import Foundation
import Observation

@MainActor
@Observable
final class DemoStore {
    var members: [FamilyMember]
    var planItems: [PlanItem]
    var inboxItems: [InboxSource]
    var proposals: [ActionProposal]
    var isImportReviewPresented = false
    var selectedSourceID: UUID?
    var lastConfirmationCount = 0

    init() {
        let fixture = Self.makeFixture()
        members = fixture.members
        planItems = fixture.planItems
        inboxItems = fixture.inboxItems
        proposals = fixture.proposals
    }

    var children: [FamilyMember] {
        members.filter { $0.role == .child }
    }

    var includedProposalCount: Int {
        proposals.filter(\.isIncluded).count
    }

    var hasBlockingProposal: Bool {
        proposals.contains { $0.isIncluded && !$0.isReadyToConfirm }
    }

    var selectedSource: InboxSource? {
        guard let selectedSourceID else { return nil }
        return inboxItems.first { $0.id == selectedSourceID }
    }

    func member(for id: UUID) -> FamilyMember? {
        members.first { $0.id == id }
    }

    func openReview(sourceID: UUID) {
        selectedSourceID = sourceID
        isImportReviewPresented = true
    }

    func openSignatureReview() {
        if let source = inboxItems.first(where: { $0.status == .review }) {
            openReview(sourceID: source.id)
        }
    }

    func confirmSelectedProposals() {
        guard !hasBlockingProposal else { return }

        let accepted = proposals.filter { $0.isIncluded && $0.isReadyToConfirm }
        for proposal in accepted {
            let item = PlanItem(
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
                isCompleted: false
            )
            planItems.append(item)
        }

        if let sourceID = selectedSourceID,
           let index = inboxItems.firstIndex(where: { $0.id == sourceID }) {
            inboxItems[index].status = .done
            inboxItems[index].proposalCount = accepted.count
        }

        lastConfirmationCount = accepted.count
        isImportReviewPresented = false
    }

    func toggleCompletion(_ itemID: UUID) {
        guard let index = planItems.firstIndex(where: { $0.id == itemID }) else { return }
        planItems[index].isCompleted.toggle()
    }

    private struct Fixture {
        var members: [FamilyMember]
        var planItems: [PlanItem]
        var inboxItems: [InboxSource]
        var proposals: [ActionProposal]
    }

