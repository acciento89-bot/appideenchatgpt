import Foundation

enum RapportWorkError: Error { case invalidInput, invalidArchive, unsupportedVersion }
enum RapportWorkKind: String, Codable, Hashable, CaseIterable { case labor, material, measurement }

struct RapportWorkItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var kind: RapportWorkKind
    var description: String
    var unit: String
    var minutes: Int?
    private var quantityValue: String?
    var quantity: Decimal? { quantityValue.flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) } }

    static func labor(description: String, minutes: Int) throws -> Self {
        let result = Self(kind: .labor, description: description.trimmingCharacters(in: .whitespacesAndNewlines), unit: "min", minutes: minutes)
        try result.validate(); return result
    }
    static func quantity(kind: RapportWorkKind, description: String, amount: String, unit: String) throws -> Self {
        guard kind != .labor else { throw RapportWorkError.invalidInput }
        let amount = amount.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard amount.range(of: "^[0-9]{1,12}(\\.[0-9]{1,3})?$", options: .regularExpression) != nil,
              var decimal = Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")),
              decimal >= 0, decimal <= Decimal(string: "999999999.999")! else { throw RapportWorkError.invalidInput }
        let result = Self(kind: kind, description: description.trimmingCharacters(in: .whitespacesAndNewlines), unit: unit.trimmingCharacters(in: .whitespacesAndNewlines), quantityValue: NSDecimalString(&decimal, Locale(identifier: "en_US_POSIX")))
        try result.validate(); return result
    }
    static func blank(kind: RapportWorkKind, description: String, unit: String) -> Self {
        Self(kind: kind, description: description, unit: kind == .labor ? "min" : unit)
    }
    func validate() throws {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw RapportWorkError.invalidInput }
        if kind == .labor {
            guard quantityValue == nil, unit == "min", minutes.map({ (0...1_000_000).contains($0) }) ?? true else { throw RapportWorkError.invalidInput }
        } else {
            guard minutes == nil else { throw RapportWorkError.invalidInput }
            if let quantityValue {
                guard quantityValue.range(of: "^[0-9]{1,12}(\\.[0-9]{1,3})?$", options: .regularExpression) != nil,
                      let quantity, quantity >= 0, quantity <= Decimal(string: "999999999.999")! else { throw RapportWorkError.invalidInput }
            }
        }
    }
}

struct RapportWorkTotals {
    private struct Key: Hashable { let kind: RapportWorkKind; let unit: String }
    let laborMinutes: Int
    let incompleteCount: Int
    private var quantities: [Key: Decimal]
    init(items: [RapportWorkItem]) throws {
        guard items.count <= 1000, Set(items.map(\.id)).count == items.count else { throw RapportWorkError.invalidInput }
        var minutes = 0, incomplete = 0
        var quantities: [Key: Decimal] = [:]
        for item in items {
            try item.validate()
            if item.kind == .labor {
                if let value = item.minutes { minutes += value } else { incomplete += 1 }
            } else if var value = item.quantity {
                let key = Key(kind: item.kind, unit: item.unit.trimmingCharacters(in: .whitespacesAndNewlines))
                var old = quantities[key, default: 0], sum = Decimal()
                guard NSDecimalAdd(&sum, &old, &value, .plain) == .noError else { throw RapportWorkError.invalidInput }
                quantities[key] = sum
            } else { incomplete += 1 }
        }
        laborMinutes = minutes; incompleteCount = incomplete; self.quantities = quantities
    }
    func quantity(kind: RapportWorkKind, unit: String) -> Decimal { quantities[Key(kind: kind, unit: unit.trimmingCharacters(in: .whitespacesAndNewlines)), default: 0] }
}

