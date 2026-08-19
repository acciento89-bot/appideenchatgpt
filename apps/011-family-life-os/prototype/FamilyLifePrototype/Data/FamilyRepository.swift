import Foundation

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
