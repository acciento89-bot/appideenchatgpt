from __future__ import annotations

import json
import plistlib
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = ROOT / "apps/002-evidaro"
APP = APP_ROOT / "prototype/EvidaroPrototype"
PROJECT = APP_ROOT / "prototype/EvidaroPrototype.xcodeproj/project.pbxproj"
SCHEME = APP_ROOT / "prototype/EvidaroPrototype.xcodeproj/xcshareddata/xcschemes/EvidaroPrototype.xcscheme"
STOREKIT = APP / "StoreKit/KamilunavoTrace.storekit"
ICON = APP / "Assets.xcassets/AppIcon.appiconset/KamilunavoTrace-AppIcon-1024.png"
ICON_CONTENTS = APP / "Assets.xcassets/AppIcon.appiconset/Contents.json"
PRIVACY_MANIFEST = APP / "PrivacyInfo.xcprivacy"
EN = APP / "en.lproj/Localizable.strings"
DE = APP / "de.lproj/Localizable.strings"
ASC_DOC = APP_ROOT / "APP_STORE_CONNECT_RELEASE.md"
APP_STORE_METADATA = APP_ROOT / "APP_STORE_METADATA.md"
ASC_JSON = APP_ROOT / "metadata/AppStoreConnectSetup.json"
QA_DOC = APP_ROOT / "PHYSICAL_QA.md"
TESTFLIGHT = ROOT / ".github/workflows/kamilunavo-trace-testflight.yml"
STATIC_WORKFLOW = ROOT / ".github/workflows/kamilunavo-trace-static-release.yml"

PRODUCT_ID = "de.kamilunavo.trace.pro.lifetime"
BUNDLE_ID = "de.kamilunavo.trace"
DISPLAY_NAME = "Kamilunavo Trace"
MARKETING_URL = "https://kamilunavo.com/trace"
SUPPORT_URL = "https://kamilunavo.com/support"
PRIVACY_URL = "https://kamilunavo.com/trace/privacy"

required = [
    PROJECT,
    SCHEME,
    STOREKIT,
    ICON,
    ICON_CONTENTS,
    PRIVACY_MANIFEST,
    EN,
    DE,
    ASC_DOC,
    APP_STORE_METADATA,
    ASC_JSON,
    QA_DOC,
    TESTFLIGHT,
    STATIC_WORKFLOW,
]
for path in required:
    if not path.exists():
        raise SystemExit(f"Missing release file: {path.relative_to(ROOT)}")

project = PROJECT.read_text()
scheme = SCHEME.read_text()
en = EN.read_text()
de = DE.read_text()
asc_doc = ASC_DOC.read_text()
metadata_doc = APP_STORE_METADATA.read_text()
qa_doc = QA_DOC.read_text()
testflight = TESTFLIGHT.read_text()
static_workflow = STATIC_WORKFLOW.read_text()

checks: dict[str, bool] = {
    "release bundle id": BUNDLE_ID in project,
    "release display name": (
        f'INFOPLIST_KEY_CFBundleDisplayName = "{DISPLAY_NAME}";' in project
        or f"INFOPLIST_KEY_CFBundleDisplayName = {DISPLAY_NAME};" in project
    ),
    "export compliance Info.plist key": project.count("INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;") == 2,
    "app icon build setting": "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;" in project,
    "privacy manifest target resource": "PrivacyInfo.xcprivacy in Resources" in project,
    "entitlement store compiled": "EntitlementStore.swift in Sources" in project,
    "paywall compiled": "ProUpgradeView.swift in Sources" in project,
    "asset catalog compiled": "Assets.xcassets in Resources" in project,
    "storekit scheme wiring": "KamilunavoTrace.storekit" in scheme,
    "testflight bundle id": f"BUNDLE_ID: '{BUNDLE_ID}'" in testflight,
    "testflight cloud signing": "app-store-connect" in testflight and "-allowProvisioningUpdates" in testflight,
    "testflight ASC credentials": all(key in testflight for key in ["ASC_ISSUER_ID", "ASC_KEY_ID", "ASC_PRIVATE_KEY_B64"]),
    "testflight PR upload disabled": "github.event_name == 'pull_request'" in testflight,
    "testflight hard failure": "Fail if TestFlight upload failed" in testflight,
    "static workflow Ubuntu": "runs-on: ubuntu-latest" in static_workflow,
    "static workflow foundation preflight": "apps/002-evidaro/ci/preflight.py" in static_workflow,
    "static workflow release preflight": "apps/002-evidaro/ci/release_preflight.py" in static_workflow,
    "ASC runbook product id": PRODUCT_ID in asc_doc,
    "ASC runbook export compliance": "ITSAppUsesNonExemptEncryption = NO" in asc_doc,
    "physical QA purchase": PRODUCT_ID in qa_doc and "Restore" in qa_doc,
    "metadata marketing URL": MARKETING_URL in metadata_doc,
    "metadata support URL": SUPPORT_URL in metadata_doc,
    "metadata privacy URL": PRIVACY_URL in metadata_doc,
}

