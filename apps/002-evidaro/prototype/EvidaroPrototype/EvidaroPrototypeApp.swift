import PDFKit
import SwiftUI

@main
struct EvidaroPrototypeApp: App {
    @StateObject private var store: EvidenceStore
    @StateObject private var appLock = AppLockController()

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
            AppLockGateView(store: store, appLock: appLock)
#if DEBUG
                .task {
                    await PersistenceSmokeRunner.runIfRequested(using: store)
                    await AppLockSmokeRunner.runIfRequested()
                }
#endif
        }
    }
}

private struct AppLockGateView: View {
    @ObservedObject var store: EvidenceStore
    @ObservedObject var appLock: AppLockController
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if appLock.needsUnlock {
                EvidaroLockedView(appLock: appLock)
            } else {
                RootView(store: store, appLock: appLock)
            }
        }
        .task {
            await appLock.unlockIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                appLock.lockIfNeeded()
            case .active:
                Task { await appLock.unlockIfNeeded() }
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

private struct EvidaroLockedView: View {
    @ObservedObject var appLock: AppLockController

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 58, weight: .semibold))
                .accessibilityHidden(true)

            VStack(spacing: 7) {
                Text("Evidaro is locked")
                    .font(.title2.bold())
                Text("Authenticate with your device to view locally stored evidence cases.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            if appLock.isAuthenticating {
                ProgressView("Authenticating…")
            } else {
                Button {
                    Task { await appLock.unlockIfNeeded() }
                } label: {
                    Label("Unlock Evidaro", systemImage: "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let error = appLock.lastError, !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
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
        let legalText = L10n.string("pdf.integrity.legal")
        let legalMarker = legalText.components(separatedBy: ".").first ?? legalText
        let requiredTokens = [
            "EVIDARO",
            L10n.string("pdf.heading.evidence_pack"),
            "CI OCR Smoke",
            evidencePackSmokeCaseID.uuidString,
            L10n.string("pdf.field.original_sha"),
            mediaHash,
            L10n.string("pdf.field.record_sha"),
            recordHash,
            L10n.string("pdf.ocr.heading"),
            "EVIDARO 4827",
            L10n.string("pdf.seals.heading"),
            sealHash,
            legalMarker
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
