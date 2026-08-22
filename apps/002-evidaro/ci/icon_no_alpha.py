from pathlib import Path
import hashlib
import json
import struct
import zlib

root = Path(__file__).resolve().parents[1]
icon_set = root / "prototype/EvidaroPrototype/Assets.xcassets/AppIcon.appiconset"
contents = icon_set / "Contents.json"

EXPECTED = {
    "default": "KamilunavoTrace-AppIcon-1024.png",
    "dark": "KamilunavoTrace-AppIcon-Dark-1024.png",
    "tinted": "KamilunavoTrace-AppIcon-Tinted-1024.png",
}

def paeth(a, b, c):
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c

def decode_rgb_png(path):
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 33:
        raise SystemExit(f"{path.name} is not a readable PNG")

    width, height, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])[:4]
    if (width, height) != (1024, 1024):
        raise SystemExit(f"{path.name} must be exactly 1024x1024")
    if bit_depth != 8 or color_type != 2:
        raise SystemExit(f"{path.name} must be 8-bit truecolor RGB with no alpha channel")

    pos = 8
    idat = bytearray()
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        if kind == b"IDAT":
            idat.extend(chunk)
        pos += 12 + length
        if kind == b"IEND":
            break

    raw = zlib.decompress(bytes(idat))
    stride = width * 3
    rows = []
    offset = 0
    prev = bytearray(stride)

    for _ in range(height):
        filter_type = raw[offset]
        offset += 1
        src = raw[offset:offset + stride]
        offset += stride
        row = bytearray(stride)

        for x, value in enumerate(src):
            left = row[x - 3] if x >= 3 else 0
            up = prev[x]
            up_left = prev[x - 3] if x >= 3 else 0
            if filter_type == 0:
                recon = value
            elif filter_type == 1:
                recon = (value + left) & 0xFF
            elif filter_type == 2:
                recon = (value + up) & 0xFF
            elif filter_type == 3:
                recon = (value + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                recon = (value + paeth(left, up, up_left)) & 0xFF
            else:
                raise SystemExit(f"{path.name} uses unsupported PNG filter {filter_type}")
            row[x] = recon

        rows.append(row)
        prev = row

    pixels = b"".join(rows)
    digest = hashlib.sha256(data).hexdigest()
    luminance_total = 0.0
    bright_pixels = 0
    grayscale = True
    count = width * height

    for i in range(0, len(pixels), 3):
        r, g, b = pixels[i], pixels[i + 1], pixels[i + 2]
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        luminance_total += lum
        if lum >= 200:
            bright_pixels += 1
        if not (r == g == b):
            grayscale = False

    return {
        "digest": digest,
        "mean_luminance": luminance_total / count,
        "bright_fraction": bright_pixels / count,
        "grayscale": grayscale,
    }

catalog = json.loads(contents.read_text(encoding="utf-8"))
images = catalog.get("images", [])

def appearance_value(entry):
    appearances = entry.get("appearances", [])
    if not appearances:
        return "default"
    for appearance in appearances:
        if appearance.get("appearance") == "luminosity":
            return appearance.get("value")
    return None

resolved = {}
for entry in images:
    if (
        entry.get("idiom") == "universal"
        and entry.get("platform") == "ios"
        and entry.get("size") == "1024x1024"
    ):
        value = appearance_value(entry)
        if value in EXPECTED:
            resolved[value] = entry.get("filename")

for appearance, expected_name in EXPECTED.items():
    actual = resolved.get(appearance)
    if actual != expected_name:
        raise SystemExit(
            f"Trace AppIcon {appearance} appearance must use {expected_name}, got {actual!r}"
        )

for appearance, filename in EXPECTED.items():
    stats = decode_rgb_png(icon_set / filename)
    print(
        f"Trace AppIcon {appearance}: {filename}, "
        f"meanLuma={stats['mean_luminance']:.1f}, "
        f"bright={stats['bright_fraction']:.3f}, "
        f"sha256={stats['digest']}"
    )

    if appearance in {"default", "dark"}:
        if stats["mean_luminance"] < 95:
            raise SystemExit(f"{filename} is too dark for release")
        if stats["bright_fraction"] < 0.12:
            raise SystemExit(f"{filename} lacks enough bright foreground detail")
    else:
        if not stats["grayscale"]:
            raise SystemExit("Tinted Trace AppIcon must be explicit grayscale artwork")
        if stats["mean_luminance"] < 80 or stats["mean_luminance"] > 235:
            raise SystemExit("Tinted Trace AppIcon luminance is outside the safe range")

print("Trace AppIcon supplies validated default, dark and tinted 1024x1024 variants")
