import AVFoundation
import Foundation
import LocalAuthentication
import Observation
import PDFKit
import Speech
import StoreKit
import Supabase
import UIKit
import UserNotifications
@preconcurrency import Vision

@MainActor
extension DemoStore {
    func applyExternalSnapshot(_ snapshot: FamilySnapshot) {
        household = snapshot.household
        members = snapshot.members
        planItems = snapshot.planItems
        inboxItems = snapshot.inboxItems
        reminders = snapshot.reminders
        activity = snapshot.activity
        entitlement = snapshot.entitlement
        notificationPreferences = snapshot.notificationPreferences
        if let selectedSourceID {
            proposals = snapshot.proposals.filter { $0.sourceID == selectedSourceID }
        } else {
            proposals = snapshot.proposals
        }
    }

    func refreshHosted() async {
        do {
            applyExternalSnapshot(try await SupabaseFamilyRepository().completeSnapshot())
            repositoryErrorMessage = nil
        } catch {
            repositoryErrorMessage = error.localizedDescription
        }
    }

    func openReviewV1(sourceID: UUID) {
        isRepositoryBusy = true
        repositoryErrorMessage = nil
        Task {
            do {
                let snapshot = try await SupabaseFamilyRepository().completeSnapshot()
                applyExternalSnapshot(snapshot)
                selectedSourceID = sourceID
                proposals = snapshot.proposals.filter { $0.sourceID == sourceID }
                isImportReviewPresented = true
            } catch {
                repositoryErrorMessage = error.localizedDescription
            }
            isRepositoryBusy = false
        }
    }

    func ingestSourceV1(_ request: SourceIngestionRequest) {
        isRepositoryBusy = true
        repositoryErrorMessage = nil
        let existing = Set(inboxItems.map(\.id))
        Task {
            do {
                let snapshot = try await SupabaseFamilyRepository().ingestSource(request)
                applyExternalSnapshot(snapshot)
                if let source = snapshot.inboxItems
                    .filter({ !existing.contains($0.id) })
                    .sorted(by: { $0.createdAt > $1.createdAt })
                    .first,
                   source.status == .review || source.status == .partial {
                    selectedSourceID = source.id
                    proposals = snapshot.proposals.filter { $0.sourceID == source.id }
                    isImportReviewPresented = true
                }
            } catch {
                repositoryErrorMessage = error.localizedDescription
            }
            isRepositoryBusy = false
        }
    }

    func createPlanItemV1(_ draft: PlanItemDraft) {
        isRepositoryBusy = true
        Task {
            do { applyExternalSnapshot(try await SupabaseFamilyRepository().createPlanItem(draft)) }
            catch { repositoryErrorMessage = error.localizedDescription }
            isRepositoryBusy = false
        }
    }

    func updatePlanItemV1(_ item: PlanItem, draft: PlanItemDraft) {
        isRepositoryBusy = true
        Task {
            do { applyExternalSnapshot(try await SupabaseFamilyRepository().updatePlanItem(item.id, expectedVersion: item.version, draft: draft)) }
            catch { repositoryErrorMessage = error.localizedDescription }
            isRepositoryBusy = false
        }
    }

    func deletePlanItemV1(_ itemID: UUID) {
        isRepositoryBusy = true
        Task {
            do { applyExternalSnapshot(try await SupabaseFamilyRepository().deletePlanItem(itemID)) }
            catch { repositoryErrorMessage = error.localizedDescription }
            isRepositoryBusy = false
        }
    }

    func updateMemberV1(_ member: FamilyMember) {
        isRepositoryBusy = true
        Task {
            do { applyExternalSnapshot(try await SupabaseFamilyRepository().updateMember(member)) }
            catch { repositoryErrorMessage = error.localizedDescription }
            isRepositoryBusy = false
        }
    }

    func createInviteV1(role: MemberRole) async throws -> HouseholdInvite {
        try await SupabaseFamilyRepository().createInvite(role: role)
    }

    func archiveSourceV1(_ sourceID: UUID, archived: Bool) {
        isRepositoryBusy = true
        Task {
            do { applyExternalSnapshot(try await SupabaseFamilyRepository().archiveSource(sourceID, archived: archived)) }
            catch { repositoryErrorMessage = error.localizedDescription }
            isRepositoryBusy = false
        }
    }

    func retrySourceV1(_ sourceID: UUID, extractedText: String? = nil) {
        isRepositoryBusy = true
        Task {
            do { applyExternalSnapshot(try await SupabaseFamilyRepository().retrySource(sourceID, extractedText: extractedText)) }
            catch { repositoryErrorMessage = error.localizedDescription }
            isRepositoryBusy = false
        }
    }
}

actor FamilySnapshotCache {
    private let url: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("FamilyLifeOS", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        url = base.appendingPathComponent("snapshot-v1.json")
    }

    func load() -> FamilySnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.family.decode(FamilySnapshot.self, from: data)
    }

    func save(_ snapshot: FamilySnapshot) {
        guard let data = try? JSONEncoder.family.encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func clear() { try? FileManager.default.removeItem(at: url) }
}