privacy = plistlib.loads(PRIVACY_MANIFEST.read_bytes())
checks["privacy manifest tracking disabled"] = privacy.get("NSPrivacyTracking") is False
checks["privacy manifest no tracking domains"] = privacy.get("NSPrivacyTrackingDomains") == []
checks["privacy manifest no developer-collected app data"] = privacy.get("NSPrivacyCollectedDataTypes") == []
accessed_types = privacy.get("NSPrivacyAccessedAPITypes", [])
user_defaults_entries = [
    entry
    for entry in accessed_types
    if entry.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults"
]
checks["privacy manifest UserDefaults category"] = len(user_defaults_entries) == 1
checks["privacy manifest UserDefaults CA92.1"] = (
    len(user_defaults_entries) == 1
    and "CA92.1" in user_defaults_entries[0].get("NSPrivacyAccessedAPITypeReasons", [])
)

for key in [
    "pro.title",
    "pro.subtitle",
    "pro.buy_lifetime",
    "pro.restore",
    "pro.feature_cases",
    "pro.feature_pdf",
    "pro.feature_bundle",
    "pro.trust_boundary",
]:
    checks[f"EN localization {key}"] = f'"{key}"' in en
    checks[f"DE localization {key}"] = f'"{key}"' in de

store = json.loads(STOREKIT.read_text())
products = store.get("products", [])
checks["exactly one StoreKit product"] = len(products) == 1
if len(products) == 1:
    product = products[0]
    checks["StoreKit product id"] = product.get("productID") == PRODUCT_ID
    checks["StoreKit non-consumable"] = product.get("type") == "NonConsumable"
    checks["StoreKit local price"] = str(product.get("displayPrice")) == "14.99"
    locales = {loc.get("locale") for loc in product.get("localizations", [])}
    checks["StoreKit EN/DE localizations"] = {"en_US", "de_DE"}.issubset(locales)

asc = json.loads(ASC_JSON.read_text())
app = asc.get("app", {})
iap = asc.get("inAppPurchase", {})
localizations = asc.get("localizations", {})
export_compliance = asc.get("exportCompliance", {})
checks["ASC JSON app name"] = app.get("name") == DISPLAY_NAME
checks["ASC JSON bundle id"] = app.get("bundleId") == BUNDLE_ID
checks["ASC JSON URLs"] = (
    app.get("marketingUrl") == MARKETING_URL
    and app.get("supportUrl") == SUPPORT_URL
    and app.get("privacyPolicyUrl") == PRIVACY_URL
)
checks["ASC JSON IAP id"] = iap.get("productId") == PRODUCT_ID
checks["ASC JSON IAP non-consumable"] = iap.get("type") == "NON_CONSUMABLE"
checks["ASC JSON IAP launch price"] = str(iap.get("launchPriceDirectionEUR")) == "14.99"
checks["ASC JSON DE/EN metadata"] = {"de-DE", "en-US"}.issubset(localizations.keys())
checks["ASC JSON non-exempt encryption false"] = export_compliance.get("usesNonExemptEncryption") is False

for locale, limits in {
    "de-DE": {"name": 30, "subtitle": 30, "promotionalText": 170, "keywords": 100},
    "en-US": {"name": 30, "subtitle": 30, "promotionalText": 170, "keywords": 100},
}.items():
    data = localizations.get(locale, {})
    for field, limit in limits.items():
        value = data.get(field, "")
        checks[f"ASC {locale} {field} present"] = bool(value)
        checks[f"ASC {locale} {field} <= {limit}"] = len(value) <= limit

icon_manifest = json.loads(ICON_CONTENTS.read_text())
images = icon_manifest.get("images", [])
checks["icon manifest file"] = any(i.get("filename") == ICON.name for i in images)

png = ICON.read_bytes()
checks["icon PNG signature"] = png.startswith(b"\x89PNG\r\n\x1a\n")
if checks["icon PNG signature"] and len(png) >= 33:
    width, height, bit_depth, color_type = struct.unpack(">IIBB", png[16:26])[:4]
    checks["icon 1024x1024"] = (width, height) == (1024, 1024)
    checks["icon 8-bit"] = bit_depth == 8
    # PNG color type 2 = truecolor RGB. App Store icons must not contain alpha.
    checks["icon has no alpha channel"] = color_type == 2
else:
    checks["icon 1024x1024"] = False
    checks["icon 8-bit"] = False
    checks["icon has no alpha channel"] = False

failed = [label for label, ok in checks.items() if not ok]
for label, ok in checks.items():
    print(("✓" if ok else "✗"), label)

if failed:
    raise SystemExit("Kamilunavo Trace release preflight failed: " + ", ".join(failed))

print("Kamilunavo Trace static release preflight passed")
