"""Keep the native game alive when Android changes its system font size.

Godot's default activity destroys the engine on activity recreation. Preserve
all template configuration flags, adding only the observed font-scale case.
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ANDROID = "{http://schemas.android.com/apk/res/android}"
ET.register_namespace("android", ANDROID[1:-1])
ET.register_namespace("tools", "http://schemas.android.com/tools")

def has_font_scale(value: str) -> bool:
    # bundletool prints compiled enum flags as a numeric mask, not names.
    try:
        return bool(int(value, 0) & 0x40000000)
    except ValueError:
        return "fontScale" in value.split("|")

def patch(manifest: Path) -> None:
    tree = ET.parse(manifest)
    matches = [a for a in tree.findall("application/activity") if a.get(ANDROID + "name") == ".GodotApp"]
    if len(matches) != 1:
        raise ValueError("Expected exactly one GodotApp template activity")
    activity = matches[0]
    flags = activity.get(ANDROID + "configChanges", "").split("|")
    if not all(flags):
        raise ValueError("Existing Godot configuration flags must be preserved")
    if "fontScale" not in flags:
        flags.append("fontScale")
        activity.set(ANDROID + "configChanges", "|".join(flags))
        tree.write(manifest, encoding="utf-8", xml_declaration=True)

if __name__ == "__main__":
    patch(Path(sys.argv[1]))
