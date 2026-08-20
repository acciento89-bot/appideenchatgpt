import Foundation
import SwiftData

enum EvidenceCaseKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case property = "Property"
    case delivery = "Delivery"
    case vehicle = "Vehicle"
    case contractor = "Contractor"
    case insurance = "Insurance"
    case workplace = "Workplace"
    case other = "Other"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .property: L10n.string("case.kind.property")
        case .delivery: L10n.string("case.kind.delivery")
        case .vehicle: L10n.string("case.kind.vehicle")
        case .contractor: L10n.string("case.kind.contractor")
        case .insurance: L10n.string("case.kind.insurance")
        case .workplace: L10n.string("case.kind.workplace")
        case .other: L10n.string("case.kind.other")
        }
    }

    var symbol: String {
        switch self {
        case .property: "house"
        case .delivery: "shippingbox"
        case .vehicle: "car"
        case .contractor: "wrench.and.screwdriver"
        case .insurance: "shield"
        case .workplace: "briefcase"
        case .other: "folder"
        }
    }
}

enum EvidenceItemKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case observation = "Observation"
    case photo = "Photo"
    case document = "Document"
    case message = "Message"
    case callNote = "Call note"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .observation: L10n.string("evidence.kind.observation")
        case .photo: L10n.string("evidence.kind.photo")
        case .document: L10n.string("evidence.kind.document")
        case .message: L10n.string("evidence.kind.message")
        case .callNote: L10n.string("evidence.kind.call_note")
        }
    }

    var symbol: String {
        switch self {
        case .observation: "note.text"
        case .photo: "photo"
        case .document: "doc.text"
        case .message: "bubble.left.and.bubble.right"
        case .callNote: "phone"
        }
    }
}

@Model
final class EvidenceItem {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var recordedAt: Date
    var source: String
    var note: String
    var contentHash: String
    var mediaFileName: String?
    var mediaOriginalName: String?
    var mediaUTType: String?
    var mediaHash: String?
    var recognizedText: String?
    var recognizedTextAt: Date?
    var recognizedTextEngine: String?
    var recognizedTextPageCount: Int?

    init(
        id: UUID = UUID(),
        kind: EvidenceItemKind,
        recordedAt: Date,
        source: String,
        note: String,
        contentHash: String,
        mediaFileName: String? = nil,
        mediaOriginalName: String? = nil,
        mediaUTType: String? = nil,
        mediaHash: String? = nil,
        recognizedText: String? = nil,
        recognizedTextAt: Date? = nil,
        recognizedTextEngine: String? = nil,
        recognizedTextPageCount: Int? = nil
    ) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.recordedAt = recordedAt
        self.source = source
        self.note = note
        self.contentHash = contentHash
        self.mediaFileName = mediaFileName
        self.mediaOriginalName = mediaOriginalName
        self.mediaUTType = mediaUTType
        self.mediaHash = mediaHash
        self.recognizedText = recognizedText
        self.recognizedTextAt = recognizedTextAt
        self.recognizedTextEngine = recognizedTextEngine
        self.recognizedTextPageCount = recognizedTextPageCount
    }

    var kind: EvidenceItemKind {
        EvidenceItemKind(rawValue: kindRawValue) ?? .observation
    }

    var hasMedia: Bool {
        mediaFileName != nil && mediaHash != nil
    }

    var hasRecognizedTextResult: Bool {
        recognizedTextAt != nil
    }
}

@Model
final class EvidenceSeal {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var itemCount: Int
    var manifestHash: String

    init(id: UUID = UUID(), createdAt: Date, itemCount: Int, manifestHash: String) {
        self.id = id
        self.createdAt = createdAt
        self.itemCount = itemCount
        self.manifestHash = manifestHash
    }
}

@Model
final class EvidenceCase {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRawValue: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var evidence: [EvidenceItem]

    @Relationship(deleteRule: .cascade)
    var seals: [EvidenceSeal]

    init(
        id: UUID = UUID(),
        title: String,
        kind: EvidenceCaseKind,
        createdAt: Date,
        evidence: [EvidenceItem] = [],
        seals: [EvidenceSeal] = []
    ) {
        self.id = id
        self.title = title
        self.kindRawValue = kind.rawValue
        self.createdAt = createdAt
        self.evidence = evidence
        self.seals = seals
    }

