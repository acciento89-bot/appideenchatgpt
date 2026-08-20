import Combine
import CryptoKit
import Foundation
import SwiftData

@MainActor
final class EvidenceStore: ObservableObject {
    let container: ModelContainer
    private let context: ModelContext
    private let mediaDirectory: URL

    @Published private var revision = 0

    init(inMemory: Bool = false, seedDemoData: Bool = true) {
        do {
            let schema = Schema([
                EvidenceCase.self,
                EvidenceItem.self,
                EvidenceSeal.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)

            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
            mediaDirectory = appSupport.appendingPathComponent("EvidaroMedia", isDirectory: true)
            try FileManager.default.createDirectory(
                at: mediaDirectory,
                withIntermediateDirectories: true
            )

            if seedDemoData && fetchCases().isEmpty {
                seedDemoCase()
            }
        } catch {
            fatalError("Unable to create Evidaro local store: \(error)")
        }
    }

    var cases: [EvidenceCase] {
        _ = revision
        return fetchCases().sorted { $0.lastActivity > $1.lastActivity }
    }

    var totalEvidenceCount: Int {
        cases.reduce(0) { $0 + $1.evidence.count }
    }

    var totalSealCount: Int {
        cases.reduce(0) { $0 + $1.seals.count }
    }

    func caseForID(_ id: UUID) -> EvidenceCase? {
        cases.first { $0.id == id }
    }

    func createCase(title: String, kind: EvidenceCaseKind) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let evidenceCase = EvidenceCase(
            title: cleanTitle,
            kind: kind,
            createdAt: Date()
        )
        context.insert(evidenceCase)
        saveAndRefresh()
    }

    func addEvidence(
        caseID: UUID,
        kind: EvidenceItemKind,
        source: String,
        note: String,
        media: EvidenceMediaDraft? = nil
    ) throws {
        guard let evidenceCase = caseForID(caseID) else { return }

        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNote.isEmpty || media != nil else { return }

        let recordedAt = Date()
        let itemID = UUID()
        let mediaHash = media.map { EvidenceHasher.sha256($0.data) }
        let storedMedia = try media.map { try persistMedia($0, itemID: itemID) }
        let contentHash = EvidenceHasher.itemHash(
            kind: kind,
            source: cleanSource,
            note: cleanNote,
            recordedAt: recordedAt,
            mediaHash: mediaHash
        )

        let item = EvidenceItem(
            id: itemID,
            kind: kind,
            recordedAt: recordedAt,
            source: cleanSource,
            note: cleanNote,
            contentHash: contentHash,
            mediaFileName: storedMedia?.storedName,
            mediaOriginalName: media?.originalName,
            mediaUTType: media?.utTypeIdentifier,
            mediaHash: mediaHash
        )

        evidenceCase.evidence.append(item)
        saveAndRefresh()
    }

    @discardableResult
    func seal(caseID: UUID) -> EvidenceSeal? {
        guard let evidenceCase = caseForID(caseID), !evidenceCase.evidence.isEmpty else {
            return nil
        }

        let manifest = EvidenceHasher.canonicalManifest(for: evidenceCase)
        let seal = EvidenceSeal(
            createdAt: Date(),
            itemCount: evidenceCase.evidence.count,
            manifestHash: EvidenceHasher.sha256(manifest)
        )
        evidenceCase.seals.append(seal)
        saveAndRefresh()
        return seal
    }

