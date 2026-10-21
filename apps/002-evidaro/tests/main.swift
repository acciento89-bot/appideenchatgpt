import Foundation

func check(_ condition: @autoclosure () throws -> Bool, _ label: String) rethrows {
    guard try condition() else { fatalError("FAIL: \(label)") }; print("PASS: \(label)")
}
func rejects(_ label: String, _ action: () throws -> Void) {
    do { try action(); fatalError("FAIL: \(label)") } catch { print("PASS: \(label)") }
}
let caseID = "11111111-1111-4111-8111-111111111111"
let firstID = "22222222-2222-4222-8222-222222222222"
let nextID = "33333333-3333-4333-8333-333333333333"
func record(_ id: String, note: String = "Original note", time: Double = 100) -> EvidenceVerificationBundleItem {
    let date = Date(timeIntervalSince1970: time)
    return EvidenceVerificationBundleItem(id: id, kindRawValue: "Observation", recordedAtCanonical: String(time), source: "Measured onsite", note: note,
        contentHash: EvidenceHasher.itemHash(kind: .observation, source: "Measured onsite", note: note, recordedAt: date, mediaHash: nil))
}
func document(_ items: [EvidenceVerificationBundleItem]) -> EvidenceVerificationBundleDocument {
    EvidenceVerificationBundleDocument(format: EvidenceVerificationBundleDocument.formatIdentifier, version: 1, exportedAtCanonical: "200.0", caseID: caseID, title: "Claim", kindRawValue: "Property", createdAtCanonical: "50.0", items: items, seals: [])
}
func snapshot(_ d: EvidenceVerificationBundleDocument) throws -> TraceVerifiedPacket {
    try TraceVerifiedPacket.load(data: EvidenceBundleCodec.encode(d), sourceName: "fixture.evpack")
}
let original = document([record(firstID)])
let sourceBytes = try EvidenceBundleCodec.encode(original)
let baseline = try TraceVerifiedPacket.load(data: sourceBytes, sourceName: "baseline.evpack")
let same = try TracePacketComparison.compare(baseline: baseline, candidate: snapshot(original))
check(same.records.isEmpty && same.unchangedCount == 1, "identical packet no changes")
check(baseline.bundleHash == EvidenceHasher.sha256(sourceBytes), "exact source packet hash retained")
try check(sourceBytes == (try EvidenceBundleCodec.encode(original)), "import leaves original packet bytes unchanged")
var proposed = original; proposed.items = [record(firstID, note: "Revised note"), record(nextID, note: "New observation", time: 101)]
let diff = try TracePacketComparison.compare(baseline: baseline, candidate: snapshot(proposed))
check(diff.records.map(\.kind) == [.modified, .added], "stable UUID order with changed and added records")
check(diff.records[0].fields.contains(where: { $0.key == "note" && $0.before == "Original note" && $0.after == "Revised note" }), "modified field includes exact before and after")
let reversed = try TracePacketComparison.compare(baseline: snapshot(proposed), candidate: baseline)
check(reversed.records.last?.kind == .removed, "explicit swap reverses additions/removals")
var contextA = original
contextA.items[0].source = "a\nnote=b"; contextA.items[0].note = "c"
contextA.items[0].contentHash = EvidenceHasher.itemHash(kind: .observation, source: contextA.items[0].source, note: contextA.items[0].note, recordedAt: Date(timeIntervalSince1970: 100), mediaHash: nil)
var contextB = contextA
contextB.items[0].source = "a"; contextB.items[0].note = "b\nnote=c"
contextB.items[0].contentHash = EvidenceHasher.itemHash(kind: .observation, source: contextB.items[0].source, note: contextB.items[0].note, recordedAt: Date(timeIntervalSince1970: 100), mediaHash: nil)
check(contextA.items[0].contentHash == contextB.items[0].contentHash, "existing canonical hash semantics retained")
let contextual = try TracePacketComparison.compare(baseline: snapshot(contextA), candidate: snapshot(contextB))
check(contextual.records.first?.kind == .modified, "exact original fields compared even when recorded hash is unchanged")
var ocr = original; ocr.items[0].recognizedText = "Derived OCR"; ocr.items[0].recognizedTextEngine = "Vision"
let derived = try TracePacketComparison.compare(baseline: baseline, candidate: snapshot(ocr))
check(derived.records.first?.kind == .metadataOnly, "OCR change is separate from original record changes")
check(derived.records.first?.fields.allSatisfy { $0.category == .derived } == true, "OCR fields labelled derived not hash-protected")
var named = original; named.items[0].mediaOriginalName = "Renamed metadata"
let renamed = try TracePacketComparison.compare(baseline: baseline, candidate: snapshot(named))
check(renamed.records.first?.fields.first?.category == .attachmentMetadata, "attachment metadata distinct from original record")
var title = original; title.title = "Renamed claim"
try check(try TracePacketComparison.compare(baseline: baseline, candidate: snapshot(title)).caseFields.contains { $0.key == "title" }, "case metadata differences visible")
var tampered = original; tampered.items[0].note = "Tamper without rehash"
rejects("actual existing verifier rejects tamper") { _ = try snapshot(tampered) }
var other = original; other.caseID = "44444444-4444-4444-8444-444444444444"
rejects("different cases cannot be compared") { _ = try TracePacketComparison.compare(baseline: baseline, candidate: snapshot(other)) }
var duplicate = original; duplicate.items.append(duplicate.items[0])
rejects("duplicate record identity blocked") { _ = try snapshot(duplicate) }
var invalidTime = original; invalidTime.exportedAtCanonical = "NaN"
rejects("nonfinite timestamp blocked") { _ = try snapshot(invalidTime) }
var future = original; future.version = 99
rejects("existing unsupported version rejection preserved") { _ = try snapshot(future) }
rejects("malformed packet rejected") { _ = try TraceVerifiedPacket.load(data: Data("broken".utf8), sourceName: "bad.evpack") }
rejects("oversized packet rejected before decoding") { _ = try TraceVerifiedPacket.load(data: Data(repeating: 32, count: TraceVerifiedPacket.maximumBytes + 1), sourceName: "large.evpack") }
var media = original
let originalMedia = Data("Original image fixture".utf8)
media.items[0].mediaHash = EvidenceHasher.sha256(originalMedia)
media.items[0].mediaDataBase64 = originalMedia.base64EncodedString()
media.items[0].contentHash = EvidenceHasher.itemHash(kind: .observation, source: media.items[0].source, note: media.items[0].note, recordedAt: Date(timeIntervalSince1970: 100), mediaHash: media.items[0].mediaHash)
let mediaSnapshot = try snapshot(media)
check(mediaSnapshot.items.first?.mediaDataBase64 == nil, "import discards embedded originals after real verification")
var badMedia = media; badMedia.items[0].mediaDataBase64 = Data("Changed".utf8).base64EncodedString()
rejects("actual verifier rejects changed original bytes") { _ = try snapshot(badMedia) }
let originalVerification = try EvidenceBundleVerifier.verify(data: sourceBytes)
var sealed = original
sealed.seals = [EvidenceVerificationBundleSeal(id: "55555555-5555-4555-8555-555555555555", createdAtCanonical: "150.0", itemCount: 1, manifestHash: originalVerification.currentManifestHash)]
let sealDifference = try TracePacketComparison.compare(baseline: baseline, candidate: snapshot(sealed))
check(sealDifference.seals.first?.kind == .added, "valid added snapshot seal visible")
var excessive = document((0..<1000).map { record(UUID().uuidString, time: Double(100 + $0)) })
let excessiveHash = try EvidenceBundleVerifier.verify(data: EvidenceBundleCodec.encode(excessive)).currentManifestHash
excessive.seals = (0..<101).map { _ in
    EvidenceVerificationBundleSeal(id: UUID().uuidString, createdAtCanonical: "1500.0", itemCount: 1000, manifestHash: excessiveHash)
}
do {
    _ = try snapshot(excessive); fatalError("FAIL: verification work limit")
} catch TracePacketError.verificationWorkLimit {
    print("PASS: cumulative verification work limit checked before verifier")
} catch { fatalError("FAIL: wrong work-limit rejection \(error)") }
let en = diff.report(german: false), de = diff.report(german: true)
check(en.contains("Original note") && en.contains("Revised note") && en.contains("Measured onsite"), "report includes factual record context")
check(en.contains(baseline.bundleHash) && en.contains(diff.candidate.bundleHash), "report binds both exact packets")
check(en.contains("not") && de.contains("Vergleich"), "DEEN report includes trust boundary")
check(diff.report(german: false) == en, "report deterministic")
let changedSeal = try TracePacketComparison.compare(baseline: snapshot(sealed), candidate: baseline)
check(changedSeal.seals.first?.kind == .removed, "swap reverses seal addition")
var renamedSeal = sealed; renamedSeal.seals[0].createdAtCanonical = "160.0"
let sealMetadata = try TracePacketComparison.compare(baseline: snapshot(sealed), candidate: snapshot(renamedSeal))
check(sealMetadata.seals.first?.kind == .modified, "unhashed seal timestamp change visible without stronger trust claim")
check(sealMetadata.report(german: false).contains("Snapshot record changed"), "seal metadata report never labels an original-record change")
let aliased = document([record("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"), record("AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA")])
rejects("case-insensitive UUID aliases cannot bypass duplicate guard") { _ = try snapshot(aliased) }
let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: directory) }
let file = directory.appendingPathComponent("baseline.evpack")
try sourceBytes.write(to: file)
let fileSnapshot = try TraceVerifiedPacket.load(url: file)
check(fileSnapshot.bundleHash == baseline.bundleHash, "bounded file loader uses exact real packet bytes")
try check(try Data(contentsOf: file) == sourceBytes, "file import never rewrites original")

