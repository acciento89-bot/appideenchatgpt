import Foundation

actor InMemoryFamilyRepository: FamilyRepository {
    private var snapshot: FamilySnapshot
    private let extractionService: any TextExtractionService

    init(
        snapshot: FamilySnapshot,
        extractionService: any TextExtractionService = FixtureTextExtractionService()
    ) {
        self.snapshot = snapshot
        self.extractionService = extractionService
    }

    func currentSnapshot() async -> FamilySnapshot {
        snapshot
    }

    func ingestText(_ request: TextIngestionRequest) async throws -> FamilySnapshot {
        guard snapshot.members.contains(where: { $0.id == request.createdByMemberID }) else {
            throw FamilyRepositoryError.memberNotFound
        }

        let sourceID = UUID()
        var source = InboxSource(
            id: sourceID,
            title: request.title,
            kind: .text,
            createdAt: .now,
            status: .processing,
            proposalCount: 0,
            sourceText: request.text,
            errorMessage: nil
        )
        snapshot.inboxItems.append(source)

        let extracted = try await extractionService.extractProposals(
            sourceID: sourceID,
            text: request.text,
            members: snapshot.members
        )

        source.status = extracted.isEmpty ? .done : .review
        source.proposalCount = extracted.count

        if let index = snapshot.inboxItems.firstIndex(where: { $0.id == sourceID }) {
            snapshot.inboxItems[index] = source
        }
        snapshot.proposals.append(contentsOf: extracted)

        return snapshot
    }

    func confirmReviewedProposals(
        sourceID: UUID,
        proposals reviewedProposals: [ActionProposal]
    ) async throws -> FamilySnapshot {
        guard let sourceIndex = snapshot.inboxItems.firstIndex(where: { $0.id == sourceID }) else {
            throw FamilyRepositoryError.sourceNotFound
        }

        guard reviewedProposals.allSatisfy({ $0.sourceID == sourceID }) else {
            throw FamilyRepositoryError.invalidProposalSource
        }

        let included = reviewedProposals.filter(\.isIncluded)
        guard included.allSatisfy(\.isReadyToConfirm) else {
            throw FamilyRepositoryError.proposalsNotReady
        }

        for reviewed in reviewedProposals {
            if let index = snapshot.proposals.firstIndex(where: { $0.id == reviewed.id }) {
                snapshot.proposals[index] = reviewed
            }
        }

        for proposal in included {
            if snapshot.planItems.contains(where: { $0.sourceProposalID == proposal.id }) {
                if let index = snapshot.proposals.firstIndex(where: { $0.id == proposal.id }) {
                    snapshot.proposals[index].reviewStatus = .confirmed
                }
                continue
            }

            snapshot.planItems.append(
                PlanItem(
                    id: UUID(),
                    kind: proposal.kind,
                    title: proposal.title,
                    startsAt: proposal.startsAt,
                    endsAt: proposal.endsAt,
                    dueAt: proposal.dueAt,
                    memberIDs: proposal.memberIDs,
                    location: proposal.location,
                    note: proposal.note,
                    amountMinor: proposal.amountMinor,
                    currency: proposal.currency,
                    sourceID: proposal.sourceID,
                    sourceProposalID: proposal.id,
                    isCompleted: false
                )
            )

            if let index = snapshot.proposals.firstIndex(where: { $0.id == proposal.id }) {
                snapshot.proposals[index].reviewStatus = .confirmed
            }
        }

        let stillOpen = snapshot.proposals.contains {
            $0.sourceID == sourceID && $0.reviewStatus == .proposed
        }
        snapshot.inboxItems[sourceIndex].status = stillOpen ? .partial : .done
        snapshot.inboxItems[sourceIndex].proposalCount = included.count

        return snapshot
    }

    func setPlanItemCompleted(
        _ itemID: UUID,
        isCompleted: Bool
    ) async throws -> FamilySnapshot {
        guard let index = snapshot.planItems.firstIndex(where: { $0.id == itemID }) else {
            return snapshot
        }

        snapshot.planItems[index].isCompleted = isCompleted
        return snapshot
    }
}
