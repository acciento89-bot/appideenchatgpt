import Foundation

enum TracePacketError: LocalizedError {
    case oversized, excessiveRecords, verificationWorkLimit, verificationByteWorkLimit, invalidStructure, differentCase
    case integrityFailed([String])
    var errorDescription: String? {
        switch self {
        case .oversized: L10n.string("comparison.error_size")
        case .excessiveRecords: L10n.string("comparison.error_count")
        case .verificationWorkLimit, .verificationByteWorkLimit: L10n.string("comparison.error_work")
        case .invalidStructure: L10n.string("comparison.error_structure")
        case .differentCase: L10n.string("comparison.error_case")
        case .integrityFailed(let issues): L10n.string("comparison.error_integrity") + "\n" + issues.joined(separator: "\n")
        }
    }
}

/// Constructed only after the unchanged packet verifier passes. This is internal
/// consistency, never an assertion of authorship, chronology or external trust.
struct TraceVerifiedPacket: Sendable {
    static let maximumBytes = 20 * 1024 * 1024
    static let maximumRecords = 10_000
    static let maximumSealEntries = 100_000
    static let maximumVerificationBytes = 64 * 1024 * 1024
    let sourceName: String
    let caseID: String
    let title: String
    let kindRawValue: String
    let createdAtCanonical: String
    let exportedAtCanonical: String
    let items: [EvidenceVerificationBundleItem]
    let seals: [EvidenceVerificationBundleSeal]
    let bundleHash: String
    let manifestHash: String
    let verifiedSealCount: Int

    private init(document: EvidenceVerificationBundleDocument, sourceName: String, verification: EvidenceBundleVerificationResult) {
        self.sourceName = sourceName
        caseID = Self.normalizedID(document.caseID)
        title = document.title; kindRawValue = document.kindRawValue
        createdAtCanonical = document.createdAtCanonical; exportedAtCanonical = document.exportedAtCanonical
        // Original bytes were already checked. Do not retain a second in-memory
        // copy of embedded media while showing a comparison.
        items = document.items.map { item in var copy = item; copy.mediaDataBase64 = nil; return copy }
        seals = document.seals
        bundleHash = verification.bundleHash; manifestHash = verification.currentManifestHash
        verifiedSealCount = verification.verifiedSealCount
    }
    static func load(url: URL) throws -> TraceVerifiedPacket {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var bytes = Data()
        while let chunk = try handle.read(upToCount: min(65_536, maximumBytes + 1 - bytes.count)), !chunk.isEmpty {
            bytes.append(chunk)
            guard bytes.count <= maximumBytes else { throw TracePacketError.oversized }
        }
        return try load(data: bytes, sourceName: url.lastPathComponent)
    }
    static func load(data: Data, sourceName: String) throws -> TraceVerifiedPacket {
        guard data.count <= maximumBytes else { throw TracePacketError.oversized }
        let document = try EvidenceBundleCodec.decode(data)
        guard document.items.count <= maximumRecords, document.seals.count <= maximumRecords else { throw TracePacketError.excessiveRecords }
        func validTime(_ text: String) -> Bool { Double(text)?.isFinite == true }
        guard UUID(uuidString: document.caseID) != nil,
              validTime(document.createdAtCanonical), validTime(document.exportedAtCanonical),
              document.items.allSatisfy({ UUID(uuidString: $0.id) != nil && validTime($0.recordedAtCanonical) && ($0.recognizedTextAtCanonical.map(validTime) ?? true) }),
              document.seals.allSatisfy({ UUID(uuidString: $0.id) != nil && validTime($0.createdAtCanonical) }),
              Set(document.items.map { normalizedID($0.id) }).count == document.items.count,
              Set(document.seals.map { normalizedID($0.id) }).count == document.seals.count else { throw TracePacketError.invalidStructure }
        var sealEntries = 0
        for seal in document.seals {
            guard seal.itemCount >= 0, seal.itemCount <= document.items.count else { throw TracePacketError.invalidStructure }
            guard seal.itemCount <= maximumSealEntries - sealEntries else { throw TracePacketError.verificationWorkLimit }
            sealEntries += seal.itemCount
        }
        try checkVerificationBudget(document: document)
        // Preserve all original format/version/hash/media/seal checks verbatim.
        let verification = try EvidenceBundleVerifier.verify(data: data)
        guard verification.isValid else { throw TracePacketError.integrityFailed(verification.issues) }
        return TraceVerifiedPacket(document: document, sourceName: sourceName, verification: verification)
    }
    /// Bounds the exact UTF8 bytes the existing verifier will hash for its
    /// current manifest and every seal-prefix manifest. Headers repeat even for
    /// empty seals. No manifests or hashes are constructed in this preflight.
    static func checkVerificationBudget(document: EvidenceVerificationBundleDocument) throws {
        guard document.items.count <= maximumRecords, document.seals.count <= maximumRecords else { throw TracePacketError.excessiveRecords }
        // Saturate at limit+1, avoiding addition/multiplication overflow and
        // unnecessary counting once any component already exceeds the budget.
        func cappedSum(_ values: [Int]) -> Int {
            var sum = 0
            for value in values {
                guard value <= maximumVerificationBytes - sum else { return maximumVerificationBytes + 1 }
                sum += value
            }
            return sum
        }
        let header = cappedSum([
            "caseID=".utf8.count, document.caseID.utf8.count, 1,
            "title=".utf8.count, document.title.utf8.count, 1,
            "kind=".utf8.count, document.kindRawValue.utf8.count, 1,
            "createdAt=".utf8.count, document.createdAtCanonical.utf8.count
        ])
        // Entry byte counts include the newline before each item and the exact
        // separators used by EvidenceBundleVerifier.canonicalManifest.
        var prefixes = [0]
        prefixes.reserveCapacity(document.items.count + 1)
        for item in document.items {
            let bytes = cappedSum([1, "item=".utf8.count, item.id.utf8.count, 1,
                                   item.recordedAtCanonical.utf8.count, 1,
                                   item.contentHash.utf8.count, 1, (item.mediaHash ?? "none").utf8.count])
            prefixes.append(cappedSum([prefixes.last!, bytes]))
        }
        var remaining = maximumVerificationBytes
        func charge(_ bytes: Int) throws {
            guard bytes <= remaining else { throw TracePacketError.verificationByteWorkLimit }
            remaining -= bytes
        }
        try charge(header)
        try charge(prefixes.last!)
        for seal in document.seals {
            guard seal.itemCount >= 0, seal.itemCount <= document.items.count else { throw TracePacketError.invalidStructure }
            try charge(header)
            try charge(prefixes[seal.itemCount])
        }
    }
    fileprivate static func normalizedID(_ value: String) -> String { UUID(uuidString: value)?.uuidString ?? value }
}

