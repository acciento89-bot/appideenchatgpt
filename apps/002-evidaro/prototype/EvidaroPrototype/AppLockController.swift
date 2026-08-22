import Combine
import Foundation
import LocalAuthentication
import UIKit

protocol AppLockAuthenticating {
    func canAuthenticate() -> Bool
    func authenticate(reason: String) async throws -> Bool
}

struct SystemAppLockAuthenticator: AppLockAuthenticating {
    func canAuthenticate() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = L10n.string("common.cancel")
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}

@MainActor
final class AppLockController: ObservableObject {
    static let preferenceKey = "evidaro.requireDeviceAuthentication"

    @Published private(set) var isEnabled: Bool
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var isAuthenticating = false
    @Published private(set) var isAuthenticationAvailable = false
    @Published var lastError: String?

    private let authenticator: AppLockAuthenticating
    private let defaults: UserDefaults

    init(
        authenticator: AppLockAuthenticating = SystemAppLockAuthenticator(),
        defaults: UserDefaults = .standard
    ) {
        self.authenticator = authenticator
        self.defaults = defaults
        let enabled = defaults.bool(forKey: Self.preferenceKey)
        isEnabled = enabled
        isUnlocked = !enabled
        isAuthenticationAvailable = authenticator.canAuthenticate()
    }

    var needsUnlock: Bool {
        isEnabled && !isUnlocked
    }

    func refreshAvailability() {
        isAuthenticationAvailable = authenticator.canAuthenticate()
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        lastError = nil
        refreshAvailability()

        if !enabled {
            defaults.set(false, forKey: Self.preferenceKey)
            isEnabled = false
            isUnlocked = true
            return true
        }

        guard isAuthenticationAvailable else {
            lastError = L10n.string("privacy_lock.system_unavailable_setup")
            return false
        }

        let authenticated = await authenticate(
            reason: L10n.string("privacy_lock.enable_reason")
        )
        guard authenticated else { return false }

        defaults.set(true, forKey: Self.preferenceKey)
        isEnabled = true
        isUnlocked = true
        return true
    }

    func lockIfNeeded() {
        guard isEnabled else { return }
        isUnlocked = false
        lastError = nil
    }

    @discardableResult
    func unlockIfNeeded() async -> Bool {
        guard needsUnlock else { return true }
        return await authenticate(reason: L10n.string("privacy_lock.unlock_reason"))
    }

    @discardableResult
    func authenticate(reason: String) async -> Bool {
        guard !isAuthenticating else { return false }
        refreshAvailability()
        guard isAuthenticationAvailable else {
            lastError = L10n.string("privacy_lock.system_unavailable")
            return false
        }

        isAuthenticating = true
        lastError = nil
        defer { isAuthenticating = false }

        do {
            let success = try await authenticator.authenticate(reason: reason)
            if success {
                isUnlocked = true
            } else {
                lastError = L10n.string("privacy_lock.system_not_completed")
            }
            return success
        } catch {
            let nsError = error as NSError
            if nsError.domain == LAError.errorDomain,
               nsError.code == LAError.userCancel.rawValue {
                lastError = nil
            } else {
                lastError = error.localizedDescription
            }
            return false
        }
    }
}

#if DEBUG
private struct AlwaysAllowAppLockAuthenticator: AppLockAuthenticating {
    func canAuthenticate() -> Bool { true }
    func authenticate(reason: String) async throws -> Bool { true }
}

@MainActor
enum AppLockSmokeRunner {
    private static let suiteName = "de.kamilunavo.evidaro.applock.smoke"

