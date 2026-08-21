import Foundation
import Supabase

struct FamilySnapshot: Codable, Sendable {
    var household: HouseholdSummary? = nil
    var members: [FamilyMember]
    var planItems: [PlanItem]
    var inboxItems: [InboxSource]
    var proposals: [ActionProposal]
    var reminders: [ReminderSnapshot] = []
    var activity: [ActivityEntry] = []
    var entitlement: FamilyEntitlement = .free
    var notificationPreferences: NotificationPreferences = .init()
}

struct TextIngestionRequest: Sendable {
    let title: String
    let text: String
    let createdByMemberID: UUID
}

enum FamilyRepositoryError: LocalizedError, Sendable {
    case memberNotFound
    case sourceNotFound
    case proposalsNotReady
    case invalidProposalSource
    case unauthenticated
    case householdUnavailable
    case invalidResponse
    case unsupportedFeature
    case invalidSource
    case conflict

    var errorDescription: String? {
        switch self {
        case .memberNotFound: "Das Familienmitglied wurde nicht gefunden."
        case .sourceNotFound: "Die Importquelle wurde nicht gefunden."
        case .proposalsNotReady: "Mindestens ein ausgewählter Vorschlag muss noch geprüft werden."
        case .invalidProposalSource: "Ein Vorschlag gehört nicht zu dieser Importquelle."
        case .unauthenticated: "Bitte zuerst anmelden."
        case .householdUnavailable: "Der Haushalt konnte nicht geladen werden."
        case .invalidResponse: "Die Serverantwort konnte nicht verarbeitet werden."
        case .unsupportedFeature: "Diese Funktion ist in diesem Datenmodus nicht verfügbar."
        case .invalidSource: "Die ausgewählte Quelle konnte nicht verarbeitet werden."
        case .conflict: "Der Eintrag wurde zwischenzeitlich auf einem anderen Gerät geändert. Bitte neu laden und erneut versuchen."
        }
    }
}

protocol FamilyRepository: Sendable {
    func currentSnapshot() async throws -> FamilySnapshot
    func ingestText(_ request: TextIngestionRequest) async throws -> FamilySnapshot
    func ingestSource(_ request: SourceIngestionRequest) async throws -> FamilySnapshot
    func confirmReviewedProposals(sourceID: UUID, proposals: [ActionProposal]) async throws -> FamilySnapshot
    func setPlanItemCompleted(_ itemID: UUID, isCompleted: Bool) async throws -> FamilySnapshot
    func createPlanItem(_ draft: PlanItemDraft) async throws -> FamilySnapshot
    func updatePlanItem(_ itemID: UUID, expectedVersion: Int, draft: PlanItemDraft) async throws -> FamilySnapshot
    func deletePlanItem(_ itemID: UUID) async throws -> FamilySnapshot
    func addChild(named name: String) async throws -> FamilySnapshot
    func updateMember(_ member: FamilyMember) async throws -> FamilySnapshot
    func createInvite(role: MemberRole) async throws -> HouseholdInvite
    func acceptInvite(token: String, displayName: String) async throws -> FamilySnapshot
    func archiveSource(_ sourceID: UUID, archived: Bool) async throws -> FamilySnapshot
    func retrySource(_ sourceID: UUID, extractedText: String?) async throws -> FamilySnapshot
    func sourceDocument(_ sourceID: UUID) async throws -> SourceDocumentData?
    func loadNotificationPreferences() async throws -> NotificationPreferences
    func saveNotificationPreferences(_ preferences: NotificationPreferences) async throws
    func deleteHousehold() async throws
}

extension FamilyRepository {
    func ingestSource(_ request: SourceIngestionRequest) async throws -> FamilySnapshot {
        if request.kind == .text, let text = request.text {
            let snapshot = try await currentSnapshot()
            guard let actor = snapshot.members.first(where: { $0.role == .owner || $0.role == .adult }) else {
                throw FamilyRepositoryError.memberNotFound
            }
            return try await ingestText(.init(title: request.title, text: text, createdByMemberID: actor.id))
        }
        throw FamilyRepositoryError.unsupportedFeature
    }