    var kind: EvidenceCaseKind {
        EvidenceCaseKind(rawValue: kindRawValue) ?? .other
    }

    var lastActivity: Date {
        max(
            evidence.map(\.recordedAt).max() ?? createdAt,
            seals.map(\.createdAt).max() ?? createdAt
        )
    }
}

struct EvidenceMediaDraft: Sendable {
    let data: Data
    let originalName: String
    let utTypeIdentifier: String
}

// MARK: - Offline verification bundle

struct EvidenceBundleExportResult: Sendable {
    let url: URL
    let bundleHash: String
    let verification: EvidenceBundleVerificationResult
}

struct EvidenceBundleVerificationResult: Identifiable, Sendable {
    let id = UUID()
    let isValid: Bool
    let caseTitle: String
    let caseID: String
    let itemCount: Int
    let sealCount: Int
    let verifiedSealCount: Int
    let currentManifestHash: String
    let bundleHash: String
    let issues: [String]
}

struct EvidenceVerificationBundleDocument: Codable, Sendable {
    static let formatIdentifier = "de.kamilunavo.trace.evpack"
    static let currentVersion = 1

    var format: String
    var version: Int
    var exportedAtCanonical: String
    var caseID: String
    var title: String
    var kindRawValue: String
    var createdAtCanonical: String
    var items: [EvidenceVerificationBundleItem]
    var seals: [EvidenceVerificationBundleSeal]
}

struct EvidenceVerificationBundleItem: Codable, Sendable {
    var id: String
    var kindRawValue: String
    var recordedAtCanonical: String
    var source: String
    var note: String
    var contentHash: String
    var mediaOriginalName: String?
    var mediaUTType: String?
    var mediaHash: String?
    var mediaDataBase64: String?
    var recognizedText: String?
    var recognizedTextAtCanonical: String?
    var recognizedTextEngine: String?
    var recognizedTextPageCount: Int?
}

struct EvidenceVerificationBundleSeal: Codable, Sendable {
    var id: String
    var createdAtCanonical: String
    var itemCount: Int
    var manifestHash: String
}

enum EvidenceBundleError: LocalizedError {
    case missingCase
    case emptyCase
    case missingOriginal(String)
    case originalIntegrityMismatch(String)
    case recordIntegrityMismatch(String)
    case generatedBundleInvalid
    case unsupportedFormat
    case unsupportedVersion(Int)
    case unreadableBundle

    var errorDescription: String? {
        switch self {
        case .missingCase:
            L10n.string("bundle.error_missing_case")
        case .emptyCase:
            L10n.string("bundle.error_empty_case")
        case .missingOriginal(let name):
            L10n.format("bundle.error_missing_original", name)
        case .originalIntegrityMismatch(let name):
            L10n.format("bundle.error_original_integrity", name)
        case .recordIntegrityMismatch(let name):
            L10n.format("bundle.error_record_integrity", name)
        case .generatedBundleInvalid:
            L10n.string("bundle.error_generated_invalid")
        case .unsupportedFormat:
            L10n.string("bundle.error_format")
        case .unsupportedVersion(let version):
            L10n.format("bundle.error_version", version)
        case .unreadableBundle:
            L10n.string("bundle.error_unreadable")
        }
    }
}

enum EvidenceBundleCodec {
    static func encode(_ document: EvidenceVerificationBundleDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }

    static func decode(_ data: Data) throws -> EvidenceVerificationBundleDocument {
        do {
            return try JSONDecoder().decode(EvidenceVerificationBundleDocument.self, from: data)
        } catch {
            throw EvidenceBundleError.unreadableBundle
        }
    }
}