    private static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Europe/Berlin")
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? .now
    }

    private static func makeFixture() -> Fixture {
        let mara = FamilyMember(id: UUID(), name: "Mara", initials: "MB", role: .owner, accent: .indigo)
        let jonas = FamilyMember(id: UUID(), name: "Jonas", initials: "JB", role: .adult, accent: .teal)
        let lina = FamilyMember(id: UUID(), name: "Lina", initials: "LB", role: .child, accent: .orange)
        let ben = FamilyMember(id: UUID(), name: "Ben", initials: "BB", role: .child, accent: .purple)

        let schoolLetterID = UUID()
        let screenshotID = UUID()
        let voiceID = UUID()
        let failedID = UUID()

        let sourceText = """
        Liebe Eltern der Klasse 6b,

        am Freitag, den 18. September 2026, findet unsere Klassenfahrt ins Freilichtmuseum statt. Wir treffen uns um 07:30 Uhr vor dem Haupteingang der Schule. Die Rückkehr ist gegen 17:00 Uhr geplant.

        Bitte geben Sie die unterschriebene Einverständniserklärung spätestens bis zum 1. September bei der Klassenleitung ab.

        Der Kostenbeitrag von 35,00 € ist bis zum 5. September zu bezahlen.

        Die Kinder benötigen wetterfeste Kleidung, eine Trinkflasche und ein Lunchpaket.
        """

        let inbox = [
            InboxSource(id: schoolLetterID, title: "Klassenfahrt 6b", kind: .pdf, createdAt: date(2026, 8, 18, 19, 42), status: .review, proposalCount: 4, sourceText: sourceText, errorMessage: nil),
            InboxSource(id: screenshotID, title: "Screenshot Elternchat", kind: .image, createdAt: date(2026, 8, 18, 20, 3), status: .processing, proposalCount: 0, sourceText: nil, errorMessage: nil),
            InboxSource(id: voiceID, title: "Zahnarzt Lina", kind: .voice, createdAt: date(2026, 8, 17, 18, 12), status: .done, proposalCount: 1, sourceText: nil, errorMessage: nil),
            InboxSource(id: failedID, title: "Schulfest Foto", kind: .image, createdAt: date(2026, 8, 17, 17, 54), status: .failed, proposalCount: 0, sourceText: nil, errorMessage: "Text konnte nicht zuverlässig erkannt werden.")
        ]

        let existingPlan = [
            PlanItem(id: UUID(), kind: .event, title: "Zahnarzt", startsAt: date(2026, 8, 18, 15, 30), endsAt: date(2026, 8, 18, 16, 15), dueAt: nil, memberIDs: [lina.id, mara.id], location: "Praxis Dr. Klein", note: nil, amountMinor: nil, currency: nil, sourceID: voiceID, isCompleted: false),
            PlanItem(id: UUID(), kind: .event, title: "Fußballtraining", startsAt: date(2026, 8, 18, 17, 0), endsAt: date(2026, 8, 18, 18, 0), dueAt: nil, memberIDs: [ben.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false),
            PlanItem(id: UUID(), kind: .task, title: "Ben abholen", startsAt: date(2026, 8, 18, 18, 5), endsAt: nil, dueAt: date(2026, 8, 18, 18, 5), memberIDs: [jonas.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: screenshotID, isCompleted: false),
            PlanItem(id: UUID(), kind: .event, title: "Elternabend 6b", startsAt: date(2026, 8, 18, 19, 30), endsAt: date(2026, 8, 18, 21, 0), dueAt: nil, memberIDs: [mara.id, jonas.id], location: "Klassenraum 2.14", note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false),
            PlanItem(id: UUID(), kind: .deadline, title: "Einverständniserklärung unterschreiben", startsAt: nil, endsAt: nil, dueAt: date(2026, 8, 19, 23, 59), memberIDs: [mara.id, jonas.id, lina.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: schoolLetterID, isCompleted: false),
            PlanItem(id: UUID(), kind: .payment, title: "12 € Theater-AG bezahlen", startsAt: nil, endsAt: nil, dueAt: date(2026, 8, 20, 12, 0), memberIDs: [mara.id, jonas.id, lina.id], location: nil, note: nil, amountMinor: 1200, currency: "EUR", sourceID: nil, isCompleted: false)
        ]

        let proposals = [
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .event, title: "Klassenfahrt Freilichtmuseum", startsAt: date(2026, 9, 18, 7, 30), endsAt: date(2026, 9, 18, 17, 0), dueAt: nil, memberIDs: [], location: "Haupteingang der Schule", note: nil, amountMinor: nil, currency: nil, isIncluded: true, requiresMemberResolution: true),
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .deadline, title: "Einverständniserklärung abgeben", startsAt: nil, endsAt: nil, dueAt: date(2026, 9, 1, 23, 59), memberIDs: [mara.id, jonas.id], location: nil, note: "Für Lina", amountMinor: nil, currency: nil, isIncluded: true, requiresMemberResolution: false),
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .payment, title: "35 € Klassenfahrt bezahlen", startsAt: nil, endsAt: nil, dueAt: date(2026, 9, 5, 12, 0), memberIDs: [mara.id, jonas.id], location: nil, note: nil, amountMinor: 3500, currency: "EUR", isIncluded: true, requiresMemberResolution: false),
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .preparation, title: "Lunchpaket und Trinkflasche vorbereiten", startsAt: nil, endsAt: nil, dueAt: date(2026, 9, 17, 19, 0), memberIDs: [lina.id, mara.id], location: nil, note: "Wetterfeste Kleidung", amountMinor: nil, currency: nil, isIncluded: true, requiresMemberResolution: false)
        ]

        return Fixture(
            members: [mara, jonas, lina, ben],
            planItems: existingPlan,
            inboxItems: inbox,
            proposals: proposals
        )
    }
}
