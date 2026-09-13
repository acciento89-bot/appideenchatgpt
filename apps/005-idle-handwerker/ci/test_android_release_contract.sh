#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
workflow="$root/.github/workflows/idle-handwerker-android.yml"
validate="$root/.github/workflows/idle-handwerker-validate.yml"
project="$root/apps/005-idle-handwerker"
preset="$project/export_presets.cfg"
monetization="$project/scripts/monetization_bridge.gd"
capture="$project/ci/capture_android_screenshots.sh"
stripper="$project/ci/strip_adaptive_launcher_icons.gradle"
aar_sanitizer="$project/ci/sanitize_godot_launcher_aar.py"

if grep -Eq 'keytool[[:space:]]+-genkeypair|Temporary CI Build|temporary-build-key' "$workflow"; then
  echo "A per-run temporary release identity is forbidden." >&2
  exit 1
fi

for file in "$workflow" "$validate" "$preset" "$monetization" "$capture" "$stripper" "$aar_sanitizer"; do
  test -s "$file"
done

grep -Fq "uses: acciento89-bot/maengelfix/.github/actions/restore-central-android-signing@main" "$workflow"
if grep -Fq "restore-android-signing@main" "$workflow" || grep -Fq "app-id:" "$workflow"; then
  echo "Dispatch signing must use the single central identity without a per-app vault id." >&2
  exit 1
fi
grep -Fq "github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'" "$workflow"
grep -Fq "id-token: write" "$workflow"
grep -Fq "BC:F2:33:7D:41:E6:17:C0:3B:CA:E6:98:C0:9D:15:23:65:4B:D7:90" "$workflow"
grep -Fq "79:85:BD:6B:33:71:1B:AC:A7:E6:BA:72:2C:2B:38:70:EB:BC:80:2F:7D:B4:A7:BC:12:06:BD:AE:51:C4:D5:D6" "$workflow"
grep -Fq "de.kamilunavo.idlehandwerker" "$workflow"
grep -Fq "versionCode=2" "$workflow"
grep -Fq "idle-handwerker-android-screenshots" "$workflow"
grep -Fq "idle-handwerker-android-runtime-diagnostics" "$workflow"
grep -Fq "idle-handwerker-screenshots.apk" "$workflow"
grep -Fq "if: always()" "$workflow"
grep -Fq "if-no-files-found: warn" "$workflow"
grep -Fq "branches: [main]" "$workflow"
grep -Fq "!apps/005-idle-handwerker/play-store/android-screenshots/**" "$workflow"
grep -Fq "github.event_name == 'push' && github.ref == 'refs/heads/main'" "$workflow"
grep -Fq 'git add -- apps/005-idle-handwerker/play-store/android-screenshots' "$workflow"
grep -Fq 'git diff --cached --quiet' "$workflow"
test "$(grep -Fc 'git add -- ' "$workflow")" -eq 1
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
if grep -Fq 'launcher_icons/adaptive_' "$preset"; then
  echo "Adaptive launcher assignments must not diverge from the canonical icon." >&2
  exit 1
fi
grep -Fq 'Adaptive launcher resources are forbidden' "$workflow"
grep -Fq 'strip_adaptive_launcher_icons.gradle' "$workflow"
grep -Fq 'stripAdaptiveLauncherIcons' "$stripper"
grep -Fq 'mipmap-anydpi-v26/icon.xml' "$stripper"
grep -Fq 'mipmap*/icon_foreground.*' "$stripper"
grep -Fq 'mipmap*/icon_background.*' "$stripper"
grep -Fq 'mipmap*/icon_monochrome.*' "$stripper"
grep -Fq 'mipmap-*/icon.webp' "$stripper"
grep -Fq 'dependsOn(stripAdaptiveLauncherIcons)' "$stripper"
grep -Fq "base/res/mipmap/icon.webp" "$workflow"
grep -Fq "mipmap-anydpi-v26/(icon|themed_icon)" "$workflow"
grep -Fq 'Launcher icon resource inventory:' "$workflow"
if grep -Fq 'drawable/icon_background\.xml' "$workflow"; then
  echo "AndroidX core-splashscreen's compatibility drawable is not a launcher icon." >&2
  exit 1
fi
test "$(grep -Fc 'version/code=2' "$preset")" -eq 2
test "$(grep -Fc 'splash_screen/background_color=Color(0.027, 0.063, 0.055, 1)' "$preset")" -eq 2
grep -Fq 'sanitize_godot_launcher_aar.py' "$workflow"
grep -Fq 'Godot splash theme still references removed icon_background' "$stripper"

python3 - "$aar_sanitizer" <<'PY'
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

sanitizer = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as directory:
    libs = Path(directory) / "libs"
    debug = libs / "debug"
    release = libs / "release"
    third_party = libs / "third-party"
    debug.mkdir(parents=True)
    release.mkdir()
    third_party.mkdir()
    entries = {
        "classes.jar": b"bytecode",
        "res/drawable/keep.xml": b"<resource />",
        "res/drawable/icon_background.xml": b"adaptive",
        "res/mipmap/icon.webp": b"fallback",
        "res/mipmap-anydpi-v26/icon.xml": b"adaptive",
        "res/mipmap-anydpi-v26/themed_icon.xml": b"adaptive",
        "res/mipmap-hdpi/icon.webp": b"fallback-density",
        "res/mipmap-hdpi/icon_foreground.webp": b"adaptive",
    }
    targets = [debug / "godot-lib.template_debug.aar", release / "godot-lib.template_release.aar"]
    unrelated = third_party / "unrelated.aar"
    for aar in [*targets, unrelated]:
        with zipfile.ZipFile(aar, "w") as archive:
            for name, data in entries.items():
                archive.writestr(name, data)
    subprocess.run([sys.executable, str(sanitizer), str(debug), str(release)], check=True)
    for aar in targets:
        with zipfile.ZipFile(aar) as archive:
            remaining = set(archive.namelist())
            assert remaining == {"classes.jar", "res/drawable/keep.xml"}, remaining
            assert archive.read("classes.jar") == b"bytecode"
    with zipfile.ZipFile(unrelated) as archive:
        assert "res/mipmap/icon.webp" in archive.namelist()
