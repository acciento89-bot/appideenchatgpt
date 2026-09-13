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
foreground="$android/app/src/main/res/drawable/ic_launcher_foreground.xml"
capture="$android/ci/capture_screenshots.sh"

if grep -Eq 'RAPPORT_ANDROID_KEYSTORE|KEYSTORE_BASE64|secrets\.' "$workflow"; then
  echo "Branch CI must not restore app signing secrets." >&2
  exit 1
fi
if grep -Eiq 'play.*upload|upload.*play|gradle-play-publisher|r0adkll/upload-google-play' "$workflow"; then
  echo "Play upload is forbidden in this workflow." >&2
  exit 1
fi

for file in "$workflow" "$gradle_file" "$ios_icon" "$android_icon" "$legacy" "$adaptive" "$foreground" "$capture"; do
  test -s "$file"
done

cmp "$ios_icon" "$android_icon"
grep -Fq '@drawable/rapport_icon' "$legacy"
grep -Fq '@drawable/rapport_icon' "$foreground"
grep -Fq '@color/navy' "$adaptive"

grep -Fq 'versionCode = 2' "$gradle_file"
grep -Fq 'versionName = "1.0.1"' "$gradle_file"
grep -Fq 'applicationId = "de.kamilunavo.rapportai"' "$gradle_file"
grep -Fq 'test_release_contract.sh' "$workflow"
grep -Fq 'reactivecircus/android-emulator-runner@v2' "$workflow"
grep -Fq 'sudo chmod 666 /dev/kvm' "$workflow"
grep -Fq 'rapport-ai-android-screenshots' "$workflow"
grep -Fq 'rapport-ai-unsigned-v2' "$workflow"
grep -Fq 'mCurrentFocus=' "$capture"
if grep -Fq 'mFocusedApp' "$capture"; then
  echo "Foreground validation must use mCurrentFocus only." >&2
  exit 1
fi
grep -Fq 'rapport-ai-create.png' "$capture"
grep -Fq 'rapport-ai-settings.png' "$capture"

echo "Rapport AI Android branch contract passed."
