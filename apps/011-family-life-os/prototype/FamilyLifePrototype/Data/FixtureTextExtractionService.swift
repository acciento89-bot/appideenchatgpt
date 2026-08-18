import Foundation

struct FixtureTextExtractionService: TextExtractionService {
    func extractProposals(
        sourceID: UUID,
        text: String,
        members: [FamilyMember]
    ) async throws -> [ActionProposal] {
        guard let mara = members.first(where: { $0.name == "Mara" }),
              let jonas = members.first(where: { $0.name == "Jonas" }),
              let lina = members.first(where: { $0.name == "Lina" }) else {
            throw FamilyRepositoryError.memberNotFound
        }

        let normalized = text.lowercased()
        guard normalized.contains("klassenfahrt"),
              normalized.contains("35,00"),
              normalized.contains("einverständniserklärung") else {
            return []
        }

        return [
            ActionProposal(
                id: UUID(),
                sourceID: sourceID,
                kind: .event,
                title: "Klassenfahrt Freilichtmuseum",
                startsAt: date(2026, 9, 18, 7, 30),
                endsAt: date(2026, 9, 18, 17, 0),
                dueAt: nil,
                memberIDs: [],
                location: "Haupteingang der Schule",
                note: nil,
                amountMinor: nil,
                currency: nil,
                isIncluded: true,
                requiresMemberResolution: true
            ),
            ActionProposal(
                id: UUID(),
                sourceID: sourceID,
                kind: .deadline,
                title: "Einverständniserklärung abgeben",
                startsAt: nil,
                endsAt: nil,
                dueAt: date(2026, 9, 1, 23, 59),
                memberIDs: [mara.id, jonas.id],
                location: nil,
                note: "Für Lina",
                amountMinor: nil,
                currency: nil,
                isIncluded: true,
                requiresMemberResolution: false
            ),
            ActionProposal(
                id: UUID(),
                sourceID: sourceID,
                kind: .payment,
                title: "35 € Klassenfahrt bezahlen",
                startsAt: nil,
                endsAt: nil,
                dueAt: date(2026, 9, 5, 12, 0),
                memberIDs: [mara.id, jonas.id],
                location: nil,
                note: nil,
                amountMinor: 3500,
                currency: "EUR",
                isIncluded: true,
                requiresMemberResolution: false
            ),
            ActionProposal(
                id: UUID(),
                sourceID: sourceID,
                kind: .preparation,
                title: "Lunchpaket und Trinkflasche vorbereiten",
                startsAt: nil,
                endsAt: nil,
                dueAt: date(2026, 9, 17, 19, 0),
                memberIDs: [lina.id, mara.id],
                location: nil,
                note: "Wetterfeste Kleidung",
                amountMinor: nil,
                currency: nil,
                isIncluded: true,
                requiresMemberResolution: false
            )
        ]
    }

    private func date(
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
}
