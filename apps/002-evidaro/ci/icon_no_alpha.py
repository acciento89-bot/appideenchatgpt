from pathlib import Path
import binascii
import hashlib
import json
import struct
import zlib

root = Path(__file__).resolve().parents[1]
icon_set = root / "prototype/EvidaroPrototype/Assets.xcassets/AppIcon.appiconset"
icon = icon_set / "KamilunavoTrace-AppIcon-1024.png"
contents = icon_set / "Contents.json"

data = icon.read_bytes()
if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 33:
    raise SystemExit("Trace App Icon is not a readable PNG")

# Parse every PNG chunk, validate CRCs, require IEND, and strictly inflate IDAT.
# This catches truncated/corrupt artwork that still has a valid PNG header.
pos = 8
idat = bytearray()
ihdr = None
saw_iend = False
while pos + 12 <= len(data):
    length = struct.unpack(">I", data[pos : pos + 4])[0]
    chunk_type = data[pos + 4 : pos + 8]
    end = pos + 12 + length
    if end > len(data):
        raise SystemExit(f"Trace App Icon PNG is truncated inside {chunk_type.decode('ascii', 'replace')} chunk")
    payload = data[pos + 8 : pos + 8 + length]
    expected_crc = struct.unpack(">I", data[pos + 8 + length : end])[0]
    actual_crc = binascii.crc32(chunk_type + payload) & 0xFFFFFFFF
    if actual_crc != expected_crc:
        raise SystemExit(f"Trace App Icon PNG has invalid CRC in {chunk_type.decode('ascii', 'replace')} chunk")
    if chunk_type == b"IHDR":
        ihdr = payload
    elif chunk_type == b"IDAT":
        idat.extend(payload)
    elif chunk_type == b"IEND":
        saw_iend = True
        if end != len(data):
            raise SystemExit("Trace App Icon PNG contains trailing bytes after IEND")
        break
    pos = end

if ihdr is None or len(ihdr) != 13 or not saw_iend or not idat:
    raise SystemExit("Trace App Icon PNG is missing required IHDR/IDAT/IEND data")

width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(">IIBBBBB", ihdr)
digest = hashlib.sha256(data).hexdigest()
print(f"Trace App Icon: {width}x{height}, bitDepth={bit_depth}, colorType={color_type}")
print(f"Trace App Icon SHA-256: {digest}")

if (width, height) != (1024, 1024):
    raise SystemExit("Trace App Icon must be exactly 1024x1024")
if bit_depth != 8:
    raise SystemExit("Trace App Icon must be 8-bit")
if color_type != 2:
    raise SystemExit("Trace App Icon must be truecolor RGB with no alpha channel")
if (compression, filter_method, interlace) != (0, 0, 0):
    raise SystemExit("Trace App Icon must use standard non-interlaced PNG encoding")

try:
    inflated = zlib.decompress(bytes(idat))
except zlib.error as exc:
    raise SystemExit(f"Trace App Icon PNG pixel stream is corrupt: {exc}") from exc
expected_inflated = height * (1 + width * 3)
if len(inflated) != expected_inflated:
    raise SystemExit(
        f"Trace App Icon PNG pixel stream is incomplete: expected {expected_inflated} bytes, got {len(inflated)}"
    )
if any(inflated[row * (1 + width * 3)] > 4 for row in range(height)):
    raise SystemExit("Trace App Icon PNG contains an invalid row filter")

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

for required_appearance in ("default", "dark", "tinted"):
    if not any(appearance_value(entry) == required_appearance for entry in matching):
        raise SystemExit(f"Trace App Icon must explicitly wire the {required_appearance} iOS appearance")

print("Trace App Icon is strictly decodable, App Store compatible: RGB, 8-bit, no alpha")
print("Trace App Icon explicitly supplies default, dark and tinted appearances")