enum EvidenceBundleVerifier {
    static func verify(data: Data) throws -> EvidenceBundleVerificationResult {
        let document = try EvidenceBundleCodec.decode(data)
        guard document.format == EvidenceVerificationBundleDocument.formatIdentifier else {
            throw EvidenceBundleError.unsupportedFormat
        }
        guard document.version == EvidenceVerificationBundleDocument.currentVersion else {
            throw EvidenceBundleError.unsupportedVersion(document.version)
        }

        var issues: [String] = []
        if UUID(uuidString: document.caseID) == nil {
            issues.append(L10n.string("bundle.issue_case_id"))
        }
        if EvidenceCaseKind(rawValue: document.kindRawValue) == nil {
            issues.append(L10n.string("bundle.issue_case_type"))
        }

        let sortedIDs = document.items.sorted {
            canonicalSeconds($0.recordedAtCanonical) < canonicalSeconds($1.recordedAtCanonical)
        }.map(\.id)
        if sortedIDs != document.items.map(\.id) {
            issues.append(L10n.string("bundle.issue_order"))
        }

        for item in document.items {
            if UUID(uuidString: item.id) == nil {
                issues.append(L10n.format("bundle.issue_item_id", item.id))
            }
            if EvidenceItemKind(rawValue: item.kindRawValue) == nil {
                issues.append(L10n.format("bundle.issue_item_type", item.id))
            }

            let expectedRecordHash = rawItemHash(
                kindRawValue: item.kindRawValue,
                source: item.source,
                note: item.note,
                recordedAtCanonical: item.recordedAtCanonical,
                mediaHash: item.mediaHash
            )
            if expectedRecordHash != item.contentHash {
                issues.append(L10n.format("bundle.issue_record_hash", item.mediaOriginalName ?? item.id))
            }

            if let expectedMediaHash = item.mediaHash {
                guard let base64 = item.mediaDataBase64,
                      let bytes = Data(base64Encoded: base64) else {
                    issues.append(L10n.format("bundle.issue_media_missing", item.mediaOriginalName ?? item.id))
                    continue
                }
                if EvidenceHasher.sha256(bytes) != expectedMediaHash {
                    issues.append(L10n.format("bundle.issue_media_hash", item.mediaOriginalName ?? item.id))
                }
            } else if item.mediaDataBase64 != nil {
                issues.append(L10n.format("bundle.issue_unhashed_media", item.id))
            }
        }

        let currentManifest = canonicalManifest(document: document, items: document.items)
        let currentManifestHash = EvidenceHasher.sha256(currentManifest)
        var verifiedSealCount = 0

        for seal in document.seals {
            guard seal.itemCount >= 0, seal.itemCount <= document.items.count else {
                issues.append(L10n.format("bundle.issue_seal_count", seal.id))
                continue
            }
            let snapshotItems = Array(document.items.prefix(seal.itemCount))
            let expectedSeal = EvidenceHasher.sha256(
                canonicalManifest(document: document, items: snapshotItems)
            )
            if expectedSeal == seal.manifestHash {
                verifiedSealCount += 1
            } else {
                issues.append(L10n.format("bundle.issue_seal_hash", seal.id))
            }
        }

        return EvidenceBundleVerificationResult(
            isValid: issues.isEmpty,
            caseTitle: document.title,
            caseID: document.caseID,
            itemCount: document.items.count,
            sealCount: document.seals.count,
            verifiedSealCount: verifiedSealCount,
            currentManifestHash: currentManifestHash,
            bundleHash: EvidenceHasher.sha256(data),
            issues: issues
        )
    }

    private static func canonicalSeconds(_ value: String) -> Double {
        Double(value) ?? -.greatestFiniteMagnitude
    }

    private static func rawItemHash(
        kindRawValue: String,
        source: String,
        note: String,
        recordedAtCanonical: String,
        mediaHash: String?
    ) -> String {
        let canonical = [
            "kind=\(kindRawValue)",
            "recordedAt=\(recordedAtCanonical)",
            "source=\(source)",
            "note=\(note)",
            "mediaHash=\(mediaHash ?? "none")"
        ].joined(separator: "\n")
        return EvidenceHasher.sha256(canonical)
    }

    private static func canonicalManifest(
        document: EvidenceVerificationBundleDocument,
        items: [EvidenceVerificationBundleItem]
    ) -> String {
        var lines = [
            "caseID=\(document.caseID)",
            "title=\(document.title)",
            "kind=\(document.kindRawValue)",
            "createdAt=\(document.createdAtCanonical)"
        ]
        for item in items {
            lines.append(
                "item=\(item.id)|\(item.recordedAtCanonical)|\(item.contentHash)|\(item.mediaHash ?? "none")"
            )
        }
        return lines.joined(separator: "\n")
    }
}

