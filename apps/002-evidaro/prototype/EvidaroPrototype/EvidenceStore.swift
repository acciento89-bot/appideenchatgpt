import Combine
import CryptoKit
import Foundation

@MainActor
final class EvidenceStore: ObservableObject {
    @Published private(set) var cases: [EvidenceCase]

    init(seedDemoData: Bool = true) {
        if seedDemoData {
            let now = Date()
            let caseID = UUID()
            let caseCreatedAt = now.addingTimeInterval(-7_400)
            let firstRecordedAt = now.addingTimeInterval(-7_200)
            let secondRecordedAt = now.addingTimeInterval(-6_900)

            let firstNote = "Package arrived with a crushed upper-right corner and a visible tear along the seam."
            let firstSource = "Front door delivery"
            let firstItem = EvidenceItem(
                id: UUID(),
                kind: .observation,
                recordedAt: firstRecordedAt,
                source: firstSource,
                note: firstNote,
                contentHash: EvidenceHasher.itemHash(
                    kind: .observation,
                    source: firstSource,
                    note: firstNote,
                    recordedAt: firstRecordedAt
                )
            )

            let secondNote = "Outer packaging retained. Contents not yet discarded."
            let secondSource = "Follow-up note"
            let secondItem = EvidenceItem(
                id: UUID(),
                kind: .observation,
                recordedAt: secondRecordedAt,
                source: secondSource,
                note: secondNote,
                contentHash: EvidenceHasher.itemHash(
                    kind: .observation,
                    source: secondSource,
                    note: secondNote,
                    recordedAt: secondRecordedAt
                )
            )

            cases = [
                EvidenceCase(
                    id: caseID,
                    title: "Damaged delivery",
                    kind: .delivery,
                    createdAt: caseCreatedAt,
                    evidence: [firstItem, secondItem],
                    seals: []
                )
            ]
        } else {
            cases = []
        }
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

        cases.insert(
            EvidenceCase(
                id: UUID(),
                title: cleanTitle,
                kind: kind,
                createdAt: Date(),
                evidence: [],
                seals: []
            ),
            at: 0
        )
    }

    func addEvidence(caseID: UUID, kind: EvidenceItemKind, source: String, note: String) {
        guard let index = cases.firstIndex(where: { $0.id == caseID }) else { return }

        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNote.isEmpty else { return }

        let cleanSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let recordedAt = Date()
        let item = EvidenceItem(
            id: UUID(),
            kind: kind,
            recordedAt: recordedAt,
            source: cleanSource,
            note: cleanNote,
            contentHash: EvidenceHasher.itemHash(
                kind: kind,
                source: cleanSource,
                note: cleanNote,
                recordedAt: recordedAt
            )
        )

        cases[index].evidence.append(item)
    }

    @discardableResult
    func seal(caseID: UUID) -> EvidenceSeal? {
        guard let index = cases.firstIndex(where: { $0.id == caseID }) else { return nil }
        guard !cases[index].evidence.isEmpty else { return nil }

        let currentCase = cases[index]
        let manifest = EvidenceHasher.canonicalManifest(for: currentCase)
        let seal = EvidenceSeal(
            id: UUID(),
            createdAt: Date(),
            itemCount: currentCase.evidence.count,
            manifestHash: EvidenceHasher.sha256(manifest)
        )
        cases[index].seals.append(seal)
        return seal
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

        for (offset, item) in evidenceCase.evidence.enumerated() {
            lines.append("")
            lines.append("#\(offset + 1) \(item.kind.rawValue)")
            lines.append("Recorded: \(item.recordedAt.formatted(date: .abbreviated, time: .standard))")
            if !item.source.isEmpty {
                lines.append("Source: \(item.source)")
            }
            lines.append("Note: \(item.note)")
            lines.append("SHA-256: \(item.contentHash)")
        }

        if let latestSeal = evidenceCase.seals.last {
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
}

enum EvidenceHasher {
    static func itemHash(kind: EvidenceItemKind, source: String, note: String, recordedAt: Date) -> String {
        let canonical = [
            "kind=\(kind.rawValue)",
            "recordedAt=\(recordedAt.timeIntervalSince1970)",
            "source=\(source)",
            "note=\(note)"
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
            lines.append("item=\(item.id.uuidString)|\(item.recordedAt.timeIntervalSince1970)|\(item.contentHash)")
        }

        return lines.joined(separator: "\n")
    }

    static func sha256(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
