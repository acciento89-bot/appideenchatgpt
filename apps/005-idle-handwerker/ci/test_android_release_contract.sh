#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
workflow="$root/.github/workflows/idle-handwerker-android.yml"
validate="$root/.github/workflows/idle-handwerker-validate.yml"
project="$root/apps/005-idle-handwerker"
preset="$project/export_presets.cfg"
monetization="$project/scripts/monetization_bridge.gd"
capture="$project/ci/capture_android_screenshots.sh"
foreground="$project/assets/branding/app_icon_adaptive_foreground.svg"
background="$project/assets/branding/app_icon_adaptive_background.svg"

if grep -Eq 'keytool[[:space:]]+-genkeypair|Temporary CI Build|temporary-build-key' "$workflow"; then
  echo "A per-run temporary release identity is forbidden." >&2
  exit 1
fi

for file in "$workflow" "$validate" "$preset" "$monetization" "$capture" "$foreground" "$background"; do
  test -s "$file"
done

grep -Fq "uses: acciento89-bot/maengelfix/.github/actions/restore-android-signing@main" "$workflow"
grep -Fq "app-id: idlehandwerker" "$workflow"
grep -Fq "github.event_name == 'workflow_dispatch'" "$workflow"
grep -Fq "id-token: write" "$workflow"
grep -Fq "BC:F2:33:7D:41:E6:17:C0:3B:CA:E6:98:C0:9D:15:23:65:4B:D7:90" "$workflow"
grep -Fq "79:85:BD:6B:33:71:1B:AC:A7:E6:BA:72:2C:2B:38:70:EB:BC:80:2F:7D:B4:A7:BC:12:06:BD:AE:51:C4:D5:D6" "$workflow"
grep -Fq "de.kamilunavo.idlehandwerker" "$workflow"
grep -Fq "versionCode=1" "$workflow"
grep -Fq "idle-handwerker-android-screenshots" "$workflow"
grep -Fq "reactivecircus/android-emulator-runner@v2" "$workflow"
grep -Fq "sudo chmod 666 /dev/kvm" "$workflow"
if ! grep -Fq 'touch "$PROJECT_DIR/android/build/.gdignore"' "$workflow"; then
  echo "Generated Android resources must be hidden from Godot's importer." >&2
  exit 1
fi
grep -Fq "test_android_release_contract.sh" "$workflow"
grep -Fq "test_android_release_contract.sh" "$validate"

grep -Fq 'name="Android Screenshots"' "$preset"
grep -Fq 'command_line/extra_args="--store-screenshots"' "$preset"
grep -Fq 'architectures/x86_64=true' "$preset"
grep -Fq 'launcher_icons/main_192x192="res://assets/branding/app_icon.svg"' "$preset"
grep -Fq 'launcher_icons/adaptive_foreground_432x432="res://assets/branding/app_icon_adaptive_foreground.svg"' "$preset"
grep -Fq 'launcher_icons/adaptive_background_432x432="res://assets/branding/app_icon_adaptive_background.svg"' "$preset"

grep -Fq 'const STORE_SCREENSHOT_ARG := "--store-screenshots"' "$monetization"
grep -Fq 'if not _store_screenshot_capture():' "$monetization"
grep -Fq 'OS.get_cmdline_args().has(STORE_SCREENSHOT_ARG)' "$monetization"

grep -Fq 'mCurrentFocus=' "$capture"
grep -Fq 'idle-handwerker-home.png' "$capture"
grep -Fq 'idle-handwerker-shop.png' "$capture"
if grep -Fq 'mFocusedApp' "$capture"; then
  echo "Foreground validation must use mCurrentFocus only." >&2
  exit 1
fi

grep -Fq 'viewBox="0 0 1024 1024"' "$foreground"
grep -Fq 'fill="none"' "$background"
if grep -Fq '<rect width="1024" height="1024"' "$foreground"; then
  echo "Adaptive foreground must remain transparent." >&2
  exit 1
fi

echo "Idle Handwerker Android release contract passed."