    func createPlanItem(_ draft: PlanItemDraft) async throws -> FamilySnapshot { throw FamilyRepositoryError.unsupportedFeature }
    func updatePlanItem(_ itemID: UUID, expectedVersion: Int, draft: PlanItemDraft) async throws -> FamilySnapshot { throw FamilyRepositoryError.unsupportedFeature }
    func deletePlanItem(_ itemID: UUID) async throws -> FamilySnapshot { throw FamilyRepositoryError.unsupportedFeature }
    func updateMember(_ member: FamilyMember) async throws -> FamilySnapshot { throw FamilyRepositoryError.unsupportedFeature }
    func createInvite(role: MemberRole) async throws -> HouseholdInvite { throw FamilyRepositoryError.unsupportedFeature }
    func acceptInvite(token: String, displayName: String) async throws -> FamilySnapshot { throw FamilyRepositoryError.unsupportedFeature }
    func archiveSource(_ sourceID: UUID, archived: Bool) async throws -> FamilySnapshot { throw FamilyRepositoryError.unsupportedFeature }
    func retrySource(_ sourceID: UUID, extractedText: String?) async throws -> FamilySnapshot { throw FamilyRepositoryError.unsupportedFeature }
    func sourceDocument(_ sourceID: UUID) async throws -> SourceDocumentData? { nil }
    func loadNotificationPreferences() async throws -> NotificationPreferences { .init() }
    func saveNotificationPreferences(_ preferences: NotificationPreferences) async throws {}
    func deleteHousehold() async throws { throw FamilyRepositoryError.unsupportedFeature }
}

protocol TextExtractionService: Sendable {
    func extractProposals(sourceID: UUID, text: String, members: [FamilyMember]) async throws -> [ActionProposal]
}

// MARK: - Durable offline source intake

struct OfflineSourceRecord: Identifiable, Codable, Sendable {
    let id: UUID
    let createdAt: Date
    let ownerUserID: UUID
    let householdID: UUID
    var kind: SourceKind
    var title: String
    var text: String?
    var fileName: String?
    var contentType: String?
    var extractedText: String?
    var payloadFileName: String?
    var sizeBytes: Int?
    var lastError: String?
    var attempts: Int

    var inboxSource: InboxSource {
        InboxSource(
            id: id,
            title: title,
            kind: kind,
            createdAt: createdAt,
            status: .queued,
            proposalCount: 0,
            sourceText: text ?? extractedText,
            errorMessage: lastError.map { "Lokal gespeichert · \($0)" } ?? "Lokal gespeichert. Wird synchronisiert.",
            storagePath: nil,
            contentType: contentType,
            fileName: fileName,
            sizeBytes: sizeBytes,
            isArchived: false,
            clientRequestID: id,
            isLocalOnly: true
        )
    }
}