enum TraceDifferenceKind: String, Sendable { case added, removed, modified, metadataOnly }
enum TraceFieldCategory: String, Sendable { case original, derived, attachmentMetadata, caseMetadata, snapshot }
struct TraceFieldChange: Sendable {
    let key: String
    let category: TraceFieldCategory
    let before: String?
    let after: String?
}
struct TraceRecordChange: Identifiable, Sendable {
    let id: String
    let kind: TraceDifferenceKind
    let fields: [TraceFieldChange]
}
struct TraceSealChange: Identifiable, Sendable {
    let id: String
    let kind: TraceDifferenceKind
    let fields: [TraceFieldChange]
}

struct TracePacketComparison: Sendable {
    let baseline: TraceVerifiedPacket
    let candidate: TraceVerifiedPacket
    let records: [TraceRecordChange]
    let seals: [TraceSealChange]
    let caseFields: [TraceFieldChange]
    let unchangedCount: Int

    static func compare(baseline: TraceVerifiedPacket, candidate: TraceVerifiedPacket) throws -> TracePacketComparison {
        guard baseline.caseID == candidate.caseID else { throw TracePacketError.differentCase }
        let before = Dictionary(uniqueKeysWithValues: baseline.items.map { (TraceVerifiedPacket.normalizedID($0.id), $0) })
        let after = Dictionary(uniqueKeysWithValues: candidate.items.map { (TraceVerifiedPacket.normalizedID($0.id), $0) })
        var records: [TraceRecordChange] = [], unchanged = 0
        for id in Set(before.keys).union(after.keys).sorted() {
            let fields = changes(before: before[id].map(recordFields) ?? [], after: after[id].map(recordFields) ?? [])
            guard !fields.isEmpty else { unchanged += 1; continue }
            let kind: TraceDifferenceKind = before[id] == nil ? .added : after[id] == nil ? .removed : fields.contains { $0.category == .original } ? .modified : .metadataOnly
            records.append(TraceRecordChange(id: id, kind: kind, fields: fields))
        }
        let oldSeals = Dictionary(uniqueKeysWithValues: baseline.seals.map { (TraceVerifiedPacket.normalizedID($0.id), $0) })
        let newSeals = Dictionary(uniqueKeysWithValues: candidate.seals.map { (TraceVerifiedPacket.normalizedID($0.id), $0) })
        var seals: [TraceSealChange] = []
        for id in Set(oldSeals.keys).union(newSeals.keys).sorted() {
            let fields = changes(before: oldSeals[id].map(sealFields) ?? [], after: newSeals[id].map(sealFields) ?? [])
            if !fields.isEmpty { seals.append(TraceSealChange(id: id, kind: oldSeals[id] == nil ? .added : newSeals[id] == nil ? .removed : .modified, fields: fields)) }
        }
        return TracePacketComparison(baseline: baseline, candidate: candidate, records: records, seals: seals,
                                     caseFields: changes(before: caseFields(baseline), after: caseFields(candidate)), unchangedCount: unchanged)
    }
    private struct Field { let key: String; let category: TraceFieldCategory; let value: String? }
    private static func recordFields(_ i: EvidenceVerificationBundleItem) -> [Field] {
        [Field(key: "kind", category: .original, value: i.kindRawValue),
         Field(key: "recordedAt", category: .original, value: i.recordedAtCanonical),
         Field(key: "source", category: .original, value: i.source), Field(key: "note", category: .original, value: i.note),
         Field(key: "contentHash", category: .original, value: i.contentHash), Field(key: "mediaHash", category: .original, value: i.mediaHash),
         Field(key: "mediaOriginalName", category: .attachmentMetadata, value: i.mediaOriginalName), Field(key: "mediaUTType", category: .attachmentMetadata, value: i.mediaUTType),
         Field(key: "recognizedText", category: .derived, value: i.recognizedText), Field(key: "recognizedTextAt", category: .derived, value: i.recognizedTextAtCanonical),
         Field(key: "recognizedTextEngine", category: .derived, value: i.recognizedTextEngine), Field(key: "recognizedTextPageCount", category: .derived, value: i.recognizedTextPageCount.map(String.init))]
    }
    private static func sealFields(_ s: EvidenceVerificationBundleSeal) -> [Field] {
        [Field(key: "createdAt", category: .snapshot, value: s.createdAtCanonical), Field(key: "itemCount", category: .snapshot, value: String(s.itemCount)), Field(key: "manifestHash", category: .snapshot, value: s.manifestHash)]
    }
    private static func caseFields(_ p: TraceVerifiedPacket) -> [Field] {
        [Field(key: "title", category: .caseMetadata, value: p.title), Field(key: "kind", category: .caseMetadata, value: p.kindRawValue), Field(key: "createdAt", category: .caseMetadata, value: p.createdAtCanonical)]
    }
    private static func changes(before: [Field], after: [Field]) -> [TraceFieldChange] {
        let order = before.isEmpty ? after.map(\.key) : before.map(\.key)
        let old = Dictionary(uniqueKeysWithValues: before.map { ($0.key, $0) })
        let new = Dictionary(uniqueKeysWithValues: after.map { ($0.key, $0) })
        return order.compactMap { key in
            let a = old[key], b = new[key]
            guard a?.value != b?.value else { return nil }
            return TraceFieldChange(key: key, category: (a ?? b)!.category, before: a?.value, after: b?.value)
        }
    }