    static func runIfRequested() async {
        let arguments = CommandLine.arguments

        if arguments.contains("--evidaro-localization-smoke") {
            do {
                let result = try verifyGermanLocalization()
                try writeResult(result, fileName: "localization-verified.txt")
                print("EVIDARO_LOCALIZATION_SMOKE SUCCESS: \(result)")
            } catch {
                let message = "localization failed: \(error.localizedDescription)"
                try? writeResult(message, fileName: "localization-failed.txt")
                assertionFailure("EVIDARO_LOCALIZATION_SMOKE FAILURE: \(message)")
            }
            return
        }

        guard let flagIndex = arguments.firstIndex(of: "--evidaro-app-lock-smoke"),
              arguments.indices.contains(flagIndex + 1) else {
            return
        }

        let command = arguments[flagIndex + 1]
        do {
            let result: String
            let fileName: String
            switch command {
            case "prepare":
                result = try await prepare()
                fileName = "lock-prepared.txt"
            case "verify":
                result = try await verify()
                fileName = "lock-verified.txt"
            default:
                throw AppLockSmokeError.unknownCommand(command)
            }
            try writeResult(result, fileName: fileName)
            print("EVIDARO_APP_LOCK_SMOKE \(command.uppercased()) SUCCESS: \(result)")
        } catch {
            let message = "\(command) failed: \(error.localizedDescription)"
            try? writeResult(message, fileName: "lock-failed.txt")
            assertionFailure("EVIDARO_APP_LOCK_SMOKE FAILURE: \(message)")
        }
    }

    private static func verifyGermanLocalization() throws -> String {
        let cases = L10n.string("home.cases")
        let property = EvidenceCaseKind.property.localizedName
        let bundleVerify = L10n.string("bundle.verify_import")
        let camera = Bundle.main.localizedInfoDictionary?["NSCameraUsageDescription"] as? String
        let faceID = Bundle.main.localizedInfoDictionary?["NSFaceIDUsageDescription"] as? String

        guard cases == "Fälle",
              property == "Immobilie",
              bundleVerify == "Beweispaket prüfen",
              camera == "Nimm Fotos direkt in einen Kamilunavo-Trace-Beweisdatensatz auf.",
              faceID == "Entsperre Kamilunavo Trace, um lokal gespeicherte Beweisfälle anzuzeigen." else {
            throw AppLockSmokeError.localizationMismatch(
                "cases=\(cases) property=\(property) bundle=\(bundleVerify) camera=\(camera ?? "nil") faceID=\(faceID ?? "nil")"
            )
        }

        let iconResult = try verifyCompiledHomeScreenIcon()
        print("TRACE_COMPILED_APPICON SUCCESS: \(iconResult)")

        return "localization-verified language=de cases=Fälle property=Immobilie camera=localized faceID=localized"
    }

    private static func verifyCompiledHomeScreenIcon() throws -> String {
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        guard let enumerator = fileManager.enumerator(
            at: bundleURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw AppLockSmokeError.compiledAppIconMissing
        }

        var pngURLs: [URL] = []
        for case let url as URL in enumerator {
            let name = url.lastPathComponent.lowercased()
            if url.pathExtension.lowercased() == "png", name.contains("appicon") {
                pngURLs.append(url)
            }
        }

        struct Candidate {
            let url: URL
            let image: CGImage
        }

        let candidates: [Candidate] = pngURLs.compactMap { url in
            guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
            return Candidate(url: url, image: image)
        }

        guard let target = candidates.first(where: { $0.image.width == 120 && $0.image.height == 120 }) else {
            let dimensions = candidates
                .map { "\($0.url.lastPathComponent)=\($0.image.width)x\($0.image.height)" }
                .sorted()
                .joined(separator: ",")
            throw AppLockSmokeError.compiledAppIcon120Missing(dimensions)
        }

        let width = target.image.width
        let height = target.image.height
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        let rendered = pixels.withUnsafeMutableBytes { rawBuffer -> Bool in
            guard let baseAddress = rawBuffer.baseAddress,
                  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                return false
            }
            context.interpolationQuality = .none
            context.draw(target.image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else {
            throw AppLockSmokeError.compiledAppIconDecodeFailed
        }

        var luminanceSum = 0.0
        var luminanceSquaredSum = 0.0
        var minimum = 255.0
        var maximum = 0.0
        let pixelCount = width * height

        for index in stride(from: 0, to: pixels.count, by: 4) {
            let red = Double(pixels[index])
            let green = Double(pixels[index + 1])
            let blue = Double(pixels[index + 2])
            let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
            luminanceSum += luminance
            luminanceSquaredSum += luminance * luminance
            minimum = min(minimum, luminance)
            maximum = max(maximum, luminance)
        }

        let mean = luminanceSum / Double(pixelCount)
        let variance = max(0, luminanceSquaredSum / Double(pixelCount) - mean * mean)
        let standardDeviation = sqrt(variance)
        let range = maximum - minimum

        guard mean >= 35, mean <= 220, standardDeviation >= 18, range >= 70 else {
            throw AppLockSmokeError.compiledAppIconLooksBlank(
                String(format: "file=%@ mean=%.2f stddev=%.2f min=%.2f max=%.2f range=%.2f", target.url.lastPathComponent, mean, standardDeviation, minimum, maximum, range)
            )
        }

        return String(
            format: "file=%@ size=%dx%d mean=%.2f stddev=%.2f min=%.2f max=%.2f range=%.2f",
            target.url.lastPathComponent,
            width,
            height,
            mean,
            standardDeviation,
            minimum,
            maximum,
            range
        )
    }

    private static func prepare() async throws -> String {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw AppLockSmokeError.defaultsUnavailable
        }
        defaults.removePersistentDomain(forName: suiteName)
        let controller = AppLockController(
            authenticator: AlwaysAllowAppLockAuthenticator(),
            defaults: defaults
        )
        guard !controller.isEnabled, controller.isUnlocked else {
            throw AppLockSmokeError.invalidInitialState
        }
        guard await controller.setEnabled(true), controller.isEnabled, controller.isUnlocked else {
            throw AppLockSmokeError.enableFailed
        }
        controller.lockIfNeeded()
        guard controller.isEnabled, controller.needsUnlock, !controller.isUnlocked else {
            throw AppLockSmokeError.lockFailed
        }
        defaults.synchronize()
        return "lock-prepared enabled=true locked=true preference=true"
    }

