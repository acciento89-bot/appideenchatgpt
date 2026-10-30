#!/bin/sh
# Pure script/mixer test: no Editor/import/export, addons, devices or providers.
set -eu
loop_app=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
loop_godot=${1:-/Volumes/SSK SSD/Kamilunavo/Cache/Godot/4.7.1/Godot.app/Contents/MacOS/Godot}
loop_temp=$(mktemp -d "${TMPDIR:-/tmp}/idle-loop-mixer.XXXXXX")
trap 'rm -rf -- "$loop_temp"' EXIT HUP INT TERM
mkdir -p "$loop_temp/scripts"
printf '%s\n' 'config_version=5' '[application]' 'config/name="CodexIdleWorkshopLoopMixerTests"' '[audio]' 'driver/mix_rate=22050' '[rendering]' 'renderer/rendering_method="gl_compatibility"' > "$loop_temp/project.godot"
cp "$loop_app/scripts/workshop_music.gd" "$loop_temp/scripts/"
cp "$loop_app/tests/test_workshop_loop_mixer.gd" "$loop_temp/test.gd"
loop_status=0
"$loop_godot" --headless --audio-driver Dummy --path "$loop_temp" --script res://test.gd > "$loop_temp/result.log" 2>&1 || loop_status=$?
cat "$loop_temp/result.log"
[ "$loop_status" -eq 0 ] || exit "$loop_status"
if grep -E 'SCRIPT ERROR|Parse Error|Compile Error|Failed to load script' "$loop_temp/result.log" >/dev/null; then exit 1; fi
grep -F 'WORKSHOP LOOP MIXER PASS' "$loop_temp/result.log" >/dev/null
