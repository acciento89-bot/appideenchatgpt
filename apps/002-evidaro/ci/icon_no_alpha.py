from pathlib import Path
import hashlib
import struct

icon = Path(__file__).resolve().parents[1] / "prototype/EvidaroPrototype/Assets.xcassets/AppIcon.appiconset/KamilunavoTrace-AppIcon-1024.png"
data = icon.read_bytes()
if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 33:
    raise SystemExit("Trace App Icon is not a readable PNG")
width, height, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])[:4]
print(f"Trace App Icon: {width}x{height}, bitDepth={bit_depth}, colorType={color_type}")
if (width, height) != (1024, 1024):
    raise SystemExit("Trace App Icon must be exactly 1024x1024")
if bit_depth != 8:
    raise SystemExit("Trace App Icon must be 8-bit")
if color_type != 2:
    raise SystemExit("Trace App Icon must be truecolor RGB with no alpha channel")

# Build 5 passed the technical PNG checks while the icon was visually too dark on-device.
# Pin the corrected high-contrast production asset so a stale/graphite icon cannot silently return.
expected_sha256 = "9f190ade364f099ac9159441d24834e9f477e99b0dee7e79adc4596598278dcb"
actual_sha256 = hashlib.sha256(data).hexdigest()
print(f"Trace App Icon SHA-256: {actual_sha256}")
if actual_sha256 != expected_sha256:
    raise SystemExit("Trace App Icon is not the approved high-contrast Build 6 asset")

print("Trace App Icon has no alpha channel and matches the approved high-contrast asset")
