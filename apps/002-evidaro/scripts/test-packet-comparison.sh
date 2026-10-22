#!/bin/bash
set -eu
TRACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/trace-packet-tests.XXXXXX")"
trap 'rm -rf "$TRACE_TMP"' EXIT
# Compile the exact existing pure verifier/model/hash sections, preserving their
# production implementations while excluding SwiftData/UIKit storage and smoke UI.
python3 - "$TRACE_ROOT" "$TRACE_TMP" <<'PY'
import pathlib,sys
root=pathlib.Path(sys.argv[1])/'prototype/EvidaroPrototype'; out=pathlib.Path(sys.argv[2])
models=(root/'Models.swift').read_text()
enums=models[models.index('enum EvidenceCaseKind'):models.index('@Model')]
bundle=models[models.index('struct EvidenceBundleExportResult'):models.index('extension EvidenceStore {')]
hasher=(root/'EvidenceStore.swift').read_text().split('enum EvidenceHasher {',1)[1]
item=hasher[:hasher.index('    static func canonicalManifest')]
sha=hasher[hasher.index('    static func sha256'):]
(out/'ProductionCore.swift').write_text('import Foundation\nimport CryptoKit\n'+enums+'\n'+bundle+'\nenum EvidenceHasher {'+item+sha)
PY
swiftc "$TRACE_TMP/ProductionCore.swift" "$TRACE_ROOT/prototype/EvidaroPrototype/Localization.swift" "$TRACE_ROOT/prototype/EvidaroPrototype/TracePacketComparison.swift" "$TRACE_ROOT/tests/main.swift" -o "$TRACE_TMP/tests"
"$TRACE_TMP/tests"
