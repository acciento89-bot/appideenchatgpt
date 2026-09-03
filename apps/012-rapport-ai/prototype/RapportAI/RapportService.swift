import Foundation

protocol RapportGenerating {
    func generate(from draft: RapportDraft) async throws -> String
}

private enum RapportBackendConfiguration {
    static let endpoint = URL(string: "https://bqctetqraszsvknczjjr.supabase.co/functions/v1/generate-rapport")!
    static let publishableKey = "sb_publishable_g4PeQGT99Tz2ltwdAzyXrA_NoYDXsP9"
}

struct HybridRapportService: RapportGenerating {
    private let session: URLSession
    private let endpoint: URL
    private let apiKey: String

    init(session: URLSession = .shared) {
        self.init(
            session: session,
            endpoint: RapportBackendConfiguration.endpoint,
            apiKey: RapportBackendConfiguration.publishableKey
        )
    }

    init(session: URLSession, endpoint: URL, apiKey: String) {
        self.session = session
        self.endpoint = endpoint
        self.apiKey = apiKey
    }

    func generate(from draft: RapportDraft) async throws -> String {
        let trimmed = draft.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RapportError.emptyInput }

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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw RapportError.service("Der KI-Dienst ist gerade nicht erreichbar. Dein Text bleibt erhalten.")
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw RapportError.service("Der KI-Dienst ist gerade nicht erreichbar. Dein Text bleibt erhalten.")
        }
        guard let decoded = try? JSONDecoder().decode(RapportGenerationResponse.self, from: data),
              !decoded.report.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RapportError.invalidResponse
        }
        return decoded.report
    }
}
