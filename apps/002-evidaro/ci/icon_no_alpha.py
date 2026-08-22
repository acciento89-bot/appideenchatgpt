from pathlib import Path
import hashlib
import json
import struct

root = Path(__file__).resolve().parents[1]
icon_set = root / "prototype/EvidaroPrototype/Assets.xcassets/AppIcon.appiconset"
icon = icon_set / "KamilunavoTrace-AppIcon-1024.png"
contents = icon_set / "Contents.json"

data = icon.read_bytes()
if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 33:
    raise SystemExit("Trace App Icon is not a readable PNG")

width, height, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])[:4]
digest = hashlib.sha256(data).hexdigest()
print(f"Trace App Icon: {width}x{height}, bitDepth={bit_depth}, colorType={color_type}")
print(f"Trace App Icon SHA-256: {digest}")

if (width, height) != (1024, 1024):
    raise SystemExit("Trace App Icon must be exactly 1024x1024")
if bit_depth != 8:
    raise SystemExit("Trace App Icon must be 8-bit")
if color_type != 2:
    raise SystemExit("Trace App Icon must be truecolor RGB with no alpha channel")

catalog = json.loads(contents.read_text(encoding="utf-8"))
images = catalog.get("images", [])
production_name = icon.name

def appearance_value(entry):
    appearances = entry.get("appearances", [])
    if not appearances:
        return "default"
    for appearance in appearances:
        if appearance.get("appearance") == "luminosity":
            return appearance.get("value")
    return None

matching = [
    entry for entry in images
    if entry.get("idiom") == "universal"
    and entry.get("platform") == "ios"
    and entry.get("size") == "1024x1024"
    and entry.get("filename") == production_name
]

if not any(appearance_value(entry) == "default" for entry in matching):
    raise SystemExit("Trace App Icon must wire the approved production PNG as the default iOS icon")
if not any(appearance_value(entry) == "dark" for entry in matching):
    raise SystemExit("Trace App Icon must explicitly wire a dark iOS appearance instead of relying on system generation")

print("Trace App Icon is App Store compatible: RGB, 8-bit, no alpha")
print("Trace App Icon explicitly supplies the approved production artwork for default and dark appearances")
