import Foundation
import Observation

enum DemoScenario: Sendable {
    case standard
    case calmToday
    case conflictToday
    case readyImport
}

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
    var isRepositoryBusy = false
    var repositoryErrorMessage: String?

    @ObservationIgnored private let repository: any FamilyRepository
    @ObservationIgnored private var allProposals: [ActionProposal]

    init(scenario: DemoScenario = .standard) {
        var snapshot = Self.makeFixture()
        Self.apply(scenario, to: &snapshot)

        members = snapshot.members
        planItems = snapshot.planItems
        inboxItems = snapshot.inboxItems
        proposals = snapshot.proposals
        allProposals = snapshot.proposals
        repository = InMemoryFamilyRepository(snapshot: snapshot)
    }

    var children: [FamilyMember] {
        members.filter { $0.role == .child }
    }

    var includedProposalCount: Int {
        proposals.filter { $0.isIncluded && $0.reviewStatus == .proposed }.count
    }

    var hasBlockingProposal: Bool {
        proposals.contains {
            $0.isIncluded && $0.reviewStatus == .proposed && !$0.isReadyToConfirm
        }
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
        proposals = allProposals.filter { $0.sourceID == sourceID }
        isImportReviewPresented = true
    }

    func openSignatureReview() {
        if let source = inboxItems.first(where: { $0.status == .review }) {
            openReview(sourceID: source.id)
        }
    }

    func ingestSchoolLetterText() {
        guard let actor = members.first(where: { $0.role == .owner || $0.role == .adult }) else {
            repositoryErrorMessage = FamilyRepositoryError.memberNotFound.localizedDescription
            return
        }

        let existingSourceIDs = Set(inboxItems.map(\.id))
        isRepositoryBusy = true
        repositoryErrorMessage = nil

        Task {
            do {
                let snapshot = try await repository.ingestText(
                    TextIngestionRequest(
                        title: "Klassenfahrt 6b · Text",
                        text: Self.signatureSourceText,
                        createdByMemberID: actor.id
                    )
                )
                apply(snapshot)

                if let newSource = inboxItems
                    .filter({ !existingSourceIDs.contains($0.id) })
                    .sorted(by: { $0.createdAt > $1.createdAt })
                    .first {
                    openReview(sourceID: newSource.id)
                }
            } catch {
                repositoryErrorMessage = error.localizedDescription
            }

            isRepositoryBusy = false
        }
    }

    func confirmSelectedProposals() {
        guard !hasBlockingProposal,
              let selectedSourceID else { return }

        let reviewed = proposals
        let acceptedCount = reviewed.filter {
            $0.isIncluded && $0.reviewStatus == .proposed && $0.isReadyToConfirm
        }.count

        isRepositoryBusy = true
        repositoryErrorMessage = nil

        Task {
            do {
                let snapshot = try await repository.confirmReviewedProposals(
                    sourceID: selectedSourceID,
                    proposals: reviewed
                )
                apply(snapshot)
                lastConfirmationCount = acceptedCount
                isImportReviewPresented = false
            } catch {
                repositoryErrorMessage = error.localizedDescription
            }

            isRepositoryBusy = false
        }
    }

    func toggleCompletion(_ itemID: UUID) {
        guard let index = planItems.firstIndex(where: { $0.id == itemID }) else { return }

        planItems[index].isCompleted.toggle()
        let desiredState = planItems[index].isCompleted

        Task {
            do {
                let snapshot = try await repository.setPlanItemCompleted(
                    itemID,
                    isCompleted: desiredState
                )
                apply(snapshot)
            } catch {
                apply(await repository.currentSnapshot())
                repositoryErrorMessage = error.localizedDescription
            }
        }
    }

    private func apply(_ snapshot: FamilySnapshot) {
        members = snapshot.members
        planItems = snapshot.planItems
        inboxItems = snapshot.inboxItems
        allProposals = snapshot.proposals

        if let selectedSourceID {
            proposals = snapshot.proposals.filter { $0.sourceID == selectedSourceID }
        } else {
            proposals = snapshot.proposals
        }
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

    private static func apply(_ scenario: DemoScenario, to snapshot: inout FamilySnapshot) {
        switch scenario {
        case .standard:
            break

        case .calmToday:
            guard
                let lina = snapshot.members.first(where: { $0.name == "Lina" }),
                let ben = snapshot.members.first(where: { $0.name == "Ben" })
            else { return }

            snapshot.planItems = [
                PlanItem(id: UUID(), kind: .event, title: "Kita", startsAt: date(2026, 8, 18, 8, 0), endsAt: nil, dueAt: nil, memberIDs: [ben.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false),
                PlanItem(id: UUID(), kind: .event, title: "Lina bei Oma", startsAt: date(2026, 8, 18, 16, 30), endsAt: nil, dueAt: nil, memberIDs: [lina.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false)
            ]

        case .conflictToday:
            guard
                let mara = snapshot.members.first(where: { $0.name == "Mara" }),
                let lina = snapshot.members.first(where: { $0.name == "Lina" }),
                let ben = snapshot.members.first(where: { $0.name == "Ben" })
            else { return }

            snapshot.planItems = [
                PlanItem(id: UUID(), kind: .event, title: "Zahnarzt Lina", startsAt: date(2026, 8, 18, 16, 0), endsAt: date(2026, 8, 18, 16, 45), dueAt: nil, memberIDs: [mara.id, lina.id], location: "Praxis Dr. Klein", note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false),
                PlanItem(id: UUID(), kind: .event, title: "Elterngespräch Ben", startsAt: date(2026, 8, 18, 16, 15), endsAt: date(2026, 8, 18, 17, 0), dueAt: nil, memberIDs: [mara.id, ben.id], location: "Kita", note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false)
            ]

        case .readyImport:
            guard let lina = snapshot.members.first(where: { $0.name == "Lina" }) else { return }
            if let index = snapshot.proposals.firstIndex(where: { $0.requiresMemberResolution }) {
                snapshot.proposals[index].memberIDs = [lina.id]
                snapshot.proposals[index].requiresMemberResolution = false
            }
        }
    }

    static let signatureSourceText = """
    Liebe Eltern der Klasse 6b,

    am Freitag, den 18. September 2026, findet unsere Klassenfahrt ins Freilichtmuseum statt. Wir treffen uns um 07:30 Uhr vor dem Haupteingang der Schule. Die Rückkehr ist gegen 17:00 Uhr geplant.

    Bitte geben Sie die unterschriebene Einverständniserklärung spätestens bis zum 1. September bei der Klassenleitung ab.

    Der Kostenbeitrag von 35,00 € ist bis zum 5. September zu bezahlen.

    Die Kinder benötigen wetterfeste Kleidung, eine Trinkflasche und ein Lunchpaket.
    """

    private static func makeFixture() -> FamilySnapshot {
        let mara = FamilyMember(id: UUID(), name: "Mara", initials: "MB", role: .owner, accent: .indigo)
        let jonas = FamilyMember(id: UUID(), name: "Jonas", initials: "JB", role: .adult, accent: .teal)
        let lina = FamilyMember(id: UUID(), name: "Lina", initials: "LB", role: .child, accent: .orange)
        let ben = FamilyMember(id: UUID(), name: "Ben", initials: "BB", role: .child, accent: .purple)

        let schoolLetterID = UUID()
        let screenshotID = UUID()
        let voiceID = UUID()
        let failedID = UUID()
        let partialID = UUID()
        let queuedID = UUID()

        let inbox = [
            InboxSource(id: schoolLetterID, title: "Klassenfahrt 6b", kind: .pdf, createdAt: date(2026, 8, 18, 19, 42), status: .review, proposalCount: 4, sourceText: signatureSourceText, errorMessage: nil),
            InboxSource(id: screenshotID, title: "Screenshot Elternchat", kind: .image, createdAt: date(2026, 8, 18, 20, 3), status: .processing, proposalCount: 0, sourceText: nil, errorMessage: nil),
            InboxSource(id: queuedID, title: "Foto vom Elternbrief", kind: .image, createdAt: date(2026, 8, 18, 20, 12), status: .queued, proposalCount: 0, sourceText: nil, errorMessage: "Wird synchronisiert, sobald du wieder online bist."),
            InboxSource(id: voiceID, title: "Zahnarzt Lina", kind: .voice, createdAt: date(2026, 8, 17, 18, 12), status: .done, proposalCount: 1, sourceText: nil, errorMessage: nil),
            InboxSource(id: failedID, title: "Schulfest Foto", kind: .image, createdAt: date(2026, 8, 17, 17, 54), status: .failed, proposalCount: 0, sourceText: nil, errorMessage: "Text konnte nicht zuverlässig erkannt werden."),
            InboxSource(id: partialID, title: "Theater-AG Info", kind: .text, createdAt: date(2026, 8, 16, 21, 10), status: .partial, proposalCount: 3, sourceText: "Theater-AG: 12 € bis Donnerstag. Aufführung am Freitag um 17 Uhr.", errorMessage: nil)
        ]

        let existingPlan = [
            PlanItem(id: UUID(), kind: .event, title: "Zahnarzt", startsAt: date(2026, 8, 18, 15, 30), endsAt: date(2026, 8, 18, 16, 15), dueAt: nil, memberIDs: [lina.id, mara.id], location: "Praxis Dr. Klein", note: nil, amountMinor: nil, currency: nil, sourceID: voiceID, isCompleted: false),
            PlanItem(id: UUID(), kind: .event, title: "Fußballtraining", startsAt: date(2026, 8, 18, 17, 0), endsAt: date(2026, 8, 18, 18, 0), dueAt: nil, memberIDs: [ben.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false),
            PlanItem(id: UUID(), kind: .task, title: "Ben abholen", startsAt: date(2026, 8, 18, 18, 5), endsAt: nil, dueAt: date(2026, 8, 18, 18, 5), memberIDs: [jonas.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: screenshotID, isCompleted: false),
            PlanItem(id: UUID(), kind: .event, title: "Elternabend 6b", startsAt: date(2026, 8, 18, 19, 30), endsAt: date(2026, 8, 18, 21, 0), dueAt: nil, memberIDs: [mara.id, jonas.id], location: "Klassenraum 2.14", note: nil, amountMinor: nil, currency: nil, sourceID: nil, isCompleted: false),
            PlanItem(id: UUID(), kind: .deadline, title: "Einverständniserklärung unterschreiben", startsAt: nil, endsAt: nil, dueAt: date(2026, 8, 19, 23, 59), memberIDs: [mara.id, jonas.id, lina.id], location: nil, note: nil, amountMinor: nil, currency: nil, sourceID: schoolLetterID, isCompleted: false),
            PlanItem(id: UUID(), kind: .payment, title: "12 € Theater-AG bezahlen", startsAt: nil, endsAt: nil, dueAt: date(2026, 8, 20, 12, 0), memberIDs: [mara.id, jonas.id, lina.id], location: nil, note: nil, amountMinor: 1200, currency: "EUR", sourceID: nil, isCompleted: false)
        ]

        let initialProposals = [
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .event, title: "Klassenfahrt Freilichtmuseum", startsAt: date(2026, 9, 18, 7, 30), endsAt: date(2026, 9, 18, 17, 0), dueAt: nil, memberIDs: [], location: "Haupteingang der Schule", note: nil, amountMinor: nil, currency: nil, isIncluded: true, requiresMemberResolution: true),
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .deadline, title: "Einverständniserklärung abgeben", startsAt: nil, endsAt: nil, dueAt: date(2026, 9, 1, 23, 59), memberIDs: [mara.id, jonas.id], location: nil, note: "Für Lina", amountMinor: nil, currency: nil, isIncluded: true, requiresMemberResolution: false),
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .payment, title: "35 € Klassenfahrt bezahlen", startsAt: nil, endsAt: nil, dueAt: date(2026, 9, 5, 12, 0), memberIDs: [mara.id, jonas.id], location: nil, note: nil, amountMinor: 3500, currency: "EUR", isIncluded: true, requiresMemberResolution: false),
            ActionProposal(id: UUID(), sourceID: schoolLetterID, kind: .preparation, title: "Lunchpaket und Trinkflasche vorbereiten", startsAt: nil, endsAt: nil, dueAt: date(2026, 9, 17, 19, 0), memberIDs: [lina.id, mara.id], location: nil, note: "Wetterfeste Kleidung", amountMinor: nil, currency: nil, isIncluded: true, requiresMemberResolution: false)
        ]

        return FamilySnapshot(
            members: [mara, jonas, lina, ben],
            planItems: existingPlan,
            inboxItems: inbox,
            proposals: initialProposals
        )
    }
}
