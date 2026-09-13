#!/usr/bin/env bash
set -euo pipefail

package_name='de.kamilunavo.idlehandwerker'
apk=${1:?Usage: capture_android_screenshots.sh APK OUTPUT_DIR}
output_dir=${2:?Usage: capture_android_screenshots.sh APK OUTPUT_DIR}

mkdir -p "$output_dir"
diagnostics_dir="$output_dir/diagnostics"

collect_android_diagnostics() {
  local exit_code=$?
  trap - ERR
  set +e
  mkdir -p "$diagnostics_dir"
  adb logcat -b all -d -v threadtime > "$diagnostics_dir/logcat.txt" 2>&1
  adb shell dumpsys activity top > "$diagnostics_dir/activity-top.txt" 2>&1
  adb shell dumpsys window > "$diagnostics_dir/window.txt" 2>&1
  adb shell pidof "$package_name" > "$diagnostics_dir/app-pid.txt" 2>&1
  adb shell dumpsys package "$package_name" > "$diagnostics_dir/package.txt" 2>&1
  printf 'Android runtime diagnostics saved under %s\n' "$diagnostics_dir" >&2
  exit "$exit_code"
}

trap collect_android_diagnostics ERR
adb logcat -c
adb install -r "$apk"
adb shell pm clear "$package_name"
adb shell settings put global hide_error_dialogs 1
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
adb shell settings put secure immersive_mode_confirmations confirmed

component=$(adb shell cmd package resolve-activity --brief "$package_name" | tr -d '\r' | tail -n 1)
test -n "$component"
adb shell am start -W -n "$component"

wait_for_app_focus() {
  local focus=''
  for _ in $(seq 1 60); do
    focus=$(adb shell dumpsys window | tr -d '\r' | sed -n '/mCurrentFocus=/p' | tail -n 1)
    if [[ "$focus" == *"$package_name"* ]]; then
      printf '%s\n' "$focus"
      return 0
    fi
    sleep 1
  done
  printf 'Idle Handwerker never gained focus; last focus: %s\n' "$focus" >&2
  return 1
}

assert_clean_app_focus() {
  local focus
  focus=$(adb shell dumpsys window | tr -d '\r' | sed -n '/mCurrentFocus=/p' | tail -n 1)
  printf '%s\n' "$focus"
  [[ "$focus" == *"$package_name"* ]]
  [[ "$focus" != *"Application Error"* ]]
  [[ "$focus" != *"Application Not Responding"* ]]
  [[ "$focus" != *"has stopped"* ]]
}

validate_png() {
  local path=$1
  local mode=${2:-app}
  python3 - "$path" "$mode" <<'PY'
import struct
import sys
import zlib
from pathlib import Path

data = Path(sys.argv[1]).read_bytes()
mode = sys.argv[2]
assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
width, height = struct.unpack(">II", data[16:24])
assert (width, height) == (1080, 2400), (width, height)

chunks = []
position = 8
bit_depth = color_type = interlace = None
while position < len(data):
    length = struct.unpack(">I", data[position:position + 4])[0]
    kind = data[position + 4:position + 8]
    payload = data[position + 8:position + 8 + length]
    position += 12 + length
    if kind == b"IHDR":
        width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
    elif kind == b"IDAT":
        chunks.append(payload)
    elif kind == b"IEND":
        break

assert bit_depth == 8, bit_depth
assert color_type in (2, 6), color_type
assert interlace == 0, interlace
bytes_per_pixel = 3 if color_type == 2 else 4
stride = width * bytes_per_pixel
packed = zlib.decompress(b"".join(chunks))
assert len(packed) == height * (stride + 1), len(packed)

def paeth(a, b, c):
    estimate = a + b - c
    da, db, dc = abs(estimate - a), abs(estimate - b), abs(estimate - c)
    return a if da <= db and da <= dc else b if db <= dc else c

previous = bytearray(stride)
colors = set()
navy_hits = 0
accent_hits = 0
count = 0
mean = 0.0
m2 = 0.0
offset = 0
for y in range(height):
    filter_type = packed[offset]
    scan = bytearray(packed[offset + 1:offset + 1 + stride])
    offset += stride + 1
    for index, value in enumerate(scan):
        left = scan[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
        up = previous[index]
        upper_left = previous[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
        if filter_type == 1:
            scan[index] = (value + left) & 255
        elif filter_type == 2:
            scan[index] = (value + up) & 255
        elif filter_type == 3:
            scan[index] = (value + ((left + up) // 2)) & 255
        elif filter_type == 4:
            scan[index] = (value + paeth(left, up, upper_left)) & 255
        else:
            assert filter_type == 0, filter_type
    if y % 8 == 0:
        for x in range(0, width, 8):
            start = x * bytes_per_pixel
            red, green, blue = scan[start:start + 3]
            colors.add((red, green, blue))
            if abs(red - 7) <= 10 and abs(green - 21) <= 10 and abs(blue - 34) <= 10:
                navy_hits += 1
            if (
                abs(red - 53) <= 16 and abs(green - 185) <= 16 and abs(blue - 230) <= 16
            ) or (
                abs(red - 242) <= 16 and abs(green - 140) <= 16 and abs(blue - 40) <= 16
            ):
                accent_hits += 1
            luminance = (red * 299 + green * 587 + blue * 114) / 1000
            count += 1
            delta = luminance - mean
            mean += delta / count
            m2 += delta * (luminance - mean)
    previous = scan

standard_deviation = ((m2 / count) ** 0.5) / 255
assert len(colors) >= 16, len(colors)
assert standard_deviation >= 0.03, standard_deviation
if mode == "app":
    assert navy_hits >= 100, navy_hits
    assert accent_hits >= 10, accent_hits
PY
}

capture_png() {
  local filename=$1
  assert_clean_app_focus
  adb exec-out screencap -p > "$output_dir/$filename"
  validate_png "$output_dir/$filename" app
}

wait_for_app_surface() {
  local ready_frame="$output_dir/idle-handwerker-not-ready.png"
  sleep 20
  for _ in $(seq 1 6); do
    assert_clean_app_focus
    adb exec-out screencap -p > "$ready_frame"
    if validate_png "$ready_frame" app >/dev/null 2>&1; then
      rm -f "$ready_frame"
      return 0
    fi
    sleep 2
  done
  printf 'Idle Handwerker never rendered its expected app palette.\n' >&2
  return 1
}

wait_for_app_focus
wait_for_app_surface

# A cleared install presents the four-page in-app tutorial. Its centered
# 430x932 panel maps the primary button to y=1650 on this 1080x2400 profile.
for _ in 1 2 3 4; do
  adb shell input tap 540 1650
  sleep 1
done
sleep 3
wait_for_app_focus
capture_png idle-handwerker-home.png

# The third of five bottom navigation actions is the Android Ausbau/
# Fortschritt counterpart. Its center is stable on the fixed Pixel 6 profile.
adb shell input tap 540 2220
sleep 2
wait_for_app_focus
capture_png idle-handwerker-progress.png

# Compact layout math: safe top ≈24 logical px + 6 px padding; the two
# 42x30 header actions therefore place SHOP at logical y=64..94, which maps
# to screen y≈165..242. Stay well inside that hitbox.
adb shell input tap 990 205
sleep 2
wait_for_app_focus
capture_png idle-handwerker-shop.png

trap - ERR
