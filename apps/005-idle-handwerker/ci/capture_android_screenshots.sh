#!/usr/bin/env bash
set -euo pipefail

package_name='de.kamilunavo.idlehandwerker'
apk=${1:?Usage: capture_android_screenshots.sh APK OUTPUT_DIR}
output_dir=${2:?Usage: capture_android_screenshots.sh APK OUTPUT_DIR}

mkdir -p "$output_dir"
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

capture_png() {
  local filename=$1
  assert_clean_app_focus
  adb exec-out screencap -p > "$output_dir/$filename"
  python3 - "$output_dir/$filename" <<'PY'
import struct
import sys
from pathlib import Path

data = Path(sys.argv[1]).read_bytes()
assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
width, height = struct.unpack(">II", data[16:24])
assert (width, height) == (1080, 2400), (width, height)
PY
  read -r colors standard_deviation < <(
    identify -format '%k %[fx:standard_deviation]\n' "$output_dir/$filename"
  )
  python3 - "$colors" "$standard_deviation" <<'PY'
import sys

colors = int(sys.argv[1])
standard_deviation = float(sys.argv[2])
assert colors >= 16, colors
assert standard_deviation >= 0.03, standard_deviation
PY
}

wait_for_app_focus
sleep 3

# A cleared install presents the four-page in-app tutorial. Advance it with
# deterministic taps inside its primary button, without changing app state/code.
for _ in 1 2 3 4; do
  adb shell input tap 540 1980
  sleep 1
done
wait_for_app_focus
capture_png idle-handwerker-home.png

# SHOP is the lower of the two compact header actions on a 1080x2400 Pixel 6.
adb shell input tap 1010 245
sleep 2
wait_for_app_focus
capture_png idle-handwerker-shop.png
