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

private enum SmokeRunnerError: LocalizedError {
    case unknownCommand(String)

    var errorDescription: String? {
        switch self {
        case .unknownCommand(let command):
            "Unknown persistence smoke command: \(command)"
        }
    }
}
#endif