struct RapportWorkTemplate: Codable, Hashable, Identifiable {
    struct Line: Codable, Hashable { var kind: RapportWorkKind; var description: String; var unit: String }
    var id = UUID()
    var name: String
    var trade: TradeCategory
    var lines: [Line]
    init(name: String, trade: TradeCategory, items: [RapportWorkItem]) throws {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines); self.trade = trade
        _ = try RapportWorkTotals(items: items)
        lines = items.map { Line(kind: $0.kind, description: $0.description, unit: $0.unit) }
        try validate()
    }
    func instantiate() -> [RapportWorkItem] { lines.map { .blank(kind: $0.kind, description: $0.description, unit: $0.unit) } }
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !lines.isEmpty else { throw RapportWorkError.invalidInput }
        _ = try RapportWorkTotals(items: instantiate())
    }
}

struct RapportRevisionContent: Codable, Hashable {
    var reportID: UUID
    var trade: TradeCategory
    var customer: String
    var location: String
    var system: String
    var rawText: String
    var reportText: String
    var tone: RapportTone
    var createdAt: Date
    var workItems: [RapportWorkItem]
    init(draft: RapportDraft) {
        reportID = draft.id; trade = draft.trade; customer = draft.customer; location = draft.location; system = draft.system
        rawText = draft.rawText; reportText = draft.reportText; tone = draft.tone; createdAt = draft.createdAt; workItems = draft.workItems
    }
    func validate() throws {
        guard createdAt.timeIntervalSince1970.isFinite else { throw RapportWorkError.invalidArchive }
        _ = try RapportWorkTotals(items: workItems)
    }
}
struct RapportRevision: Codable, Hashable, Identifiable {
    var id = UUID()
    var number: Int
    var at: Date
    var content: RapportRevisionContent
}
struct RapportAcknowledgement: Codable, Hashable, Identifiable {
    var id = UUID()
    var revisionID: UUID
    var name: String
    var note: String
    var at: Date
}

