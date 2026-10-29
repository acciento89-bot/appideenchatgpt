#!/usr/bin/env python3
"""CPU-only Android metadata/raw-file export-filter contract. No Godot or SDK run."""
import configparser, fnmatch, hashlib, json, os, pathlib, re, subprocess, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
META = json.loads((ROOT / "docs/android-release-metadata.json").read_text())


def sections():
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.read(ROOT / "export_presets.cfg")
    return cfg


class AndroidReleaseSourceTests(unittest.TestCase):
    def test_only_expected_android_release_versions(self):
        cfg = sections()
        names = []
        for section in cfg.sections():
            if re.fullmatch(r"preset\.\d+", section) and cfg[section].get("platform") == '"Android"':
                names.append(cfg[section]["name"].strip('"'))
                options = cfg[section + ".options"]
                self.assertEqual(int(options["version/code"]), META["androidVersionCode"])
                self.assertEqual(options["version/name"].strip('"'), META["androidVersionName"])
                self.assertEqual(options["package/unique_name"].strip('"'), META["package"])
        self.assertEqual(names, META["androidPresetNames"])
        self.assertEqual(META["savedLiveMax"], 4)  # Retained actual provider proof.
        self.assertEqual(META.get("reservedUnpublishedVersionCodes"), [5])
        self.assertEqual(META["androidVersionCode"], max([META["savedLiveMax"]] + META["reservedUnpublishedVersionCodes"]) + 1)
        self.assertEqual(META["androidVersionCode"], 6)

    def test_ios_and_shared_project_bytes_preserved(self):
        ios = (ROOT / "export_presets.cfg").read_bytes().split(b"[preset.1]", 1)[0]
        self.assertEqual(hashlib.sha256(ios).hexdigest(), META["preservedIOSPresetSha256"])
        self.assertEqual(hashlib.sha256((ROOT / "project.godot").read_bytes()).hexdigest(), META["preservedProjectGodotSha256"])

    def test_original_notice_bytes_and_raw_export_filters(self):
        cfg = sections()
        for filename, expected in META['rawAttributionFiles'].items():
            self.assertEqual(hashlib.sha256((ROOT / filename).read_bytes()).hexdigest(), expected)
            for section in cfg.sections():
                if re.fullmatch(r'preset\.\d+', section) and cfg[section].get('platform') == '"Android"':
                    include = cfg[section]['include_filter'].strip('"').split(',')
                    exclude = cfg[section]['exclude_filter'].strip('"').split(',')
                    for required in [filename, *META['requiredRawCreditFiles']]:
                        self.assertTrue(any(fnmatch.fnmatchcase(required, p.strip()) for p in include), (section, required))
                        self.assertFalse(any(fnmatch.fnmatchcase(required, p.strip()) for p in exclude), (section, required))

    def test_only_unused_demo_paths_are_excluded_from_normal_android(self):
        cfg = sections()
        normal = next(cfg[s] for s in cfg.sections() if cfg[s].get('name') == '"Android Play"')
        excluded = normal['exclude_filter'].strip('"').split(',')
        for sample in META['excludeUnusedAdmobDemoPathsFromNormalAndroidOnly']:
            self.assertIn(sample, excluded)
        for active in ['assets/fonts/mitr/Mitr-Regular.ttf', 'assets/fonts/mitr/Mitr-Bold.ttf', 'assets/fonts/mitr/OFL.txt', 'assets/fonts/LICENSE.txt', 'assets/fonts/DejaVu-2.37-LICENSE.txt']:
            self.assertFalse(any(fnmatch.fnmatchcase(active, pattern.strip()) for pattern in excluded), active)

    def test_qualified_same_project_mit_notice_is_in_normal_android(self):
        filename = 'licenses/godot-iap-1.2.9/CURRENT-UPSTREAM-MIT-LICENSE.txt'
        self.assertTrue((ROOT / filename).is_file(), 'Complete unchanged maintained-project MIT notice is required')
        raw = (ROOT / filename).read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(), '243adbe048bbec60be2faf9ae1e62c5221327d20ffbc13b1c80e82fa98127af1')
        provenance = json.loads((ROOT / 'licenses/godot-iap-1.2.9/PROVENANCE.json').read_text())
        self.assertEqual(provenance['pinnedCommit'], META['iapPinnedSourceCommit'])
        self.assertEqual(provenance['upstreamDeclaration'], 'MIT License - see [LICENSE](LICENSE) file for details.')
        self.assertEqual(provenance['fullNotice']['sourceCommit'], '6a2abd7b6512e26c47a3517f6564769f03505cef')
        self.assertFalse(provenance['fullNotice']['claimedHistoricalPinnedFile'])
        self.assertEqual(provenance['fullNotice']['sha256'], hashlib.sha256(raw).hexdigest())
        self.assertEqual(META['normalAndroidRawAttributionFiles'][filename], hashlib.sha256(raw).hexdigest())
        cfg = sections()
        normal = next(cfg[s] for s in cfg.sections() if cfg[s].get('name') == '"Android Play"')
        self.assertIn(filename, normal['include_filter'].strip('"').split(','))
        self.assertFalse(any(fnmatch.fnmatchcase(filename, p.strip()) for p in normal['exclude_filter'].strip('"').split(',')))
        self.assertFalse(provenance['sdkBehaviorOrVersionChanged'])

    def test_actual_manifest_checks_require_exact_android_identity(self):
        workflow = (ROOT / META['sourceWorkflow']).read_text()
        checks = [line.strip() for line in workflow.splitlines() if line.strip().startswith(('grep -F \'package="', 'grep -F \'android:versionCode="', 'grep -F \'android:versionName="'))]
        self.assertEqual(len(checks), 3)
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            env = {**os.environ, 'RUNNER_TEMP': directory}
            def run(package, code, name):
                pathlib.Path(directory, 'manifest.xml').write_text('<manifest package="'+package+'" android:versionCode="'+code+'" android:versionName="'+name+'"/>')
                return subprocess.run(['bash'], input='set -euo pipefail\n'+'\n'.join(checks), text=True, env=env, capture_output=True).returncode
            self.assertEqual(run(META['package'], '6', '1.5.0'), 0)
            for values in [('de.example.other','6','1.5.0'),(META['package'],'4','1.5.0'),(META['package'],'5','1.5.0'),(META['package'],'60','1.5.0'),(META['package'],'6','1.4.0'),(META['package'],'6','1.5.0-beta')]:
                with self.subTest(values=values): self.assertNotEqual(run(*values), 0)

    def test_workflow_environment_and_manifest_summary_bind_successor(self):
        workflow = (ROOT / META['sourceWorkflow']).read_text()
        self.assertEqual(re.findall(r"EXPECTED_VERSION_CODE: '([0-9]+)'", workflow), ['6'])
        self.assertEqual(re.findall(r'EXPECTED_VERSION_NAME: ([0-9.]+)', workflow), ['1.5.0'])
        self.assertIn('expected_manifest=\'package=de.kamilunavo.idlehandwerker versionCode=6 versionName=1.5.0\'', workflow)

    def test_actual_pre_and_post_sign_checks_reject_unpublished_predecessor(self):
        # Execute the actual workflow predicates, replacing only the external
        # manifest reader with a local, strictly bounded fake executable.
        import tempfile
        workflow = (ROOT / META['sourceWorkflow']).read_text()
        before = workflow.index('      - name: Validate exact release identity before restoring signing material')
        restore = workflow.index('      - name: Restore central upload identity')
        stages = {'before_key_restore': workflow[before:restore], 'after_signing': workflow[restore:]}
        with tempfile.TemporaryDirectory() as directory:
            java = pathlib.Path(directory, 'java')
            java.write_text('''#!/usr/bin/env python3
import os, sys
fields = {'--xpath=/manifest/@package': 'TEST_PACKAGE', '--xpath=/manifest/@android:versionCode': 'TEST_CODE', '--xpath=/manifest/@android:versionName': 'TEST_NAME'}
if len(sys.argv) != 7 or sys.argv[1] != '-jar' or sys.argv[3:5] != ['dump', 'manifest'] or not sys.argv[5].startswith('--bundle=') or sys.argv[6] not in fields:
    raise SystemExit(97)
print(os.environ[fields[sys.argv[6]]])
''')
            java.chmod(0o700)
            env = {**os.environ, 'PATH': directory + os.pathsep + os.environ['PATH'], 'RUNNER_TEMP': directory,
                   'unsigned': directory + '/unsigned.aab', 'signed': directory + '/signed.aab'}
            for stage, block in stages.items():
                checks = [line.strip() for line in block.splitlines() if line.strip().startswith('test "$(java -jar "$RUNNER_TEMP/bundletool.jar" dump manifest --bundle=')]
                self.assertEqual(len(checks), 3, stage)
                def run(package, code, name):
                    return subprocess.run(['bash'], input='set -euo pipefail\n' + '\n'.join(checks), text=True,
                                          env={**env, 'TEST_PACKAGE': package, 'TEST_CODE': code, 'TEST_NAME': name}, capture_output=True).returncode
                with self.subTest(stage=stage, valid=True):
                    self.assertEqual(run(META['package'], '6', '1.5.0'), 0)
                for values in [('de.example.other','6','1.5.0'),(META['package'],'4','1.5.0'),(META['package'],'5','1.5.0'),(META['package'],'60','1.5.0'),(META['package'],'6','1.4.0'),(META['package'],'6','1.5.0-beta')]:
                    with self.subTest(stage=stage, values=values): self.assertNotEqual(run(*values), 0)

    def test_signer_checks_exact_identity_before_key_restore_and_after_signing(self):
        workflow = (ROOT / META['sourceWorkflow']).read_text()
        before = workflow.index('      - name: Validate exact release identity before restoring signing material')
        restore = workflow.index('      - name: Restore central upload identity')
        self.assertLess(before, restore)
        block = workflow[before:restore]
        for value in ['--xpath=/manifest/@package)" = '+META['package'], '--xpath=/manifest/@android:versionCode)" = '+str(META['androidVersionCode']), '--xpath=/manifest/@android:versionName)" = '+META['androidVersionName']]:
            self.assertIn(value, block)
            self.assertIn(value, workflow[restore:])
        self.assertIn('sha256sum --check -', block)

if __name__ == '__main__':
    unittest.main()