extension EvidenceStore {
    func generateVerificationBundle(caseID: UUID) throws -> EvidenceBundleExportResult {
        guard let evidenceCase = caseForID(caseID) else {
            throw EvidenceBundleError.missingCase
        }
        let sortedItems = evidenceCase.evidence.sorted { $0.recordedAt < $1.recordedAt }
        guard !sortedItems.isEmpty else {
            throw EvidenceBundleError.emptyCase
        }

        var bundleItems: [EvidenceVerificationBundleItem] = []
        bundleItems.reserveCapacity(sortedItems.count)

        for item in sortedItems {
            let expectedRecordHash = EvidenceHasher.itemHash(
                kind: item.kind,
                source: item.source,
                note: item.note,
                recordedAt: item.recordedAt,
                mediaHash: item.mediaHash
            )
            guard expectedRecordHash == item.contentHash else {
                throw EvidenceBundleError.recordIntegrityMismatch(item.mediaOriginalName ?? item.kind.rawValue)
            }

            var mediaBase64: String?
            if let expectedMediaHash = item.mediaHash {
                guard let url = mediaURL(for: item) else {
                    throw EvidenceBundleError.missingOriginal(item.mediaOriginalName ?? item.kind.rawValue)
                }
                let bytes = try Data(contentsOf: url)
                guard EvidenceHasher.sha256(bytes) == expectedMediaHash else {
                    throw EvidenceBundleError.originalIntegrityMismatch(item.mediaOriginalName ?? item.kind.rawValue)
                }
                mediaBase64 = bytes.base64EncodedString()
            }

            bundleItems.append(
                EvidenceVerificationBundleItem(
                    id: item.id.uuidString,
                    kindRawValue: item.kind.rawValue,
                    recordedAtCanonical: String(item.recordedAt.timeIntervalSince1970),
                    source: item.source,
                    note: item.note,
                    contentHash: item.contentHash,
                    mediaOriginalName: item.mediaOriginalName,
                    mediaUTType: item.mediaUTType,
                    mediaHash: item.mediaHash,
                    mediaDataBase64: mediaBase64,
                    recognizedText: item.recognizedText,
                    recognizedTextAtCanonical: item.recognizedTextAt.map { String($0.timeIntervalSince1970) },
                    recognizedTextEngine: item.recognizedTextEngine,
                    recognizedTextPageCount: item.recognizedTextPageCount
                )
            )
        }

        let document = EvidenceVerificationBundleDocument(
            format: EvidenceVerificationBundleDocument.formatIdentifier,
            version: EvidenceVerificationBundleDocument.currentVersion,
            exportedAtCanonical: String(Date().timeIntervalSince1970),
            caseID: evidenceCase.id.uuidString,
            title: evidenceCase.title,
            kindRawValue: evidenceCase.kind.rawValue,
            createdAtCanonical: String(evidenceCase.createdAt.timeIntervalSince1970),
            items: bundleItems,
            seals: evidenceCase.seals.sorted(by: { $0.createdAt < $1.createdAt }).map {
                EvidenceVerificationBundleSeal(
                    id: $0.id.uuidString,
                    createdAtCanonical: String($0.createdAt.timeIntervalSince1970),
                    itemCount: $0.itemCount,
                    manifestHash: $0.manifestHash
                )
            }
        )

        let data = try EvidenceBundleCodec.encode(document)
        let verification = try EvidenceBundleVerifier.verify(data: data)
        guard verification.isValid else {
            throw EvidenceBundleError.generatedBundleInvalid
        }

        let url = EvidenceVerificationBundleIO.outputURL(for: evidenceCase.id)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)

        return EvidenceBundleExportResult(
            url: url,
            bundleHash: verification.bundleHash,
            verification: verification
        )
    }
}

enum EvidenceVerificationBundleIO {
    static func outputURL(for caseID: UUID) -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return appSupport
            .appendingPathComponent("EvidaroExports", isDirectory: true)
            .appendingPathComponent("Kamilunavo-Trace-\(caseID.uuidString.lowercased())-Verification.evpack")
    }
}

