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
manifest="$android/app/src/main/AndroidManifest.xml"

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

for file in "$workflow" "$gradle_file" "$ios_icon" "$android_icon" "$legacy" "$capture" "$manifest"; do
  test -s "$file"
done

python3 - "$manifest" <<'PY'
import sys
import xml.etree.ElementTree as ET

android = "{http://schemas.android.com/apk/res/android}"
root = ET.parse(sys.argv[1]).getroot()
queries = root.findall("queries")
services = [
    intent.find("action").get(android + "name")
    for query in queries
    for intent in query.findall("intent")
    if intent.find("action") is not None
]
assert services.count("android.speech.RecognitionService") == 1
PY

cmp "$ios_icon" "$android_icon"
grep -Fq '@drawable/rapport_icon' "$legacy"
test ! -e "$adaptive"
test ! -e "$adaptive_round"
test ! -e "$foreground"
test ! -e "$adaptive"
test ! -e "$adaptive_round"
grep -Fq 'versionCode = 5' "$gradle_file"
grep -Fq 'versionName = "1.3.0"' "$gradle_file"
grep -Fq 'applicationId = "de.kamilunavo.rapportai"' "$gradle_file"
grep -Fq 'verifyFragmentRuntime' "$workflow"
! grep -Fq 'hide_error_dialogs' "$workflow"
echo "Rapport Android5 package/icon/unsigned CI contract passed."