actor FamilyOfflineSourceQueue {
    static let shared = FamilyOfflineSourceQueue()

    private let rootURL: URL
    private var syncInFlight = false

    init(rootURL: URL? = nil) {
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.rootURL = applicationSupport
                .appendingPathComponent("FamilyLifeOS", isDirectory: true)
                .appendingPathComponent("OfflineSources", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.rootURL, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableRoot = self.rootURL
        try? mutableRoot.setResourceValues(values)
    }

    func enqueue(
        _ request: SourceIngestionRequest,
        ownerUserID: UUID,
        householdID: UUID
    ) throws -> OfflineSourceRecord {
        let id = request.clientRequestID ?? UUID()
        let directory = directoryURL(for: id)
        let metadata = metadataURL(for: id)

        if let existing = loadRecord(at: metadata) {
            guard existing.ownerUserID == ownerUserID, existing.householdID == householdID else {
                throw FamilyRepositoryError.invalidSource
            }
            return existing
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var payloadName: String?

        do {
            if let data = request.fileData {
                payloadName = "payload.bin"
                try data.write(
                    to: directory.appendingPathComponent("payload.bin"),
                    options: [.atomic, .completeFileProtection]
                )
            }

            let record = OfflineSourceRecord(
                id: id,
                createdAt: .now,
                ownerUserID: ownerUserID,
                householdID: householdID,
                kind: request.kind,
                title: request.title,
                text: request.text,
                fileName: request.fileName,
                contentType: request.contentType,
                extractedText: request.extractedText,
                payloadFileName: payloadName,
                sizeBytes: request.fileData?.count,
                lastError: nil,
                attempts: 0
            )
            try write(record)
            return record
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func records(ownerUserID: UUID, householdID: UUID) -> [OfflineSourceRecord] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        return urls
            .compactMap { loadRecord(at: $0.appendingPathComponent("metadata.json")) }
            .filter { $0.ownerUserID == ownerUserID && $0.householdID == householdID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func request(for record: OfflineSourceRecord) throws -> SourceIngestionRequest {
        let payload: Data?
        if let payloadFileName = record.payloadFileName {
            payload = try Data(contentsOf: directoryURL(for: record.id).appendingPathComponent(payloadFileName))
        } else {
            payload = nil
        }

        return SourceIngestionRequest(
            kind: record.kind,
            title: record.title,
            text: record.text,
            fileData: payload,
            fileName: record.fileName,
            contentType: record.contentType,
            extractedText: record.extractedText,
            clientRequestID: record.id,
            targetHouseholdID: record.householdID
        )
    }

    func markAttemptFailed(_ id: UUID, message: String) {
        guard var record = loadRecord(at: metadataURL(for: id)) else { return }
        record.attempts += 1
        record.lastError = String(message.prefix(240))
        try? write(record)
    }

    func clearFailure(_ id: UUID) {
        guard var record = loadRecord(at: metadataURL(for: id)) else { return }
        record.lastError = nil
        try? write(record)
    }

    func remove(_ id: UUID) {
        try? FileManager.default.removeItem(at: directoryURL(for: id))
    }

    func beginSync() -> Bool {
        guard !syncInFlight else { return false }
        syncInFlight = true
        return true
    }

    func endSync() {
        syncInFlight = false
    }

    private func directoryURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent(id.uuidString.lowercased(), isDirectory: true)
    }

    private func metadataURL(for id: UUID) -> URL {
        directoryURL(for: id).appendingPathComponent("metadata.json")
    }

    private func loadRecord(at url: URL) -> OfflineSourceRecord? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(OfflineSourceRecord.self, from: data)
    }

    private func write(_ record: OfflineSourceRecord) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        try data.write(to: metadataURL(for: record.id), options: [.atomic, .completeFileProtection])
    }
}

struct QueuedSourceIngestionResult: Sendable {
    let snapshot: FamilySnapshot
    let sourceID: UUID
}

extension SupabaseFamilyRepository {
    func ingestQueuedSource(_ request: SourceIngestionRequest) async throws -> QueuedSourceIngestionResult {
        guard let clientRequestID = request.clientRequestID,
              let targetHouseholdID = request.targetHouseholdID else {
            let snapshot = try await ingestSource(request)
            guard let source = snapshot.inboxItems.first else { throw FamilyRepositoryError.invalidResponse }
            return QueuedSourceIngestionResult(snapshot: snapshot, sourceID: source.id)
        }

        let client = SupabaseEnvironment.client
        let rows: [OfflineCreatedSourceRow] = try await client
            .rpc(
                "create_source_item",
                params: OfflineCreateSourceParams(
                    sourceType: request.kind.rawValue,
                    title: request.title,
                    originalText: request.text,
                    clientRequestID: clientRequestID,
                    householdID: targetHouseholdID
                )
            )
            .execute()
            .value

        guard let source = rows.first,
              source.householdID == targetHouseholdID else {
            throw FamilyRepositoryError.invalidResponse
        }

        let states: [OfflineSourceStateRow] = try await client
            .from("source_items")
            .select("storage_path,processing_status")
            .eq("id", value: source.sourceItemID)
            .execute()
            .value
        guard var state = states.first else { throw FamilyRepositoryError.invalidResponse }

        if let data = request.fileData, state.storagePath == nil {
            let fileName = OfflineSourceSanitizer.fileName(request.fileName ?? "Quelle")
            let path = "households/\(source.householdID.uuidString.lowercased())/sources/\(source.sourceItemID.uuidString.lowercased())/\(fileName)"
            let contentType = request.contentType ?? "application/octet-stream"

            try await client.storage
                .from("family-sources")
                .upload(
                    path: path,
                    file: data,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: contentType,
                        upsert: true
                    )
                )

            try await client
                .rpc(
                    "finalize_source_upload",
                    params: OfflineFinalizeUploadParams(
                        sourceItemID: source.sourceItemID,
                        storagePath: path,
                        fileName: fileName,
                        contentType: contentType,
                        sizeBytes: data.count,
                        extractedText: request.extractedText
                    )
                )
                .execute()
            state.storagePath = path
            state.processingStatus = "processing"
        }

        if !["review", "partial", "done"].contains(state.processingStatus) {
            let _: OfflineProcessResult = try await client.functions.invoke(
                "process-family-source",
                options: FunctionInvokeOptions(
                    body: OfflineProcessSourceBody(
                        sourceItemID: source.sourceItemID,
                        textOverride: request.text ?? request.extractedText
                    )
                )
            )
        }

        return QueuedSourceIngestionResult(
            snapshot: try await currentSnapshot(),
            sourceID: source.sourceItemID
        )
    }
}

@MainActor
extension DemoStore {
    func enqueueSourceV1(_ request: SourceIngestionRequest) {
        isRepositoryBusy = true
        repositoryErrorMessage = nil

        Task {
            do {
                guard let householdID = household?.id else {
                    throw FamilyRepositoryError.householdUnavailable
                }
                let ownerUserID = try await SupabaseEnvironment.client.auth.session.user.id
                let record = try await FamilyOfflineSourceQueue.shared.enqueue(
                    request,
                    ownerUserID: ownerUserID,
                    householdID: householdID
                )
                await overlayOfflineSourcesV1()
                await syncOfflineSourcesV1(openReviewFor: record.id)
            } catch {
                repositoryErrorMessage = "Die Quelle konnte nicht lokal gespeichert werden: \(error.localizedDescription)"
            }
            isRepositoryBusy = false
        }
    }

    func restoreAndSyncOfflineSourcesV1() async {
        await overlayOfflineSourcesV1()
        await syncOfflineSourcesV1()
    }

    func retryQueuedSourceV1(_ id: UUID) {
        Task {
            await FamilyOfflineSourceQueue.shared.clearFailure(id)
            await overlayOfflineSourcesV1()
            await syncOfflineSourcesV1(openReviewFor: id)
        }
    }

    func discardQueuedSourceV1(_ id: UUID) {
        Task {
            await FamilyOfflineSourceQueue.shared.remove(id)
            await overlayOfflineSourcesV1()
        }
    }

    func overlayOfflineSourcesV1() async {
        inboxItems.removeAll { $0.isLocalOnly }
        guard let householdID = household?.id,
              let ownerUserID = try? await SupabaseEnvironment.client.auth.session.user.id else {
            return
        }
        let records = await FamilyOfflineSourceQueue.shared.records(
            ownerUserID: ownerUserID,
            householdID: householdID
        )
        inboxItems.append(contentsOf: records.map(\.inboxSource))
        inboxItems.sort { $0.createdAt > $1.createdAt }
    }

    func syncOfflineSourcesV1(openReviewFor localRequestID: UUID? = nil) async {
        guard let householdID = household?.id,
              let ownerUserID = try? await SupabaseEnvironment.client.auth.session.user.id else {
            return
        }
        guard await FamilyOfflineSourceQueue.shared.beginSync() else { return }

        let records = await FamilyOfflineSourceQueue.shared.records(
            ownerUserID: ownerUserID,
            householdID: householdID
        )
        let repository = SupabaseFamilyRepository()

        for record in records {
            do {
                let request = try await FamilyOfflineSourceQueue.shared.request(for: record)
                let result = try await repository.ingestQueuedSource(request)
                await FamilyOfflineSourceQueue.shared.remove(record.id)
                applyExternalSnapshot(result.snapshot)
                await overlayOfflineSourcesV1()

                if localRequestID == record.id,
                   let source = result.snapshot.inboxItems.first(where: { $0.id == result.sourceID }),
                   source.status == .review || source.status == .partial {
                    selectedSourceID = source.id
                    proposals = result.snapshot.proposals.filter { $0.sourceID == source.id }
                    isImportReviewPresented = true
                }
            } catch {
                await FamilyOfflineSourceQueue.shared.markAttemptFailed(record.id, message: error.localizedDescription)
                await overlayOfflineSourcesV1()
                break
            }
        }

        await FamilyOfflineSourceQueue.shared.endSync()
    }
}

private struct OfflineCreateSourceParams: Encodable, Sendable {
    let sourceType: String
    let title: String
    let originalText: String?
    let clientRequestID: UUID
    let householdID: UUID

    enum CodingKeys: String, CodingKey {
        case sourceType = "p_source_type"
        case title = "p_title"
        case originalText = "p_original_text"
        case clientRequestID = "p_client_request_id"
        case householdID = "p_household_id"
    }
}

private struct OfflineCreatedSourceRow: Decodable, Sendable {
    let sourceItemID: UUID
    let householdID: UUID

    enum CodingKeys: String, CodingKey {
        case sourceItemID = "source_item_id"
        case householdID = "household_id"
    }
}

private struct OfflineSourceStateRow: Decodable, Sendable {
    var storagePath: String?
    var processingStatus: String

    enum CodingKeys: String, CodingKey {
        case storagePath = "storage_path"
        case processingStatus = "processing_status"
    }
}

private struct OfflineFinalizeUploadParams: Encodable, Sendable {
    let sourceItemID: UUID
    let storagePath: String
    let fileName: String
    let contentType: String
    let sizeBytes: Int
    let extractedText: String?

    enum CodingKeys: String, CodingKey {
        case sourceItemID = "p_source_item_id"
        case storagePath = "p_storage_path"
        case fileName = "p_file_name"
        case contentType = "p_content_type"
        case sizeBytes = "p_size_bytes"
        case extractedText = "p_extracted_text"
    }
}

private struct OfflineProcessSourceBody: Encodable, Sendable {
    let sourceItemID: UUID
    let textOverride: String?

    enum CodingKeys: String, CodingKey {
        case sourceItemID = "source_item_id"
        case textOverride = "text_override"
    }
}

private struct OfflineProcessResult: Decodable, Sendable {
    let sourceItemID: UUID
    let proposalCount: Int

    enum CodingKeys: String, CodingKey {
        case sourceItemID = "source_item_id"
        case proposalCount = "proposal_count"
    }
}

private enum OfflineSourceSanitizer {
    static func fileName(_ value: String) -> String {
        let clean = value
            .replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-"))
        return String((clean.isEmpty ? "Quelle" : clean).prefix(120))
    }
}
