import PDFKit
import SwiftUI

@main
struct EvidaroPrototypeApp: App {
    @StateObject private var store: EvidenceStore

    init() {
#if DEBUG
        let smokeRequested = CommandLine.arguments.contains("--evidaro-persistence-smoke")
#else
        let smokeRequested = false
#endif
        _store = StateObject(wrappedValue: EvidenceStore(seedDemoData: !smokeRequested))
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
#if DEBUG
                .task {
                    await PersistenceSmokeRunner.runIfRequested(using: store)
                }
#endif
        }
    }
}

#if DEBUG
@MainActor
private enum PersistenceSmokeRunner {
    private static let evidencePackSmokeCaseID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!

    static func runIfRequested(using store: EvidenceStore) async {
        let arguments = CommandLine.arguments
        guard let flagIndex = arguments.firstIndex(of: "--evidaro-persistence-smoke"),
              arguments.indices.contains(flagIndex + 1) else {
            return
        }

        let command = arguments[flagIndex + 1]
        do {
            let result: String
            let fileName: String
            switch command {
            case "prepare":
                result = try store.preparePersistenceSmoke()
                fileName = "prepared.txt"
            case "verify":
                result = try store.verifyPersistenceSmoke()
                fileName = "verified.txt"
            case "ocr-prepare":
                result = try await store.prepareOCRSmoke()
                fileName = "ocr-prepared.txt"
            case "ocr-verify":
                result = try store.verifyOCRSmoke()
                fileName = "ocr-verified.txt"
            case "pack-prepare":
                result = try await prepareEvidencePackSmoke(using: store)
                fileName = "pack-prepared.txt"
            case "pack-verify":
                result = try verifyEvidencePackSmoke(using: store)
                fileName = "pack-verified.txt"
            default:
                throw SmokeRunnerError.unknownCommand(command)
            }
            try writeResult(result, fileName: fileName)
            print("EVIDARO_PERSISTENCE_SMOKE \(command.uppercased()) SUCCESS: \(result)")
        } catch {
            let message = "\(command) failed: \(error.localizedDescription)"
            try? writeResult(message, fileName: "failed.txt")
            assertionFailure("EVIDARO_PERSISTENCE_SMOKE FAILURE: \(message)")
        }
    }

    private static func prepareEvidencePackSmoke(using store: EvidenceStore) async throws -> String {
        let anchors = try evidencePackAnchors(using: store)
        let result = try await store.generateEvidencePack(caseID: evidencePackSmokeCaseID)
        let pages = try validateEvidencePack(
            at: result.url,
            mediaHash: anchors.mediaHash,
            recordHash: anchors.recordHash,
            sealHash: anchors.sealHash
        )
        let refreshed = try evidencePackAnchors(using: store)
        guard refreshed == anchors else {
            throw SmokeRunnerError.evidencePackIntegrityChanged
        }
        return "pack-prepared pages=\(pages) pdfHash=\(result.pdfHash) mediaHash=\(anchors.mediaHash) recordHash=\(anchors.recordHash) seal=\(anchors.sealHash)"
    }

    private static func verifyEvidencePackSmoke(using store: EvidenceStore) throws -> String {
        let anchors = try evidencePackAnchors(using: store)
        let url = evidencePackURL()
        let data = try Data(contentsOf: url)
        let pdfHash = EvidenceHasher.sha256(data)
        let pages = try validateEvidencePack(
            at: url,
            mediaHash: anchors.mediaHash,
            recordHash: anchors.recordHash,
            sealHash: anchors.sealHash
        )
        let refreshed = try evidencePackAnchors(using: store)
        guard refreshed == anchors else {
            throw SmokeRunnerError.evidencePackIntegrityChanged
        }
        return "pack-verified pages=\(pages) pdfHash=\(pdfHash) mediaHash=\(anchors.mediaHash) recordHash=\(anchors.recordHash) seal=\(anchors.sealHash)"
    }

    private static func evidencePackAnchors(using store: EvidenceStore) throws -> EvidencePackSmokeAnchors {
        guard let evidenceCase = store.caseForID(evidencePackSmokeCaseID),
              let item = evidenceCase.evidence.first,
              let mediaHash = item.mediaHash,
              let seal = evidenceCase.seals.first else {
            throw SmokeRunnerError.missingEvidencePackFixture
        }
        return EvidencePackSmokeAnchors(
            mediaHash: mediaHash,
            recordHash: item.contentHash,
            sealHash: seal.manifestHash
        )
    }

    private static func validateEvidencePack(
        at url: URL,
        mediaHash: String,
        recordHash: String,
        sealHash: String
    ) throws -> Int {
        guard let document = PDFDocument(url: url), document.pageCount >= 4 else {
            throw SmokeRunnerError.invalidEvidencePack
        }
        let text = document.string ?? ""
        let requiredTokens = [
            "EVIDARO",
            "EVIDENCE PACK",
            "CI OCR Smoke",
            evidencePackSmokeCaseID.uuidString,
            "Original media SHA-256",
            mediaHash,
            "Evidence record SHA-256",
            recordHash,
            "DERIVED OCR",
            "EVIDARO 4827",
            "SNAPSHOT SEALS",
            sealHash,
            "Integrity aid only"
        ]
        for token in requiredTokens where text.range(of: token, options: .caseInsensitive) == nil {
            throw SmokeRunnerError.missingEvidencePackToken(token)
        }
        return document.pageCount
    }

    private static func evidencePackURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return appSupport
            .appendingPathComponent("EvidaroExports", isDirectory: true)
            .appendingPathComponent("Evidaro-\(evidencePackSmokeCaseID.uuidString.lowercased())-Evidence-Pack.pdf")
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

private struct EvidencePackSmokeAnchors: Equatable {
    let mediaHash: String
    let recordHash: String
    let sealHash: String
}

private enum SmokeRunnerError: LocalizedError {
    case unknownCommand(String)
    case missingEvidencePackFixture
    case invalidEvidencePack
    case missingEvidencePackToken(String)
    case evidencePackIntegrityChanged

    var errorDescription: String? {
        switch self {
        case .unknownCommand(let command):
            "Unknown persistence smoke command: \(command)"
        case .missingEvidencePackFixture:
            "The OCR fixture required for the evidence-pack smoke test is missing."
        case .invalidEvidencePack:
            "The generated evidence pack is not a readable multi-page PDF."
        case .missingEvidencePackToken(let token):
            "The generated evidence pack is missing required text: \(token)"
        case .evidencePackIntegrityChanged:
            "Creating or reopening the evidence pack changed an original media, record or seal hash."
        }
    }
}
#endif
