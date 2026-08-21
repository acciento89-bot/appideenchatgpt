from pathlib import Path
import struct
import zlib

icon = Path(__file__).resolve().parents[1] / "prototype/EvidaroPrototype/Assets.xcassets/AppIcon.appiconset/KamilunavoTrace-AppIcon-1024.png"
data = icon.read_bytes()
if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 33:
    raise SystemExit("Trace App Icon is not a readable PNG")

width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(">IIBBBBB", data[16:29])
print(f"Trace App Icon: {width}x{height}, bitDepth={bit_depth}, colorType={color_type}")
if (width, height) != (1024, 1024):
    raise SystemExit("Trace App Icon must be exactly 1024x1024")
if bit_depth != 8:
    raise SystemExit("Trace App Icon must be 8-bit")
if color_type != 2:
    raise SystemExit("Trace App Icon must be truecolor RGB with no alpha channel")
if compression != 0 or filter_method != 0 or interlace != 0:
    raise SystemExit("Trace App Icon must use standard non-interlaced PNG encoding")

# Decode RGB pixels with stdlib only so Linux release CI catches a visually
# near-black icon, not merely dimensions/alpha. Normal PNG uses a zlib-wrapped
# stream; some encoders use raw deflate, so accept either representation.
pos = 8
idat = bytearray()
while pos + 12 <= len(data):
    length = struct.unpack(">I", data[pos:pos + 4])[0]
    kind = data[pos + 4:pos + 8]
    payload = data[pos + 8:pos + 8 + length]
    if kind == b"IDAT":
        idat.extend(payload)
    pos += 12 + length
    if kind == b"IEND":
        break

try:
    raw = zlib.decompress(bytes(idat))
except zlib.error:
    raw = zlib.decompress(bytes(idat), -15)

bpp = 3
stride = width * bpp
expected = height * (stride + 1)
if len(raw) != expected:
    raise SystemExit("Trace App Icon has an unexpected PNG scanline layout")

rows = []
prev = bytearray(stride)
offset = 0
for _ in range(height):
    filter_type = raw[offset]
    scan = bytearray(raw[offset + 1:offset + 1 + stride])
    offset += stride + 1
    recon = bytearray(stride)
    for i, value in enumerate(scan):
        a = recon[i - bpp] if i >= bpp else 0
        b = prev[i]
        c = prev[i - bpp] if i >= bpp else 0
        if filter_type == 0:
            x = value
        elif filter_type == 1:
            x = (value + a) & 0xFF
        elif filter_type == 2:
            x = (value + b) & 0xFF
        elif filter_type == 3:
            x = (value + ((a + b) // 2)) & 0xFF
        elif filter_type == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
            x = (value + pr) & 0xFF
        else:
            raise SystemExit(f"Trace App Icon uses unsupported PNG filter {filter_type}")
        recon[i] = x
    rows.append(recon)
    prev = recon

sample_count = 0
luma_total = 0.0
bright_count = 0
for y in range(0, height, 8):
    row = rows[y]
    for x in range(0, width, 8):
        i = x * 3
        r, g, b = row[i], row[i + 1], row[i + 2]
        luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
        luma_total += luma
        bright_count += luma >= 200
        sample_count += 1

average_luma = luma_total / sample_count
bright_ratio = bright_count / sample_count
corner = rows[0]
r0, g0, b0 = corner[0], corner[1], corner[2]
corner_luma = 0.2126 * r0 + 0.7152 * g0 + 0.0722 * b0
print(f"Trace App Icon visual guard: averageLuma={average_luma:.1f}, cornerLuma={corner_luma:.1f}, brightRatio={bright_ratio:.3f}")

# Build 5 passed technical PNG checks but looked effectively black on-device.
# Reject a near-black field while allowing later blue/teal refinements.
if average_luma < 70 or corner_luma < 60:
    raise SystemExit("Trace App Icon is too dark for release")
if bright_ratio < 0.015:
    raise SystemExit("Trace App Icon does not contain enough high-contrast foreground detail")

print("Trace App Icon is RGB/no-alpha and passes the on-device contrast regression guard")