    func mediaURL(for item: EvidenceItem) -> URL? {
        guard let mediaFileName = item.mediaFileName else { return nil }
        let url = mediaDirectory.appendingPathComponent(mediaFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func shareManifest(caseID: UUID) -> String {
        guard let evidenceCase = caseForID(caseID) else { return "" }

        var lines: [String] = [
            "EVIDARO EVIDENCE MANIFEST",
            "Case: \(evidenceCase.title)",
            "Type: \(evidenceCase.kind.rawValue)",
            "Case ID: \(evidenceCase.id.uuidString)",
            "Created: \(evidenceCase.createdAt.formatted(date: .abbreviated, time: .standard))",
            "",
            "Evidence items: \(evidenceCase.evidence.count)"
        ]

        for (offset, item) in evidenceCase.evidence.sorted(by: { $0.recordedAt < $1.recordedAt }).enumerated() {
            lines.append("")
            lines.append("#\(offset + 1) \(item.kind.rawValue)")
            lines.append("Recorded: \(item.recordedAt.formatted(date: .abbreviated, time: .standard))")
            if !item.source.isEmpty {
                lines.append("Source: \(item.source)")
            }
            if !item.note.isEmpty {
                lines.append("Note: \(item.note)")
            }
            if let originalName = item.mediaOriginalName {
                lines.append("Original file: \(originalName)")
            }
            if let mediaHash = item.mediaHash {
                lines.append("Original media SHA-256: \(mediaHash)")
            }
            lines.append("Evidence record SHA-256: \(item.contentHash)")
        }

        if let latestSeal = evidenceCase.seals.max(by: { $0.createdAt < $1.createdAt }) {
            lines.append("")
            lines.append("LATEST SNAPSHOT SEAL")
            lines.append("Sealed: \(latestSeal.createdAt.formatted(date: .abbreviated, time: .standard))")
            lines.append("Items: \(latestSeal.itemCount)")
            lines.append("Manifest SHA-256: \(latestSeal.manifestHash)")
        } else {
            lines.append("")
            lines.append("No snapshot has been sealed yet.")
        }

        lines.append("")
        lines.append("Integrity aid only. Evidaro does not provide legal advice or guarantee admissibility.")
        return lines.joined(separator: "\n")
    }

    private func fetchCases() -> [EvidenceCase] {
        (try? context.fetch(FetchDescriptor<EvidenceCase>())) ?? []
    }

    private func saveAndRefresh() {
        do {
            try context.save()
            revision += 1
        } catch {
            assertionFailure("Evidaro persistence save failed: \(error)")
        }
    }

    private func seedDemoCase() {
        let now = Date()
        let caseCreatedAt = now.addingTimeInterval(-7_400)
        let firstRecordedAt = now.addingTimeInterval(-7_200)
        let secondRecordedAt = now.addingTimeInterval(-6_900)

        let firstNote = "Package arrived with a crushed upper-right corner and a visible tear along the seam."
        let firstSource = "Front door delivery"
        let firstItem = EvidenceItem(
            kind: .observation,
            recordedAt: firstRecordedAt,
            source: firstSource,
            note: firstNote,
            contentHash: EvidenceHasher.itemHash(
                kind: .observation,
                source: firstSource,
                note: firstNote,
                recordedAt: firstRecordedAt,
                mediaHash: nil
            )
        )

        let secondNote = "Outer packaging retained. Contents not yet discarded."
        let secondSource = "Follow-up note"
        let secondItem = EvidenceItem(
            kind: .observation,
            recordedAt: secondRecordedAt,
            source: secondSource,
            note: secondNote,
            contentHash: EvidenceHasher.itemHash(
                kind: .observation,
                source: secondSource,
                note: secondNote,
                recordedAt: secondRecordedAt,
                mediaHash: nil
            )
        )

        let evidenceCase = EvidenceCase(
            title: "Damaged delivery",
            kind: .delivery,
            createdAt: caseCreatedAt,
            evidence: [firstItem, secondItem]
        )
        context.insert(evidenceCase)
        saveAndRefresh()
    }

    private func persistMedia(
        _ media: EvidenceMediaDraft,
        itemID: UUID
    ) throws -> (storedName: String, url: URL) {
        let originalExtension = (media.originalName as NSString).pathExtension
        let safeExtension = originalExtension.isEmpty ? "bin" : originalExtension.lowercased()
        let storedName = "\(itemID.uuidString).\(safeExtension)"
        let url = mediaDirectory.appendingPathComponent(storedName)
        try media.data.write(to: url, options: .atomic)
        return (storedName, url)
    }

#if DEBUG
    private static let smokeCaseID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    private static let smokeItemID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    private static let smokeSealID = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!
    private static let smokeCreatedAt = Date(timeIntervalSince1970: 1_787_000_000)
    private static let smokeRecordedAt = Date(timeIntervalSince1970: 1_787_000_120)
    private static let smokeMediaData = Data("evidaro-persistence-smoke-media-v1".utf8)

    func preparePersistenceSmoke() throws -> String {
        if let existing = fetchCases().first(where: { $0.id == Self.smokeCaseID }) {
            for item in existing.evidence {
                if let url = mediaURL(for: item) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            context.delete(existing)
            try context.save()
        }

        let media = EvidenceMediaDraft(
            data: Self.smokeMediaData,
            originalName: "persistence-smoke.bin",
            utTypeIdentifier: "public.data"
        )
        let mediaHash = EvidenceHasher.sha256(media.data)
        let storedMedia = try persistMedia(media, itemID: Self.smokeItemID)
        let note = "Process-relaunch persistence smoke"
        let source = "GitHub Actions simulator"
        let contentHash = EvidenceHasher.itemHash(
            kind: .document,
            source: source,
            note: note,
            recordedAt: Self.smokeRecordedAt,
            mediaHash: mediaHash
        )

        let item = EvidenceItem(
            id: Self.smokeItemID,
            kind: .document,
            recordedAt: Self.smokeRecordedAt,
            source: source,
            note: note,
            contentHash: contentHash,
            mediaFileName: storedMedia.storedName,
            mediaOriginalName: media.originalName,
            mediaUTType: media.utTypeIdentifier,
            mediaHash: mediaHash
        )
        let evidenceCase = EvidenceCase(
            id: Self.smokeCaseID,
            title: "CI Persistence Smoke",
            kind: .other,
            createdAt: Self.smokeCreatedAt,
            evidence: [item]
        )
        context.insert(evidenceCase)

        let seal = EvidenceSeal(
            id: Self.smokeSealID,
            createdAt: Self.smokeRecordedAt.addingTimeInterval(60),
            itemCount: 1,
            manifestHash: EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: evidenceCase))
        )
        evidenceCase.seals.append(seal)
        try context.save()
        revision += 1

        return "prepared case=\(evidenceCase.id.uuidString) mediaHash=\(mediaHash) seal=\(seal.manifestHash)"
    }

    func verifyPersistenceSmoke() throws -> String {
        guard let evidenceCase = fetchCases().first(where: { $0.id == Self.smokeCaseID }) else {
            throw PersistenceSmokeError.missingCase
        }
        guard evidenceCase.evidence.count == 1,
              let item = evidenceCase.evidence.first(where: { $0.id == Self.smokeItemID }) else {
            throw PersistenceSmokeError.missingEvidence
        }
        guard evidenceCase.seals.count == 1,
              let seal = evidenceCase.seals.first(where: { $0.id == Self.smokeSealID }) else {
            throw PersistenceSmokeError.missingSeal
        }
        guard let mediaURL = mediaURL(for: item) else {
            throw PersistenceSmokeError.missingMedia
        }

        let storedData = try Data(contentsOf: mediaURL)
        guard storedData == Self.smokeMediaData else {
            throw PersistenceSmokeError.mediaBytesChanged
        }
        let expectedMediaHash = EvidenceHasher.sha256(storedData)
        guard item.mediaHash == expectedMediaHash else {
            throw PersistenceSmokeError.mediaHashMismatch
        }
        let expectedItemHash = EvidenceHasher.itemHash(
            kind: item.kind,
            source: item.source,
            note: item.note,
            recordedAt: item.recordedAt,
            mediaHash: item.mediaHash
        )
        guard item.contentHash == expectedItemHash else {
            throw PersistenceSmokeError.itemHashMismatch
        }
        let expectedSealHash = EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: evidenceCase))
        guard seal.itemCount == 1, seal.manifestHash == expectedSealHash else {
            throw PersistenceSmokeError.sealMismatch
        }

