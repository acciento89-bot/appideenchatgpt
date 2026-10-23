"""Protect the Godot activity from being destroyed on a system font change."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

MODULE = Path(__file__).with_name("patch_android_font_scale.py")
ANDROID = "{http://schemas.android.com/apk/res/android}"

class FontConfigurationTest(unittest.TestCase):
    def test_preserves_activity_flags_and_unrelated_components(self):
        self.assertTrue(MODULE.is_file(), "font-scale activity configuration is not patched")
        spec = importlib.util.spec_from_file_location("font_patch", MODULE)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "AndroidManifest.xml"
            manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application><activity android:name=".GodotApp" android:configChanges="orientation|screenSize|density"/><activity android:name="AdActivity" android:configChanges="orientation"/></application></manifest>')
            module.patch(manifest)
            first = manifest.read_bytes()
            module.patch(manifest)
            self.assertEqual(first, manifest.read_bytes())
            activities = ET.parse(manifest).findall("application/activity")
            self.assertEqual(set(activities[0].get(ANDROID+"configChanges").split("|")), {"orientation", "screenSize", "density", "fontScale"})
            self.assertEqual(activities[1].get(ANDROID+"configChanges"), "orientation")

if __name__ == "__main__":
    unittest.main()