#if DEBUG
@MainActor
enum EvidenceBundleSmokeRunner {
    private static let caseID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!

    static func runIfRequested(using store: EvidenceStore) async {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--evidaro-verification-bundle-smoke"),
              arguments.indices.contains(index + 1) else {
            return
        }

        let command = arguments[index + 1]
        do {
            let result: String
            let fileName: String
            switch command {
            case "prepare":
                result = try prepare(using: store)
                fileName = "bundle-prepared.txt"
            case "verify":
                result = try verifyPersisted()
                fileName = "bundle-verified.txt"
            default:
                throw EvidenceBundleSmokeError.unknownCommand(command)
            }
            try writeResult(result, fileName: fileName)
            print("EVIDARO_BUNDLE_SMOKE \(command.uppercased()) SUCCESS: \(result)")
        } catch {
            let message = "\(command) failed: \(error.localizedDescription)"
            try? writeResult(message, fileName: "bundle-failed.txt")
            assertionFailure("EVIDARO_BUNDLE_SMOKE FAILURE: \(message)")
        }
    }

    private static func prepare(using store: EvidenceStore) throws -> String {
        let export = try store.generateVerificationBundle(caseID: caseID)
        guard export.verification.isValid,
              export.verification.itemCount == 1,
              export.verification.verifiedSealCount == 1 else {
            throw EvidenceBundleSmokeError.validBundleRejected
        }

        let originalData = try Data(contentsOf: export.url)
        var tampered = try EvidenceBundleCodec.decode(originalData)
        guard !tampered.items.isEmpty else {
            throw EvidenceBundleSmokeError.missingFixture
        }
        tampered.items[0].note += " TAMPERED"
        let tamperedResult = try EvidenceBundleVerifier.verify(data: EvidenceBundleCodec.encode(tampered))
        guard !tamperedResult.isValid else {
            throw EvidenceBundleSmokeError.tamperAccepted
        }

        var derivedOnly = try EvidenceBundleCodec.decode(originalData)
        derivedOnly.items[0].recognizedText = "DERIVED OCR CHANGED FOR SMOKE"
        let derivedResult = try EvidenceBundleVerifier.verify(data: EvidenceBundleCodec.encode(derivedOnly))
        guard derivedResult.isValid else {
            throw EvidenceBundleSmokeError.derivedOCRAffectedIntegrity
        }

        return "bundle-prepared hash=\(export.bundleHash) manifest=\(export.verification.currentManifestHash) items=1 seals=1 tamperRejected=true derivedOCRIgnored=true"
    }

    private static func verifyPersisted() throws -> String {
        let url = EvidenceVerificationBundleIO.outputURL(for: caseID)
        let data = try Data(contentsOf: url)
        let result = try EvidenceBundleVerifier.verify(data: data)
        guard result.isValid,
              result.itemCount == 1,
              result.verifiedSealCount == 1 else {
            throw EvidenceBundleSmokeError.persistedBundleInvalid
        }
        return "bundle-verified hash=\(result.bundleHash) manifest=\(result.currentManifestHash) items=1 seals=1"
    }

    private static func writeResult(_ result: String, fileName: String) throws {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let directory = appSupport.appendingPathComponent("EvidaroSmoke", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data((result + "\n").utf8).write(
            to: directory.appendingPathComponent(fileName),
            options: .atomic
        )
    }
}

private enum EvidenceBundleSmokeError: LocalizedError {
    case unknownCommand(String)
    case missingFixture
    case validBundleRejected
    case tamperAccepted
    case derivedOCRAffectedIntegrity
    case persistedBundleInvalid

    var errorDescription: String? {
        switch self {
        case .unknownCommand(let command):
            "Unknown verification-bundle smoke command: \(command)"
        case .missingFixture:
            "The verification-bundle smoke fixture is missing."
        case .validBundleRejected:
            "A freshly exported verification bundle did not verify."
        case .tamperAccepted:
            "The verification bundle accepted a modified evidence note."
        case .derivedOCRAffectedIntegrity:
            "Changing derived OCR incorrectly invalidated original evidence integrity."
        case .persistedBundleInvalid:
            "The verification bundle did not remain valid after process relaunch."
        }
    }
}
#endif
