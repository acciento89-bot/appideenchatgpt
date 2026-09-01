import Foundation

enum TradeCategory: String, Codable, CaseIterable, Identifiable {
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
    var trade: TradeCategory = .plumbingHeating
    var customer = ""
    var location = ""
    var system = ""
    var rawText = ""
    var reportText = ""
    var tone: RapportTone = .factual
    var createdAt = Date()
    var updatedAt = Date()

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