        return "verified case=\(evidenceCase.id.uuidString) mediaHash=\(expectedMediaHash) seal=\(expectedSealHash)"
    }
#endif
}

#if DEBUG
private enum PersistenceSmokeError: LocalizedError {
    case missingCase
    case missingEvidence
    case missingSeal
    case missingMedia
    case mediaBytesChanged
    case mediaHashMismatch
    case itemHashMismatch
    case sealMismatch

    var errorDescription: String? {
        switch self {
        case .missingCase: "Persistence smoke case did not survive process restart."
        case .missingEvidence: "Persistence smoke evidence did not survive process restart."
        case .missingSeal: "Persistence smoke seal did not survive process restart."
        case .missingMedia: "Persistence smoke media reference did not survive process restart."
        case .mediaBytesChanged: "Persistence smoke media bytes changed after process restart."
        case .mediaHashMismatch: "Persistence smoke media hash no longer matches stored bytes."
        case .itemHashMismatch: "Persistence smoke evidence-record hash no longer matches persisted fields."
        case .sealMismatch: "Persistence smoke seal no longer matches the persisted manifest."
        }
    }
}
#endif

enum EvidenceHasher {
    static func itemHash(
        kind: EvidenceItemKind,
        source: String,
        note: String,
        recordedAt: Date,
        mediaHash: String?
    ) -> String {
        let canonical = [
            "kind=\(kind.rawValue)",
            "recordedAt=\(recordedAt.timeIntervalSince1970)",
            "source=\(source)",
            "note=\(note)",
            "mediaHash=\(mediaHash ?? "none")"
        ].joined(separator: "\n")
        return sha256(canonical)
    }

    static func canonicalManifest(for evidenceCase: EvidenceCase) -> String {
        var lines = [
            "caseID=\(evidenceCase.id.uuidString)",
            "title=\(evidenceCase.title)",
            "kind=\(evidenceCase.kind.rawValue)",
            "createdAt=\(evidenceCase.createdAt.timeIntervalSince1970)"
        ]

        for item in evidenceCase.evidence.sorted(by: { $0.recordedAt < $1.recordedAt }) {
            lines.append(
                "item=\(item.id.uuidString)|\(item.recordedAt.timeIntervalSince1970)|\(item.contentHash)|\(item.mediaHash ?? "none")"
            )
        }

        return lines.joined(separator: "\n")
    }

    static func sha256(_ value: String) -> String {
        sha256(Data(value.utf8))
    }

    static func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