extension JSONEncoder {
    fileprivate static var family: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    fileprivate static var family: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

enum FamilyOCRService {
    static func extractText(from data: Data, contentType: String) async throws -> String {
        if contentType == "application/pdf" {
            guard let document = PDFDocument(data: data) else { throw FamilyRepositoryError.invalidSource }
            var text = ""
            for index in 0..<document.pageCount {
                guard let page = document.page(at: index) else { continue }
                if let pageText = page.string, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    text += pageText + "\n"
                } else if let image = page.thumbnail(of: CGSize(width: 1800, height: 2400), for: .mediaBox).cgImage {
                    text += (try await recognize(image)) + "\n"
                }
            }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let image = UIImage(data: data)?.cgImage else { throw FamilyRepositoryError.invalidSource }
        return try await recognize(image)
    }

    private static func recognize(_ image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error { continuation.resume(throwing: error); return }
                let lines = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["de-DE", "en-US", "pl-PL"]
            DispatchQueue.global(qos: .userInitiated).async {
                do { try VNImageRequestHandler(cgImage: image).perform([request]) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }
}

actor FamilyNotificationService {
    static let shared = FamilyNotificationService()

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    func reschedule(snapshot: FamilySnapshot, preferences: NotificationPreferences) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = snapshot.reminders.map { "family-reminder-\($0.id.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        let memberByID = Dictionary(uniqueKeysWithValues: snapshot.members.map { ($0.id, $0.name) })
        let itemByID = Dictionary(uniqueKeysWithValues: snapshot.planItems.map { ($0.id, $0) })

        for reminder in snapshot.reminders where reminder.deliveryState == "pending" && reminder.triggerAt > .now {
            guard let item = itemByID[reminder.planItemID], shouldSchedule(item, preferences: preferences) else { continue }
            let content = UNMutableNotificationContent()
            content.title = item.kind.displayName
            content.body = memberByID[reminder.targetMemberID].map { "\(item.title) · \($0)" } ?? item.title
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.triggerAt),
                repeats: false
            )
            let request = UNNotificationRequest(identifier: "family-reminder-\(reminder.id.uuidString)", content: content, trigger: trigger)
            try? await center.add(request)
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
    static let monthlyID = "de.kamilunavo.family.familypro.monthly"
    static let annualID = "de.kamilunavo.family.familypro.annual"

    var products: [Product] = []
    var isPro = false
    var isBusy = false
    var errorMessage: String?

    func refresh() async {
        isBusy = true
        defer { isBusy = false }
        do {
            products = try await Product.products(for: [Self.monthlyID, Self.annualID])
            isPro = false
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result,
                   [Self.monthlyID, Self.annualID].contains(transaction.productID),
                   transaction.revocationDate == nil {
                    isPro = true
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func purchase(_ product: Product) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                await transaction.finish()
                await refresh()
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refresh()
        } catch { errorMessage = error.localizedDescription }
    }
}

@MainActor
@Observable
final class FamilyAppLock {
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "family.appLock.enabled") }
    }
    var isUnlocked = true
    var errorMessage: String?

    init() { isEnabled = UserDefaults.standard.bool(forKey: "family.appLock.enabled") }

    func lock() {
        if isEnabled { isUnlocked = false }
    }

    func unlock() async {
        guard isEnabled else { isUnlocked = true; return }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Biometrische Entsperrung ist nicht verfügbar."
            return
        }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Familieninformationen entsperren")
            isUnlocked = success
        } catch { errorMessage = error.localizedDescription }
    }
}

@MainActor
@Observable
final class VoiceCaptureModel: NSObject, AVAudioRecorderDelegate {
    var isRecording = false
    var transcript = ""
    var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var audioURL: URL?

    func start() async {
        do {
            let speech: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            guard speech == .authorized else { throw VoiceError.permission }

            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
            guard granted else { throw VoiceError.permission }

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("family-voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .spokenAudio)
            try session.setActive(true)
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            audioURL = url
            isRecording = true
        } catch { errorMessage = error.localizedDescription }
    }

    func stopAndTranscribe() async -> (Data, String)? {
        recorder?.stop()
        isRecording = false
        guard let audioURL, let data = try? Data(contentsOf: audioURL) else { return nil }
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        do {
            let text: String = try await withCheckedThrowingContinuation { continuation in
                var task: SFSpeechRecognitionTask?
                task = recognizer?.recognitionTask(with: request) { result, error in
                    if let error { task?.cancel(); continuation.resume(throwing: error); return }
                    if let result, result.isFinal {
                        task?.cancel()
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                }
                if task == nil { continuation.resume(throwing: VoiceError.recognition) }
            }
            transcript = text
            return (data, text)
        } catch {
            errorMessage = error.localizedDescription
            return (data, "")
        }
    }

    enum VoiceError: LocalizedError {
        case permission, recognition
        var errorDescription: String? {
            switch self {
            case .permission: "Mikrofon- und Spracherkennungszugriff werden benötigt."
            case .recognition: "Die Sprachaufnahme konnte nicht transkribiert werden."
            }
        }
    }
}
