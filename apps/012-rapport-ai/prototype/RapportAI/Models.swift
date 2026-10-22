import Foundation

enum TradeCategory: String, Codable, CaseIterable, Identifiable {
    case general
    case plumbingHeating
    case electrical
    case painting
    case carpentry
    case roofing
    case construction
    case facility
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "Allgemeines Handwerk"
        case .plumbingHeating: "Sanitär & Heizung"
        case .electrical: "Elektro"
        case .painting: "Maler & Lackierer"
        case .carpentry: "Tischler & Schreiner"
        case .roofing: "Dach & Fassade"
        case .construction: "Bau & Ausbau"
        case .facility: "Hausmeisterservice"
        case .other: "Sonstiges Gewerk"
        }
    }
}

enum RapportTone: String, Codable, CaseIterable, Identifiable {
    case factual
    case customerFriendly
    case insurance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .factual: "Sachlich"
        case .customerFriendly: "Kundenfreundlich"
        case .insurance: "Dokumentation"
        }
    }
}

struct RapportDraft: Identifiable, Codable, Hashable {
    var id = UUID()
    var trade: TradeCategory = .general
    var customer = ""
    var location = ""
    var system = ""
    var rawText = ""
    var reportText = ""
    var tone: RapportTone = .factual
    var createdAt = Date()
    var updatedAt = Date()
    var workItems: [RapportWorkItem] = []
    var revisions: [RapportRevision] = []
    var acknowledgements: [RapportAcknowledgement] = []

    var displayTitle: String {
        if !customer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return customer }
        if !system.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return system }
        return "Neuer Arbeitsrapport"
    }
}

struct RapportGenerationRequest: Encodable {
    let rawText: String
    let trade: String
    let customer: String
    let location: String
    let system: String
    let tone: String
}

struct RapportGenerationResponse: Decodable {
    let report: String
}

enum RapportError: LocalizedError {
    case emptyInput
    case invalidResponse
    case service(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput: "Bitte zuerst den Baustellenbericht einsprechen oder eingeben."
        case .invalidResponse: "Der Rapport konnte nicht gelesen werden. Bitte erneut versuchen."
        case .service(let message): message
        }
    }
}


extension RapportDraft {
    private enum CodingKeys: String, CodingKey {
        case id, trade, customer, location, system, rawText, reportText, tone, createdAt, updatedAt
        case workItems, revisions, acknowledgements
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        id = try c.decode(UUID.self, forKey: .id); trade = try c.decode(TradeCategory.self, forKey: .trade)
        customer = try c.decode(String.self, forKey: .customer); location = try c.decode(String.self, forKey: .location)
        system = try c.decode(String.self, forKey: .system); rawText = try c.decode(String.self, forKey: .rawText)
        reportText = try c.decode(String.self, forKey: .reportText); tone = try c.decode(RapportTone.self, forKey: .tone)
        createdAt = try c.decode(Date.self, forKey: .createdAt); updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        workItems = c.contains(.workItems) ? try c.decode([RapportWorkItem].self, forKey: .workItems) : []
        acknowledgements = c.contains(.acknowledgements) ? try c.decode([RapportAcknowledgement].self, forKey: .acknowledgements) : []
        if c.contains(.revisions) { revisions = try c.decode([RapportRevision].self, forKey: .revisions) }
        else { revisions = [RapportRevision(number: 1, at: updatedAt, content: RapportRevisionContent(draft: self))] }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(trade, forKey: .trade)
        try c.encode(customer, forKey: .customer); try c.encode(location, forKey: .location)
        try c.encode(system, forKey: .system); try c.encode(rawText, forKey: .rawText)
        try c.encode(reportText, forKey: .reportText); try c.encode(tone, forKey: .tone)
        try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(workItems, forKey: .workItems); try c.encode(revisions, forKey: .revisions); try c.encode(acknowledgements, forKey: .acknowledgements)
    }
}