    func report(german: Bool) -> String {
        func l(_ en: String, _ de: String) -> String { german ? de : en }
        func quoted(_ text: String?) -> String {
            guard let text else { return "null" }
            return String(data: (try? JSONEncoder().encode(text)) ?? Data(), encoding: .utf8) ?? "\"\""
        }
        func packet(_ p: TraceVerifiedPacket, _ title: String) -> [String] {
            [title, l("Source label: ", "Quelldatei: ") + quoted(p.sourceName), l("Case title: ", "Falltitel: ") + quoted(p.title),
             "Case ID: \(p.caseID)", "SHA-256: \(p.bundleHash)", "Manifest SHA-256: \(p.manifestHash)",
             l("Items / internally verified seals: ", "Elemente / intern geprüfte Siegel: ") + "\(p.items.count) / \(p.verifiedSealCount)",
             l("Export time metadata (Unix seconds, untrusted): ", "Exportzeit-Metadaten (Unix-Sekunden, nicht unabhängig bestätigt): ") + quoted(p.exportedAtCanonical)]
        }
        var lines = ["Kamilunavo Trace — " + l("Packet comparison", "Paketvergleich"),
                     l("Direction is explicitly selected; candidate is not asserted to be newer.", "Die Vergleichsrichtung ist ausdrücklich gewählt; das Vergleichspaket gilt nicht automatisch als neuer."), ""]
        lines += packet(baseline, l("BASELINE", "REFERENZ")) + [""] + packet(candidate, l("CANDIDATE", "VERGLEICHSPAKET"))
        lines += ["", l("Unchanged records: ", "Unveränderte Datensätze: ") + String(unchangedCount),
                  l("Added / removed / original-field modified / metadata-only: ", "Hinzugefügt / entfernt / Originalfelder geändert / nur Metadaten: ") +
                    [TraceDifferenceKind.added, .removed, .modified, .metadataOnly].map { kind in String(records.filter { $0.kind == kind }.count) }.joined(separator: " / "),
                  l("Values use JSON quoting; null means absent. Embedded line breaks are escaped.", "Werte sind als JSON-Zeichenfolgen dargestellt; null bedeutet nicht vorhanden. Enthaltene Zeilenumbrüche werden maskiert.")]
        func appendFields(_ fields: [TraceFieldChange]) {
            for field in fields {
                lines += [field.key + " [" + Self.categoryName(field.category, german: german) + "]",
                          l("Before: ", "Vorher: ") + quoted(field.before), l("After: ", "Nachher: ") + quoted(field.after)]
            }
        }
        if !caseFields.isEmpty { lines += ["", l("CASE METADATA CHANGES", "ÄNDERUNGEN DER FALL-METADATEN")]; appendFields(caseFields) }
        let oldRecords = Dictionary(uniqueKeysWithValues: baseline.items.map { (TraceVerifiedPacket.normalizedID($0.id), $0) })
        let newRecords = Dictionary(uniqueKeysWithValues: candidate.items.map { (TraceVerifiedPacket.normalizedID($0.id), $0) })
        for change in records {
            lines += ["", Self.kindName(change.kind, german: german) + " — " + change.id]
            appendFields(change.fields)
            for (recordsByID, label) in [(oldRecords, l("Full baseline record", "Vollständiger Referenzdatensatz")), (newRecords, l("Full candidate record", "Vollständiger Vergleichsdatensatz"))] {
                if let item = recordsByID[change.id] {
                    lines.append(label)
                    for field in Self.recordFields(item) { lines.append(field.key + " = " + quoted(field.value)) }
                }
            }
        }
        for seal in seals { lines += ["", l("SNAPSHOT RECORD", "SNAPSHOT-DATENSATZ") + " — " + Self.kindName(seal.kind, german: german, snapshot: true) + " — " + seal.id]; appendFields(seal.fields) }
        lines += ["", l("Boundary: both source packets passed the existing local internal-consistency checks for embedded original bytes, record hashes and recorded seals. This is not independent authorship, event-time, chronological-chain or legal verification. Derived OCR and attachment metadata are not protected by the original record hash. Snapshot time metadata is not an external timestamp. No imported original file was modified or attached to this difference report.",
            "Prüfgrenze: Beide Quellpakete bestanden die bestehenden lokalen Konsistenzprüfungen für eingebettete Originaldaten, Datensatz-Hashes und aufgezeichnete Siegel. Dies ist keine unabhängige Bestätigung von Urheberschaft, Ereigniszeit, zeitlicher Beweiskette oder rechtlicher Anerkennung. Abgeleiteter OCR-Text und Anhang-Metadaten sind nicht durch den ursprünglichen Datensatz-Hash geschützt. Snapshot-Zeitangaben sind keine externen Zeitstempel. Keine importierte Originaldatei wurde verändert oder diesem Vergleichsbericht beigefügt.")]
        return lines.joined(separator: "\n")
    }
    static func kindName(_ kind: TraceDifferenceKind, german: Bool, snapshot: Bool = false) -> String {
        switch kind {
        case .added: german ? "Hinzugefügt" : "Added"
        case .removed: german ? "Entfernt" : "Removed"
        case .modified: snapshot ? (german ? "Snapshot-Datensatz geändert" : "Snapshot record changed") : (german ? "Originalfelder geändert" : "Original fields changed")
        case .metadataOnly: german ? "Nur Metadaten geändert" : "Metadata only changed"
        }
    }
    static func categoryName(_ category: TraceFieldCategory, german: Bool) -> String {
        switch category {
        case .original: german ? "Original-Datensatzfeld" : "Original record field"
        case .derived: german ? "Abgeleiteter OCR-Wert, nicht im Original-Hash" : "Derived OCR, outside original hash"
        case .attachmentMetadata: german ? "Anhang-Metadaten, nicht im Original-Hash" : "Attachment metadata, outside original hash"
        case .caseMetadata: german ? "Fall-Metadaten" : "Case metadata"
        case .snapshot: german ? "Snapshot-Datensatz; keine externe Zeitbestätigung" : "Snapshot record; no external timestamp"
        }
    }
}
