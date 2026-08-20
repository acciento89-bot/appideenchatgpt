import Foundation

@main
struct ProposalModelRegression {
    static func main() {
        let sourceID = UUID()
        let memberID = UUID()

        var timeProposal = ActionProposal(
            id: UUID(),
            sourceID: sourceID,
            kind: .event,
            title: "Elternabend",
            startsAt: Date(timeIntervalSince1970: 1_787_245_200),
            endsAt: nil,
            dueAt: nil,
            memberIDs: [],
            location: nil,
            note: nil,
            amountMinor: nil,
            currency: nil,
            isIncluded: true,
            requiresMemberResolution: false,
            unresolvedFields: ["time": "required"]
        )
        precondition(!timeProposal.isReadyToConfirm, "Missing time must block confirmation")
        timeProposal.resolveUncertainty("time")
        precondition(timeProposal.isReadyToConfirm, "Resolving time should unblock an otherwise complete proposal")

        var memberProposal = ActionProposal(
            id: UUID(),
            sourceID: sourceID,
            kind: .task,
            title: "Abholen",
            startsAt: nil,
            endsAt: nil,
            dueAt: nil,
            memberIDs: [],
            location: nil,
            note: nil,
            amountMinor: nil,
            currency: nil,
            isIncluded: true,
            requiresMemberResolution: true,
            unresolvedFields: ["member": "required"]
        )
        precondition(!memberProposal.isReadyToConfirm, "Missing member must block confirmation")
        memberProposal.memberIDs = [memberID]
        memberProposal.resolveUncertainty("member")
        precondition(memberProposal.isReadyToConfirm, "Explicit member selection should resolve the member blocker")

        var mixedProposal = ActionProposal(
            id: UUID(),
            sourceID: sourceID,
            kind: .payment,
            title: "Beitrag bezahlen",
            startsAt: nil,
            endsAt: nil,
            dueAt: nil,
            memberIDs: [],
            location: nil,
            note: nil,
            amountMinor: 3500,
            currency: "EUR",
            isIncluded: true,
            requiresMemberResolution: true,
            unresolvedFields: ["member": "required", "due_at": "required"]
        )
        mixedProposal.memberIDs = [memberID]
        mixedProposal.resolveUncertainty("member")
        precondition(!mixedProposal.isReadyToConfirm, "Resolving member must not erase an unrelated due-date blocker")
        precondition(mixedProposal.unresolvedFields == ["due_at": "required"], "Unrelated unresolved fields must survive edits")
        mixedProposal.dueAt = Date(timeIntervalSince1970: 1_787_332_740)
        mixedProposal.resolveUncertainty("due_at")
        precondition(mixedProposal.isReadyToConfirm, "All blockers resolved should allow confirmation")

        print("Family proposal regression checks passed")
    }
}
