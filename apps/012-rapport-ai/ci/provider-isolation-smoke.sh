#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
QA_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rapport-provider-isolation.XXXXXX")
trap 'rm -rf "$QA_DIR"' EXIT
xcrun swiftc -emit-module -emit-library -module-name StoreKit ci/ProviderIsolationStoreKitStub.swift -o "$QA_DIR/libStoreKit.dylib" -emit-module-path "$QA_DIR/StoreKit.swiftmodule"
xcrun swiftc -DDEBUG -I "$QA_DIR" -L "$QA_DIR" -lStoreKit -parse-as-library prototype/RapportAI/EntitlementStore.swift ci/ProviderIsolationSmoke.swift -o "$QA_DIR/smoke"
DYLD_LIBRARY_PATH="$QA_DIR" "$QA_DIR/smoke" --rapportProviderDisabledQA

EXPECT_PROVIDER_CALLS=1 DYLD_LIBRARY_PATH="$QA_DIR" "$QA_DIR/smoke"
xcrun swiftc -I "$QA_DIR" -L "$QA_DIR" -lStoreKit -parse-as-library prototype/RapportAI/EntitlementStore.swift ci/ProviderIsolationSmoke.swift -o "$QA_DIR/release-smoke"
EXPECT_PROVIDER_CALLS=1 DYLD_LIBRARY_PATH="$QA_DIR" "$QA_DIR/release-smoke" --rapportProviderDisabledQA
