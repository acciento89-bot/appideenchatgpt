from pathlib import Path
import hashlib
import struct

icon = Path(__file__).resolve().parents[1] / "prototype/EvidaroPrototype/Assets.xcassets/AppIcon.appiconset/KamilunavoTrace-AppIcon-1024.png"
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

print("Trace App Icon is App Store compatible: RGB, 8-bit, no alpha")
