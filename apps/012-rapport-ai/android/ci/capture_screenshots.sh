#!/usr/bin/env bash
set -euo pipefail

package_name='de.kamilunavo.rapportai'
apk=${1:?Usage: capture_screenshots.sh APK OUTPUT_DIR}
output_dir=${2:?Usage: capture_screenshots.sh APK OUTPUT_DIR}

mkdir -p "$output_dir"
adb install -r "$apk"
adb shell pm clear "$package_name"
adb shell settings put global hide_error_dialogs 1
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0

adb shell am start -W -n "$package_name/.MainActivity"

dump_ui() {
  adb shell uiautomator dump /sdcard/rapport-window.xml >/dev/null
  adb shell cat /sdcard/rapport-window.xml | tr -d '\r'
}

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
  printf 'Rapport AI never gained focus; last focus: %s\n' "$focus" >&2
  return 1
}

wait_for_text() {
  local wanted=$1
  for _ in $(seq 1 30); do
    if dump_ui | grep -Fq "text=\"$wanted\""; then
      return 0
    fi
    sleep 1
  done
  printf 'UI text not found: %s\n' "$wanted" >&2
  dump_ui >&2
  return 1
}

tap_text() {
  local wanted=$1
  local bounds
  bounds=$(dump_ui | python3 -c '
import re, sys, xml.etree.ElementTree as ET
wanted = sys.argv[1]
root = ET.fromstring(sys.stdin.read())
for node in root.iter("node"):
    if node.attrib.get("text") == wanted or node.attrib.get("content-desc") == wanted:
        match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.attrib["bounds"])
        if match:
            x1, y1, x2, y2 = map(int, match.groups())
            print((x1 + x2) // 2, (y1 + y2) // 2)
            raise SystemExit
raise SystemExit(1)
' "$wanted")
  read -r x y <<< "$bounds"
  adb shell input tap "$x" "$y"
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
assert len(data) > 100_000, len(data)
PY
}

wait_for_app_focus
wait_for_text "Neuer Rapport"

# A sideloaded debug APK can show the app's own transient Billing notice.
# Dismiss it; screenshots still fail if any system window owns focus.
if dump_ui | grep -Fq 'text="Hinweis"'; then
  tap_text "OK"
  wait_for_text "Neuer Rapport"
fi
capture_png rapport-ai-create.png

tap_text "Mehr"
wait_for_text "Firmenprofil für PDF"
capture_png rapport-ai-settings.png
