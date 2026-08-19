import Foundation
import Supabase

struct HostedSmokeTestStep: Identifiable, Sendable {
    let id: String
    let title: String
    let detail: String
    let passed: Bool
}

struct HostedSmokeTestReport: Sendable {
    let passed: Bool
    let steps: [HostedSmokeTestStep]
    let finishedAt: Date
}

actor HostedSmokeTestService {
    private let repository: SupabaseFamilyRepository
    private let client: SupabaseClient

    init(
        repository: SupabaseFamilyRepository,
        client: SupabaseClient = SupabaseEnvironment.client
    ) {
        self.repository = repository
        self.client = client
    }

    func run() async -> HostedSmokeTestReport {
        let runID = UUID().uuidString.lowercased().prefix(8)
        let sourceTitle = "E2E Schulbrief · \(runID)"
        var sourceID: UUID?
        var createdChildID: UUID?
        var steps: [HostedSmokeTestStep] = []

        do {
            let user = try await client.auth.session.user
            steps.append(
                step(
                    "session",
                    title: "Auth-Session",
                    detail: "Angemeldete Session \(user.id.uuidString.prefix(8))… ist aktiv."
                )
            )

            var snapshot = try await repository.currentSnapshot()
            try require(
                snapshot.members.contains(where: { $0.role == .owner || $0.role == .adult }),
                "Kein verwaltendes Haushaltsmitglied gefunden."
            )
            steps.append(
                step(
                    "household",
                    title: "Haushalt laden",
                    detail: "\(snapshot.members.count) Mitglied(er) über Hosted RLS geladen."
                )
            )

            let child: FamilyMember
            if let existingChild = snapshot.members.first(where: { $0.role == .child }) {
                child = existingChild
                steps.append(
                    step(
                        "child",
                        title: "Kind-Zuordnung",
                        detail: "Vorhandenes Kinderprofil \(existingChild.name) wird für den Test verwendet."
                    )
                )
            } else {
                let beforeMemberIDs = Set(snapshot.members.map(\.id))
                snapshot = try await repository.addChild(named: "E2E Testkind")
                guard let newChild = snapshot.members.first(where: {
                    $0.role == .child && !beforeMemberIDs.contains($0.id)
                }) else {
                    throw HostedSmokeTestError.assertion("Test-Kinderprofil wurde nicht zurückgeliefert.")
                }
                child = newChild
                createdChildID = newChild.id
                steps.append(
                    step(
                        "child",
                        title: "Kind-Zuordnung",
                        detail: "Temporäres Kinderprofil wurde über Hosted RLS angelegt."
                    )
                )
            }

            guard let actor = snapshot.members.first(where: { $0.role == .owner || $0.role == .adult }) else {
                throw HostedSmokeTestError.assertion("Kein Owner/Adult für den Textimport verfügbar.")
            }

            let inboxBefore = Set(snapshot.inboxItems.map(\.id))
            snapshot = try await repository.ingestText(
                TextIngestionRequest(
                    title: sourceTitle,
                    text: Self.schoolLetter,
                    createdByMemberID: actor.id
                )
            )

            guard let newSource = snapshot.inboxItems.first(where: {
                !inboxBefore.contains($0.id) && $0.title == sourceTitle
            }) else {
                throw HostedSmokeTestError.assertion("Der Hosted-Textimport hat keine neue Inbox-Quelle erzeugt.")
            }
            sourceID = newSource.id
            steps.append(
                step(
                    "ingest",
                    title: "Schulbrief importieren",
                    detail: "Neue Hosted-Quelle \(newSource.id.uuidString.prefix(8))… wurde erzeugt."
                )
            )

            var proposals = snapshot.proposals.filter { $0.sourceID == newSource.id }
            try require(proposals.count == 4, "Erwartet wurden 4 Vorschläge, erhalten: \(proposals.count).")
            steps.append(
                step(
                    "proposals",
                    title: "4 Vorschläge",
                    detail: "Termin, Frist, Zahlung und Vorbereitung wurden geladen."
                )
            )

            guard let eventIndex = proposals.firstIndex(where: { $0.kind == .event }) else {
                throw HostedSmokeTestError.assertion("Der Klassenfahrt-Termin fehlt.")
            }
            proposals[eventIndex].memberIDs = [child.id]
            proposals[eventIndex].requiresMemberResolution = false
            try require(
                proposals.allSatisfy { !$0.isIncluded || $0.isReadyToConfirm },
                "Mindestens ein eingeschlossener Vorschlag bleibt ungeklärt."
            )
            steps.append(
                step(
                    "review",
                    title: "Review-Grenze",
                    detail: "Ungeklärte Kind-Zuordnung wurde explizit auf \(child.name) gesetzt."
                )
            )

            snapshot = try await repository.confirmReviewedProposals(
                sourceID: newSource.id,
                proposals: proposals
            )

            let createdPlanItems = snapshot.planItems.filter { $0.sourceID == newSource.id }
            try require(createdPlanItems.count == 4, "Confirm erzeugte \(createdPlanItems.count) statt 4 PlanItems.")
            try require(
                createdPlanItems.allSatisfy { $0.sourceProposalID != nil },
                "Mindestens einem PlanItem fehlt die Proposal-Provenance."
            )
            try require(
                snapshot.inboxItems.first(where: { $0.id == newSource.id })?.status == .done,
                "Die Inbox-Quelle wurde nach vollständigem Confirm nicht auf done gesetzt."
            )
            steps.append(
                step(
                    "confirm",
                    title: "Canonical Confirm",
                    detail: "4 PlanItems mit Source-/Proposal-Provenance wurden erstellt."
                )
            )

            let includedProposalIDs = proposals.filter(\.isIncluded).map(\.id)
            let _: [SmokeConfirmedRow] = try await client
                .rpc(
                    "confirm_action_proposals",
                    params: SmokeConfirmParams(
                        sourceItemID: newSource.id,
                        proposalIDs: includedProposalIDs
                    )
                )
                .execute()
                .value

            let afterRetry = try await repository.currentSnapshot()
            try require(
                afterRetry.planItems.filter { $0.sourceID == newSource.id }.count == 4,
                "Idempotenz-Retry hat zusätzliche PlanItems erzeugt."
            )
            steps.append(
                step(
                    "retry",
                    title: "Idempotenz-Retry",
                    detail: "Zweiter Confirm-Aufruf bleibt bei exakt 4 PlanItems."
                )
            )

            let cleanupPassed = await cleanup(
                sourceTitle: sourceTitle,
                preferredSourceID: sourceID,
                createdChildID: createdChildID
            )
            try require(cleanupPassed, "Temporäre Hosted-Testdaten konnten nicht vollständig entfernt werden.")
            steps.append(
                step(
                    "cleanup",
                    title: "Cleanup",
                    detail: "Temporäre Quelle, PlanItems und Testprofil wurden entfernt."
                )
            )

            return HostedSmokeTestReport(passed: true, steps: steps, finishedAt: .now)
        } catch {
            let cleanupPassed = await cleanup(
                sourceTitle: sourceTitle,
                preferredSourceID: sourceID,
                createdChildID: createdChildID
            )
            steps.append(
                HostedSmokeTestStep(
                    id: "failure",
                    title: "Smoke-Test fehlgeschlagen",
                    detail: error.localizedDescription,
                    passed: false
                )
            )
            steps.append(
                HostedSmokeTestStep(
                    id: "cleanup-after-failure",
                    title: "Cleanup nach Fehler",
                    detail: cleanupPassed
                        ? "Temporäre Testdaten wurden entfernt."
                        : "Cleanup konnte nicht vollständig bestätigt werden.",
                    passed: cleanupPassed
                )
            )
            return HostedSmokeTestReport(passed: false, steps: steps, finishedAt: .now)
        }
    }

    private func cleanup(
        sourceTitle: String,
        preferredSourceID: UUID?,
        createdChildID: UUID?
    ) async -> Bool {
        do {
            var sourceIDs: [UUID] = []
            if let preferredSourceID {
                sourceIDs = [preferredSourceID]
            } else {
                let rows: [SmokeSourceIDRow] = try await client
                    .from("source_items")
                    .select("id")
                    .eq("display_title", value: sourceTitle)
                    .execute()
                    .value
                sourceIDs = rows.map(\.id)
            }

            for sourceID in sourceIDs {
                try await client
                    .from("plan_items")
                    .delete()
                    .eq("source_item_id", value: sourceID)
                    .execute()

                try await client
                    .from("source_items")
                    .delete()
                    .eq("id", value: sourceID)
                    .execute()
            }

            if let createdChildID {
                try await client
                    .from("household_members")
                    .delete()
                    .eq("id", value: createdChildID)
                    .execute()
            }

            return true
        } catch {
            return false
        }
    }

    private func step(_ id: String, title: String, detail: String) -> HostedSmokeTestStep {
        HostedSmokeTestStep(id: id, title: title, detail: detail, passed: true)
    }

    private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw HostedSmokeTestError.assertion(message)
        }
    }

    private static let schoolLetter = """
    Liebe Eltern der Klasse 6b,
    am Freitag, den 18. September 2026, findet unsere Klassenfahrt ins Freilichtmuseum statt. Wir treffen uns um 07:30 Uhr vor dem Haupteingang der Schule. Die Rückkehr ist gegen 17:00 Uhr geplant.
    Bitte geben Sie die unterschriebene Einverständniserklärung spätestens bis zum 1. September bei der Klassenleitung ab.
    Der Kostenbeitrag von 35,00 € ist bis zum 5. September zu bezahlen.
    Die Kinder benötigen wetterfeste Kleidung, eine Trinkflasche und ein Lunchpaket.
    Viele Grüße
    Frau Neumann
    """
}

private enum HostedSmokeTestError: LocalizedError {
    case assertion(String)

    var errorDescription: String? {
        switch self {
        case .assertion(let message): message
        }
    }
}

private struct SmokeConfirmParams: Encodable, Sendable {
    let sourceItemID: UUID
    let proposalIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case sourceItemID = "p_source_item_id"
        case proposalIDs = "p_proposal_ids"
    }
}

private struct SmokeConfirmedRow: Decodable, Sendable {
    let proposalID: UUID
    let planItemID: UUID

    enum CodingKeys: String, CodingKey {
        case proposalID = "proposal_id"
        case planItemID = "plan_item_id"
    }
}

private struct SmokeSourceIDRow: Decodable, Sendable {
    let id: UUID
}
