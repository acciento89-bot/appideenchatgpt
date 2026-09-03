import Foundation

protocol RapportGenerating {
    func generate(from draft: RapportDraft) async throws -> String
}

struct HybridRapportService: RapportGenerating {
    private let session: URLSession
    private let endpoint: URL?
    private let apiKey: String?

    init(session: URLSession = .shared, bundle: Bundle = .main) {
        self.session = session
        endpoint = Self.configuredURL(for: "RAPPORT_API_URL", bundle: bundle)
        apiKey = Self.configuredValue(for: "RAPPORT_API_KEY", bundle: bundle)
    }

    func generate(from draft: RapportDraft) async throws -> String {
        let trimmed = draft.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RapportError.emptyInput }
        guard let endpoint, let apiKey else {
            return LocalRapportFormatter.format(draft)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(
            RapportGenerationRequest(
                rawText: trimmed,
                trade: draft.trade.title,
                customer: draft.customer,
                location: draft.location,
                system: draft.system,
                tone: draft.tone.rawValue
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw RapportError.service("Der KI-Dienst ist gerade nicht erreichbar. Dein Text bleibt erhalten.")
        }
        guard let decoded = try? JSONDecoder().decode(RapportGenerationResponse.self, from: data),
              !decoded.report.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RapportError.invalidResponse
        }
        return decoded.report
    }

    private static func configuredValue(for key: String, bundle: Bundle) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func configuredURL(for key: String, bundle: Bundle) -> URL? {
        guard let value = configuredValue(for: key, bundle: bundle) else { return nil }
        return URL(string: value)
    }
}

enum LocalRapportFormatter {
    static func format(_ draft: RapportDraft) -> String {
        var text = draft.rawText
            .replacingOccurrences(of: " äh ", with: " ", options: .caseInsensitive)
            .replacingOccurrences(of: " ähm ", with: " ", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let first = text.first { text.replaceSubrange(text.startIndex...text.startIndex, with: String(first).uppercased()) }
        if !text.hasSuffix(".") && !text.hasSuffix("!") && !text.hasSuffix("?") { text += "." }

        let context = [
            "Gewerk: \(draft.trade.title)",
            draft.system.isEmpty ? nil : "Anlage: \(draft.system)",
            draft.location.isEmpty ? nil : "Einsatzort: \(draft.location)"
        ].compactMap { $0 }.joined(separator: "\n")

        let heading: String
        switch draft.tone {
        case .factual: heading = "Arbeitsbericht"
        case .customerFriendly: heading = "Durchgeführte Arbeiten"
        case .insurance: heading = "Sachverhalts- und Leistungsdokumentation"
        }

        return [heading, context, text, "Hinweis: Der Rapport wurde digital erstellt und ist vor Verwendung fachlich zu prüfen."]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
