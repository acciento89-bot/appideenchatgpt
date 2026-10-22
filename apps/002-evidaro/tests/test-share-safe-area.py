from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]/'prototype/EvidaroPrototype'
case=(root/'CaseDetailView.swift').read_text()
# Native activity controller contains controls: never opt its entire sheet out of insets.
for state in ('evidencePackShareItem','verificationBundleShareItem'):
    pattern=rf'\.sheet\(item: \${state}\)\s*\{{ shareItem in\s*EvidencePackShareSheet\(url: shareItem.url\)(.*?)\n\s*\}}'
    match=re.search(pattern,case,re.S)
    assert match, f'Missing existing {state} export path'
    assert '.ignoresSafeArea' not in match.group(1), f'{state}: share controls opt out of native safe areas'
# The audited full-screen camera surface remains intentionally unchanged.
assert '.ignoresSafeArea()' in (root/'AddEvidenceView.swift').read_text()
print('PASS: both share-control sheets respect offered safe area; camera exception retained')
