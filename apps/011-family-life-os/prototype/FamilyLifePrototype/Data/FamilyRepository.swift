import Foundation

struct FamilySnapshot: Sendable {
    var members: [FamilyMember]
    var planItems: [PlanItem]
    var inboxItems: [InboxSource]
    var proposals: [ActionProposal]
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

    var errorDescription: String? {
        switch self {
        case .memberNotFound:
            "Das Familienmitglied wurde nicht gefunden."
        case .sourceNotFound:
            "Die Importquelle wurde nicht gefunden."
        case .proposalsNotReady:
            "Mindestens ein ausgewählter Vorschlag muss noch geprüft werden."
        case .invalidProposalSource:
            "Ein Vorschlag gehört nicht zu dieser Importquelle."
        }
    }
}

protocol FamilyRepository: Sendable {
    func currentSnapshot() async -> FamilySnapshot

    func ingestText(_ request: TextIngestionRequest) async throws -> FamilySnapshot

    func confirmReviewedProposals(
        sourceID: UUID,
        proposals: [ActionProposal]
    ) async throws -> FamilySnapshot

    func setPlanItemCompleted(
        _ itemID: UUID,
        isCompleted: Bool
    ) async throws -> FamilySnapshot
}

protocol TextExtractionService: Sendable {
    func extractProposals(
        sourceID: UUID,
        text: String,
        members: [FamilyMember]
    ) async throws -> [ActionProposal]
}
