import AVFAudio
import Foundation
import Observation
import StoreKit
import Supabase
import UIKit
import UserNotifications

struct SupabaseEnvironment {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://qmvejpuzejdvtmzpjsme.supabase.co")!,
        supabaseKey: "sb_publishable_jFDlBIFbVRhhpwfWIPhnzA_G36NlJWg"
    )
}

actor FamilyNotificationService {
    static let shared = FamilyNotificationService()

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func schedule(planItems: [PlanItem], preferences: NotificationPreferences) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for item in planItems where shouldSchedule(item, preferences: preferences) {
            guard let start = item.startsAt else { continue }

            var dates: [Date] = []
            if preferences.eventReminders || preferences.taskReminders {
                dates.append(start.addingTimeInterval(-3600))
            }
            if preferences.preparationReminders,
               item.kind == .event || item.kind == .preparation {
                dates.append(start.addingTimeInterval(-86400))
            }

            for (index, date) in dates.enumerated() where date > .now {
                let content = UNMutableNotificationContent()
                content.title = item.title
                content.body = item.kind == .preparation ? "Vorbereitung steht an." : "Ein Familientermin oder eine Aufgabe steht an."
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: "family-\(item.id.uuidString)-\(index)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    private func shouldSchedule(_ item: PlanItem, preferences: NotificationPreferences) -> Bool {
        switch item.kind {
        case .event: preferences.eventReminders
        case .preparation: preferences.preparationReminders
        case .task, .deadline, .payment: preferences.taskReminders
        }
    }
}

@MainActor
@Observable
final class FamilyProStore {
    var products: [Product] = []
    var isPro = false
    var isBusy = false
    var errorMessage: String?
    var statusMessage: String?

    // Swift 6 treats deinit as nonisolated. This handle is only assigned during
    // initialization and read during teardown, so keeping the handle itself
    // nonisolated avoids crossing MainActor isolation while still cancelling
    // the long-lived StoreKit updates task when the store is released.
    private nonisolated(unsafe) var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = Task { [weak self] in
            for await verification in Transaction.updates {
                guard !Task.isCancelled else { return }
                await self?.consume(transaction: verification, finish: true)
            }
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func refresh() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            products = try await Product.products(for: FamilyProPolicy.productIDs)
                .sorted { FamilyProPolicy.productRank($0.id) < FamilyProPolicy.productRank($1.id) }
            isPro = await hasCurrentEntitlement()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        guard FamilyProPolicy.productIDs.contains(product.id) else {
            errorMessage = "Dieses Produkt gehört nicht zu Family Pro."
            return
        }

        isBusy = true
        errorMessage = nil
        statusMessage = nil
        defer { isBusy = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                await consume(transaction: verification, finish: true)
                if isPro { statusMessage = "Family Pro ist aktiv." }
            case .pending:
                statusMessage = "Der Kauf wartet auf Freigabe durch Apple."
            case .userCancelled:
                break
            @unknown default:
                statusMessage = "Der Kaufstatus konnte noch nicht abgeschlossen werden."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        isBusy = true
        errorMessage = nil
        statusMessage = nil
        defer { isBusy = false }

        do {
            try await AppStore.sync()
            isPro = await hasCurrentEntitlement()
            statusMessage = isPro
                ? "Family Pro wurde wiederhergestellt."
                : "Für diesen Apple-Account wurde kein aktives Family-Pro-Abo gefunden."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func consume(transaction verification: VerificationResult<Transaction>, finish: Bool) async {
        switch verification {
        case .verified(let transaction):
            guard FamilyProPolicy.productIDs.contains(transaction.productID) else { return }
            if finish { await transaction.finish() }
            isPro = await hasCurrentEntitlement()
        case .unverified:
            errorMessage = "Die StoreKit-Transaktion konnte nicht verifiziert werden."
            isPro = await hasCurrentEntitlement()
        }
    }

    private func hasCurrentEntitlement(now: Date = .now) async -> Bool {
        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else { continue }
            if FamilyProPolicy.isEntitled(
                productID: transaction.productID,
                revocationDate: transaction.revocationDate,
                expirationDate: transaction.expirationDate,
                now: now
            ) {
                return true
            }
        }
        return false
    }
}

@MainActor
@Observable
final class VoiceCaptureModel: NSObject, AVAudioRecorderDelegate {
    var isRecording = false
    var level: Float = 0
    var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var continuation: CheckedContinuation<URL, Error>?

    func record() async throws -> URL {
        if AVAudioApplication.shared.recordPermission != .granted {
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed) }
            }
            guard granted else { throw VoiceError.permission }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("family-voice-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.record()
        isRecording = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recorder?.updateMeters()
            self.level = self.recorder?.averagePower(forChannel: 0) ?? -160
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func stop() {
        recorder?.stop()
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        timer?.invalidate()
        timer = nil
        isRecording = false
        let result = continuation
        continuation = nil
        if flag {
            result?.resume(returning: recorder.url)
        } else {
            result?.resume(throwing: VoiceError.recordingFailed)
        }
    }

    enum VoiceError: LocalizedError {
        case permission
        case recordingFailed

        var errorDescription: String? {
            switch self {
            case .permission: "Mikrofonzugriff wurde nicht erlaubt."
            case .recordingFailed: "Die Sprachaufnahme konnte nicht gespeichert werden."
            }
        }
    }
}