PY

grep -Fq 'const STORE_SCREENSHOT_ARG := "--store-screenshots"' "$monetization"
grep -Fq 'if not _store_screenshot_capture():' "$monetization"
grep -Fq 'OS.get_cmdline_args().has(STORE_SCREENSHOT_ARG)' "$monetization"

grep -Fq 'mCurrentFocus=' "$capture"
grep -Fq 'adb logcat -c' "$capture"
grep -Fq 'adb logcat -b all -d -v threadtime' "$capture"
grep -Fq 'dumpsys activity top' "$capture"
grep -Fq 'dumpsys window' "$capture"
grep -Fq 'pidof "$package_name"' "$capture"
grep -Fq 'trap collect_android_diagnostics ERR' "$capture"
grep -Fq 'Application Not Responding: com.google.android.apps.nexuslauncher' "$capture"
grep -Fq 'Application Not Responding: com.android.launcher3' "$capture"
grep -Fq 'am force-stop com.google.android.apps.nexuslauncher' "$capture"
grep -Fq 'am force-stop com.android.launcher3' "$capture"

diagnostics_fixture=$(mktemp -d)
mkdir -p "$diagnostics_fixture/bin" "$diagnostics_fixture/output"
cat > "$diagnostics_fixture/bin/adb" <<'SH'
#!/usr/bin/env bash
if [[ "$*" == "logcat -c" ]]; then
  exit 0
fi
if [[ "$*" == "shell dumpsys window" ]]; then
  if [[ -f "$ADB_FIXTURE_DIR/launcher-recovered" ]]; then
    echo 'mCurrentFocus=Window{fixture u0 com.google.android.apps.nexuslauncher/.NexusLauncherActivity}'
  else
    echo 'mCurrentFocus=Window{fixture u0 Application Not Responding: com.google.android.apps.nexuslauncher}'
  fi
  exit 0
fi
if [[ "$*" == "shell am force-stop com.google.android.apps.nexuslauncher" ]]; then
  touch "$ADB_FIXTURE_DIR/launcher-recovered"
  echo "$*" >> "$ADB_FIXTURE_DIR/commands"
  exit 0
fi
if [[ "$1" == "install" ]]; then
  exit 23
fi
printf 'fixture diagnostics: %s\n' "$*"
SH
chmod +x "$diagnostics_fixture/bin/adb"
printf fixture > "$diagnostics_fixture/app.apk"
set +e
ADB_FIXTURE_DIR="$diagnostics_fixture" PATH="$diagnostics_fixture/bin:$PATH" bash "$capture" \
  "$diagnostics_fixture/app.apk" "$diagnostics_fixture/output"
diagnostics_status=$?
set -e
test "$diagnostics_status" -eq 23
grep -Fq 'am force-stop com.google.android.apps.nexuslauncher' "$diagnostics_fixture/commands"
for diagnostic in logcat.txt activity-top.txt window.txt app-pid.txt package.txt; do
  test -s "$diagnostics_fixture/output/diagnostics/$diagnostic"
done
if ! grep -Fq 'settings put secure immersive_mode_confirmations confirmed' "$capture"; then
  echo "The known first-launch immersive confirmation must be suppressed before launch." >&2
  exit 1
fi
grep -Fq 'idle-handwerker-home.png' "$capture"
grep -Fq 'idle-handwerker-progress.png' "$capture"
grep -Fq 'idle-handwerker-shop.png' "$capture"
if grep -Fq 'input tap 540 1980' "$capture"; then
  echo "Tutorial taps must target the centered tutorial panel button." >&2
  exit 1
fi
grep -Fq 'input tap 540 1650' "$capture"
if grep -Fq 'input tap 1010 245' "$capture"; then
  echo "Shop taps must stay inside the computed compact header button bounds." >&2
  exit 1
fi
grep -Fq 'input tap 990 205' "$capture"
grep -Fq 'input tap 540 2220' "$capture"
if grep -Fq 'len(data) > 100_000' "$capture"; then
  echo "Compressed PNG byte size is not a valid visual-content gate." >&2
  exit 1
fi
if grep -Fq 'identify -format' "$capture"; then
  echo "Pixel validation must not depend on an undeclared runner binary." >&2
  exit 1
fi
grep -Fq 'standard_deviation' "$capture"
grep -Fq 'zlib.decompress' "$capture"
grep -Fq 'wait_for_app_surface' "$capture"
grep -Fq 'navy_hits' "$capture"
grep -Fq 'accent_hits' "$capture"
if grep -Fq 'mFocusedApp' "$capture"; then
  echo "Foreground validation must use mCurrentFocus only." >&2
  exit 1
fi

echo "Idle Handwerker Android release contract passed."