// This pathological fixture is preflight-only: never pass it to the unchanged
// verifier, which would otherwise hash over100GiB of repeated header bytes.
var amplified = document([])
amplified.title = String(repeating: "x", count: 10 * 1024 * 1024)
amplified.seals = (0..<10_000).map { _ in
    EvidenceVerificationBundleSeal(id: UUID().uuidString, createdAtCanonical: "150.0", itemCount: 0, manifestHash: String(repeating: "0", count: 64))
}
do {
    try TraceVerifiedPacket.checkVerificationBudget(document: amplified)
    fatalError("FAIL: repeated manifest-header byte budget")
} catch TracePacketError.verificationByteWorkLimit {
    print("PASS: repeated header byte amplification rejected without hashing")
} catch { fatalError("FAIL: wrong byte-budget rejection \(error)") }
var unicodeBudget = document([])
unicodeBudget.title = String(repeating: "🧾", count: 20_000)
unicodeBudget.seals = Array(amplified.seals.prefix(1000))
do {
    try TraceVerifiedPacket.checkVerificationBudget(document: unicodeBudget)
    fatalError("FAIL: UTF8 byte budget")
} catch TracePacketError.verificationByteWorkLimit {
    print("PASS: manifest budget counts UTF8 bytes rather than characters")
} catch { fatalError("FAIL: wrong UTF8 budget rejection \(error)") }
// Integration fixture would hash only~70MiB if the guard were accidentally
// omitted. It can safely prove that loading calls the real preflight guard.
var boundedAmplification = document([])
boundedAmplification.title = String(repeating: "x", count: 70 * 1024)
let boundedHash = try EvidenceBundleVerifier.verify(data: EvidenceBundleCodec.encode(boundedAmplification)).currentManifestHash
boundedAmplification.seals = (0..<1000).map { _ in
    EvidenceVerificationBundleSeal(id: UUID().uuidString, createdAtCanonical: "150.0", itemCount: 0, manifestHash: boundedHash)
}
do {
    _ = try snapshot(boundedAmplification)
    fatalError("FAIL: loader must invoke byte preflight")
} catch TracePacketError.verificationByteWorkLimit {
    print("PASS: loader rejects byte-work amplification before original verifier")
} catch { fatalError("FAIL: wrong loader byte-budget rejection \(error)") }
try TraceVerifiedPacket.checkVerificationBudget(document: original)
print("PASS: ordinary packet remains within verification byte budget")
if let fixturePath = ProcessInfo.processInfo.environment["TRACE_NATIVE_FIXTURE_DIR"] {
    let baseURL = URL(fileURLWithPath: fixturePath, isDirectory: true)
    let a = try TraceVerifiedPacket.load(url: baseURL.appendingPathComponent("Trace-QA-Baseline.evpack"))
    let b = try TraceVerifiedPacket.load(url: baseURL.appendingPathComponent("Trace-QA-Candidate.evpack"))
    let pair = try TracePacketComparison.compare(baseline: a, candidate: b)
    check(a.verifiedSealCount == 1 && b.verifiedSealCount == 1, "generated native fixture packets pass actual unchanged verifier")
    check(pair.records.filter { $0.kind == .added }.count == 1 && pair.records.filter { $0.kind == .modified }.count == 1, "generated native fixtures match intended record differences")
    check(pair.seals.filter { $0.kind == .added }.count == 1 && pair.seals.filter { $0.kind == .removed }.count == 1, "generated native fixtures match intended seal differences")
}
print("ALL TRACE PACKET COMPARISON TESTS PASSED")