extension RapportDraft {
    var latestIsAcknowledged: Bool {
        guard let last = revisions.last, last.content == RapportRevisionContent(draft: self) else { return false }
        return acknowledgements.contains { $0.revisionID == last.id }
    }
    func savingRevision(at: Date = Date()) throws -> Self {
        try validateWorkHistory()
        guard at.timeIntervalSince1970.isFinite else { throw RapportWorkError.invalidInput }
        var result = self
        let content = RapportRevisionContent(draft: self)
        if revisions.last?.content != content {
            result.revisions.append(RapportRevision(number: revisions.count + 1, at: at, content: content))
        }
        result.updatedAt = at
        return result
    }
    func preparingSave(preserving stored: Self?, at: Date = Date()) throws -> Self {
        guard let stored else { return try savingRevision(at: at) }
        try stored.validateWorkHistory()
        guard stored.id == id else { throw RapportWorkError.invalidArchive }
        var result = self
        // A stale editor owns current content only. Stored history/acknowledgements always win.
        result.createdAt = stored.createdAt
        result.revisions = stored.revisions
        result.acknowledgements = stored.acknowledgements
        return try result.savingRevision(at: at)
    }
    func acknowledging(revisionID: UUID, name: String, note: String, at: Date = Date()) throws -> Self {
        try validateWorkHistory()
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard revisions.contains(where: { $0.id == revisionID }), !name.isEmpty, at.timeIntervalSince1970.isFinite else { throw RapportWorkError.invalidInput }
        var result = self
        result.acknowledgements.append(RapportAcknowledgement(revisionID: revisionID, name: name, note: note.trimmingCharacters(in: .whitespacesAndNewlines), at: at))
        return result
    }
    func validateWorkHistory() throws {
        guard createdAt.timeIntervalSince1970.isFinite, updatedAt.timeIntervalSince1970.isFinite,
              Set(revisions.map(\.id)).count == revisions.count,
              Set(acknowledgements.map(\.id)).count == acknowledgements.count else { throw RapportWorkError.invalidArchive }
        _ = try RapportWorkTotals(items: workItems)
        for (index, revision) in revisions.enumerated() {
            guard revision.number == index + 1, revision.content.reportID == id, revision.content.createdAt == createdAt,
                  revision.at.timeIntervalSince1970.isFinite else { throw RapportWorkError.invalidArchive }
            try revision.content.validate()
        }
        for acknowledgement in acknowledgements {
            guard revisions.contains(where: { $0.id == acknowledgement.revisionID }), !acknowledgement.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  acknowledgement.at.timeIntervalSince1970.isFinite else { throw RapportWorkError.invalidArchive }
        }
    }
    func structuredWorkText(german: Bool) -> String {
        func l(_ de: String, _ en: String) -> String { german ? de : en }
        func kind(_ kind: RapportWorkKind) -> String {
            switch kind { case .labor: return l("Arbeitszeit", "Labor"); case .material: return "Material"; case .measurement: return l("Messwert", "Measurement") }
        }
        func lines(_ items: [RapportWorkItem]) -> [String] {
            items.map { item in
                let value: String
                if item.kind == .labor { value = item.minutes.map { "\($0) min" } ?? l("Nicht angegeben", "Not entered") }
                else { value = item.quantity.map { decimal in var decimal = decimal; return NSDecimalString(&decimal, Locale(identifier: german ? "de_DE" : "en_US_POSIX")) + " " + item.unit } ?? l("Nicht angegeben", "Not entered") }
                return "• \(item.description) [\(kind(item.kind))]: \(value)"
            }
        }
        var result = [l("Arbeitspositionen", "Work line items"), l("Nur eingegebene Werte; keine durch KI ergänzten Messwerte.", "Entered facts only; no AI-added measurements.")]
        if !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result += ["", l("Ursprüngliche Notizen", "Original notes"), rawText]
        }
        if !reportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result += ["", l("Bearbeiteter Rapporttext", "Edited report text"), reportText]
        }
        result += lines(workItems)
        if let totals = try? RapportWorkTotals(items: workItems) {
            result += [l("Summe eingegebener Arbeitszeiten: ", "Total entered labor: ") + "\(totals.laborMinutes) min", l("Nicht ausgefüllte Positionen: ", "Unfilled entries: ") + String(totals.incompleteCount)]
            for category in [RapportWorkKind.material, .measurement] {
                for unit in Set(workItems.filter { $0.kind == category && $0.quantity != nil }.map(\.unit)).sorted() {
                    var value = totals.quantity(kind: category, unit: unit)
                    result.append(kind(category) + ": " + NSDecimalString(&value, Locale(identifier: german ? "de_DE" : "en_US_POSIX")) + " " + unit)
                }
            }
        }
        result += ["", l("GESPEICHERTE VERSIONEN", "SAVED REVISIONS")]
        for revision in revisions {
            result += ["", "\(l("Version", "Revision")) \(revision.number) · \(ISO8601DateFormatter().string(from: revision.at))", revision.content.customer, revision.content.location, revision.content.system]
            if !revision.content.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result += [l("Ursprüngliche Notizen", "Original notes"), revision.content.rawText]
            }
            if !revision.content.reportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result += [l("Bearbeiteter Rapporttext", "Edited report text"), revision.content.reportText]
            }
            result += lines(revision.content.workItems)
            for ack in acknowledgements where ack.revisionID == revision.id {
                result += [l("Lokale Bestätigung: ", "Local acknowledgement: ") + ack.name, ack.note, ISO8601DateFormatter().string(from: ack.at)]
            }
        }
        result += ["", latestIsAcknowledged ? l("Aktuelle gespeicherte Version lokal bestätigt.", "Current saved revision locally acknowledged.") : l("Aktueller Inhalt nicht bestätigt.", "Current content is not acknowledged."),
                   l("Bestätigung ist eine lokale Namenseingabe, keine digitale Signatur, Identitätsprüfung oder rechtssichere Abnahme. Zeitangaben stammen von der Geräteuhr. Frühere Bestätigungen gelten nur für die zugehörige Version.", "Acknowledgement is a local entered name, not a digital signature, identity verification or legally verified acceptance. Times come from the device clock. Earlier acknowledgements apply only to their associated revision.")]
        return result.joined(separator: "\n")
    }
}
