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
        self.assertEqual(META["androidVersionCode"], META["savedLiveMax"] + 1)

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
            self.assertEqual(run(META['package'], str(META['androidVersionCode']), META['androidVersionName']), 0)
            for values in [('de.example.other','5','1.5.0'),(META['package'],'4','1.5.0'),(META['package'],'50','1.5.0'),(META['package'],'5','1.4.0'),(META['package'],'5','1.5.0-beta')]:
                with self.subTest(values=values): self.assertNotEqual(run(*values), 0)

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