    private static func verify() async throws -> String {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw AppLockSmokeError.defaultsUnavailable
        }
        let controller = AppLockController(
            authenticator: AlwaysAllowAppLockAuthenticator(),
            defaults: defaults
        )
        guard controller.isEnabled, controller.needsUnlock, !controller.isUnlocked else {
            throw AppLockSmokeError.preferenceDidNotPersist
        }
        guard await controller.unlockIfNeeded(), controller.isUnlocked else {
            throw AppLockSmokeError.unlockFailed
        }
        guard await controller.setEnabled(false), !controller.isEnabled, controller.isUnlocked else {
            throw AppLockSmokeError.disableFailed
        }
        defaults.synchronize()
        return "lock-verified persisted=true unlocked=true disabled=true"
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

private enum AppLockSmokeError: LocalizedError {
    case unknownCommand(String)
    case defaultsUnavailable
    case invalidInitialState
    case enableFailed
    case lockFailed
    case preferenceDidNotPersist
    case unlockFailed
    case disableFailed
    case localizationMismatch(String)
    case compiledAppIconMissing
    case compiledAppIcon120Missing(String)
    case compiledAppIconDecodeFailed
    case compiledAppIconLooksBlank(String)

    var errorDescription: String? {
        switch self {
        case .unknownCommand(let command):
            "Unknown app-lock smoke command: \(command)"
        case .defaultsUnavailable:
            "The isolated app-lock UserDefaults suite could not be created."
        case .invalidInitialState:
            "The app-lock smoke controller did not start disabled and unlocked."
        case .enableFailed:
            "The privacy lock could not be enabled with successful device authentication."
        case .lockFailed:
            "The enabled privacy lock did not transition to a locked state."
        case .preferenceDidNotPersist:
            "The enabled privacy-lock preference did not survive process relaunch."
        case .unlockFailed:
            "The persisted privacy lock could not be unlocked after process relaunch."
        case .disableFailed:
            "The privacy lock could not be disabled after verification."
        case .localizationMismatch(let detail):
            "The German localization runtime smoke did not resolve the expected values: \(detail)"
        case .compiledAppIconMissing:
            "The compiled app bundle did not expose any AppIcon PNG candidates."
        case .compiledAppIcon120Missing(let detail):
            "The compiled app bundle did not contain the 120x120 Home Screen AppIcon. Candidates: \(detail)"
        case .compiledAppIconDecodeFailed:
            "The compiled 120x120 Home Screen AppIcon could not be decoded into pixels."
        case .compiledAppIconLooksBlank(let detail):
            "The compiled 120x120 Home Screen AppIcon is visually blank/dark or lacks contrast: \(detail)"
        }
    }
}
#endif