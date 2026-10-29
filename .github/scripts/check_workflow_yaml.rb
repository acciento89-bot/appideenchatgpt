#!/usr/bin/env ruby
# Strict syntax/duplicate-key checks using Ruby's existing standard YAML parser.
# Walk the AST before loading: permissive loaders otherwise discard duplicate keys.
require 'yaml'

class DuplicateWorkflowKey < StandardError; end

def strict_workflow_yaml(source, filename)
  tree = Psych.parse_stream(source, filename: filename)
  visit = lambda do |node|
    if node.is_a?(Psych::Nodes::Mapping)
      seen = {}
      node.children.each_slice(2) do |key, _value|
        raise "#{filename}:#{key.start_line + 1}: non-scalar workflow mapping key" unless key.is_a?(Psych::Nodes::Scalar)
        name = key.value
        if seen.key?(name)
          raise DuplicateWorkflowKey, "#{filename}:#{key.start_line + 1}: duplicate key #{name.inspect} (first at #{seen[name]})"
        end
        seen[name] = key.start_line + 1
      end
    end
    (node.respond_to?(:children) ? node.children : nil)&.each { |child| visit.call(child) }
  end
  visit.call(tree)
  YAML.safe_load(source, aliases: true)
end

def self_test
  valid = "jobs:\n  first:\n    with: {ref: main}\n  second:\n    with: {ref: main}\n"
  strict_workflow_yaml(valid, 'synthetic-valid-sibling-maps')
  controls = {
    'top-level' => "name: one\nname: two\n",
    'nested-job' => "jobs:\n  build:\n    env: {SHA: one, SHA: two}\n",
    'sequence-step' => "jobs:\n  build:\n    steps:\n      - uses: checkout\n        with: {ref: main}\n        with: {ref: other}\n",
    'quoted-key' => "env:\n  'SHA': one\n  SHA: two\n",
    'deep-sequence' => "a:\n - b:\n    c:\n      - d: one\n        d: two\n"
  }
  controls.each do |name, source|
    begin
      strict_workflow_yaml(source, "synthetic-#{name}")
    rescue DuplicateWorkflowKey
      next
    end
    raise "Duplicate-key negative control accepted: #{name}"
  end
  puts "Strict YAML controls PASS: valid sibling mappings and #{controls.length} duplicate-key rejections"
end

self_test
paths = ARGV.empty? ? Dir.glob(File.expand_path('../workflows/*.{yml,yaml}', __dir__)).sort : ARGV
raise 'No actual workflows selected' if paths.empty?
paths.each do |path|
  workflow = strict_workflow_yaml(File.read(path), path)
  if File.basename(path) == 'idle-handwerker-android.yml'
    jobs = workflow.fetch('jobs')
    %w[contract build-and-screenshot sign-central-release].each do |name|
      checkout = jobs.fetch(name).fetch('steps').find { |step| step['uses'] == 'actions/checkout@v5' }
      raise "#{path}: #{name} must checkout exact github.sha without persisted credentials" unless checkout.fetch('with') == {'ref' => '${{ github.sha }}', 'persist-credentials' => false}
    end
    persist = jobs.fetch('persist-main-screenshots')
    checkout = persist.fetch('steps').find { |step| step['uses'] == 'actions/checkout@v5' }
    raise "#{path}: push-only screenshot persistence must retain original main/auth checkout" unless checkout.fetch('with') == {'ref' => 'main'}
    raise "#{path}: screenshot persistence must remain push-only" unless persist.fetch('if').start_with?("github.event_name == 'push' && github.ref == 'refs/heads/main'")
  end
end
puts "Strict YAML PASS: #{paths.length} actual workflow files, every nested mapping checked"
