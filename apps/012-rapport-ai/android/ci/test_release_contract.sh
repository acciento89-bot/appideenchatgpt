#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
android="$root/apps/012-rapport-ai/android"
workflow="$root/.github/workflows/rapport-android.yml"
gradle_file="$android/app/build.gradle.kts"
ios_icon="$root/apps/012-rapport-ai/prototype/RapportAI/Assets.xcassets/AppIcon.appiconset/RapportAI-AppIcon-1024.png"
android_icon="$android/app/src/main/res/drawable-nodpi/rapport_icon.png"
legacy="$android/app/src/main/res/mipmap-anydpi/ic_launcher.xml"
adaptive="$android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"
adaptive_round="$android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml"
foreground="$android/app/src/main/res/drawable/ic_launcher_foreground.xml"
capture="$android/ci/capture_screenshots.sh"

if grep -Eq 'RAPPORT_ANDROID_KEYSTORE|KEYSTORE_BASE64|secrets\.' "$workflow"; then
  echo "Branch CI must not restore app signing secrets." >&2
  exit 1
fi
if grep -Eq 'RAPPORT_ANDROID|signingConfigs' "$gradle_file"; then
  echo "Branch builds must not contain an optional signing path." >&2
  exit 1
fi
if grep -Eiq 'play.*upload|upload.*play|gradle-play-publisher|r0adkll/upload-google-play' "$workflow"; then
  echo "Play upload is forbidden in this workflow." >&2
  exit 1
fi

for file in "$workflow" "$gradle_file" "$ios_icon" "$android_icon" "$legacy" "$capture"; do
  test -s "$file"
done

cmp "$ios_icon" "$android_icon"
grep -Fq '@drawable/rapport_icon' "$legacy"
test ! -e "$adaptive"
test ! -e "$adaptive_round"
test ! -e "$foreground"
grep -Fq 'Adaptive launcher resources are forbidden' "$workflow"

grep -Fq 'versionCode = 2' "$gradle_file"
grep -Fq 'versionName = "1.0.1"' "$gradle_file"
grep -Fq 'applicationId = "de.kamilunavo.rapportai"' "$gradle_file"
grep -Fq 'test_release_contract.sh' "$workflow"
grep -Fq 'reactivecircus/android-emulator-runner@v2' "$workflow"
grep -Fq 'target: default' "$workflow"
if grep -Fq 'target: google_apis' "$workflow"; then
  echo "Screenshot CI must use the AOSP image without Google setup services." >&2
  exit 1
fi
grep -Fq 'sudo chmod 666 /dev/kvm' "$workflow"
grep -Fq 'rapport-ai-android-screenshots' "$workflow"
grep -Fq '!apps/012-rapport-ai/play-store/android-screenshots/**' "$workflow"
grep -Fq "github.event_name == 'push' && github.ref == 'refs/heads/main'" "$workflow"
grep -Fq 'git add -- apps/012-rapport-ai/play-store/android-screenshots' "$workflow"
grep -Fq 'git diff --cached --quiet' "$workflow"
test "$(grep -Fc 'git add -- ' "$workflow")" -eq 1
grep -Fq 'rapport-ai-unsigned-v2' "$workflow"
grep -Fq 'acciento89-bot/maengelfix/.github/actions/restore-central-android-signing@main' "$workflow"
if grep -Fq 'restore-android-signing@main' "$workflow" || grep -Fq 'app-id:' "$workflow"; then
  echo "Dispatch signing must use the single central identity without a per-app vault id." >&2
  exit 1
fi
grep -Fq "github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'" "$workflow"
grep -Fq 'id-token: write' "$workflow"
grep -Fq 'BC:F2:33:7D:41:E6:17:C0:3B:CA:E6:98:C0:9D:15:23:65:4B:D7:90' "$workflow"
grep -Fq '79:85:BD:6B:33:71:1B:AC:A7:E6:BA:72:2C:2B:38:70:EB:BC:80:2F:7D:B4:A7:BC:12:06:BD:AE:51:C4:D5:D6' "$workflow"
grep -Fq 'rapport-ai-central-signed-v2' "$workflow"
grep -Fq "grep -Eq '^META-INF/[^/]+\.(RSA|DSA|EC)$'" "$workflow"
if grep -Fq 'if keytool -printcert -jarfile' "$workflow"; then
  echo "keytool exit status cannot prove that an AAB is unsigned." >&2
  exit 1
fi
grep -Fq 'mCurrentFocus=' "$capture"
if grep -Fq 'com.google.android.googlesdksetup' "$capture"; then
  echo "Do not chase Google package failures in an AOSP screenshot image." >&2
  exit 1
fi
if grep -Fq 'mFocusedApp' "$capture"; then
  echo "Foreground validation must use mCurrentFocus only." >&2
  exit 1
fi
grep -Fq 'rapport-ai-create.png' "$capture"
grep -Fq 'rapport-ai-settings.png' "$capture"
python3 - "$capture" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
assert text.index("wait_for_initial_state") < text.rindex('wait_for_text "Neuer Rapport"')
assert text.index("if grep -Fq 'text=\"Hinweis\"'") < text.rindex('wait_for_text "Neuer Rapport"')
PY

echo "Rapport AI Android branch contract passed."
