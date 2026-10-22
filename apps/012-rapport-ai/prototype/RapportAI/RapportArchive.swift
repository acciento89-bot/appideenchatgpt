import Foundation

struct RapportArchiveSnapshot: Equatable {
    var reports: [RapportDraft]
    var templates: [RapportWorkTemplate]
}
struct RapportArchive {
    let url: URL
    private struct Envelope: Codable { let schemaVersion: Int; let reports: [RapportDraft]; let templates: [RapportWorkTemplate] }
    func load() throws -> RapportArchiveSnapshot {
        guard FileManager.default.fileExists(atPath: url.path) else { return RapportArchiveSnapshot(reports: [], templates: []) }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let result: RapportArchiveSnapshot
        if data.first(where: { ![9,10,13,32].contains($0) }) == 91 {
            // The published app stores ISO8601 arrays. Read without touching the original file.
            decoder.dateDecodingStrategy = .iso8601
            result = RapportArchiveSnapshot(reports: try decoder.decode([RapportDraft].self, from: data), templates: [])
        } else {
            // v1 envelope uses exact numeric epoch dates; legacy values retain their instant.
            decoder.dateDecodingStrategy = .secondsSince1970
            let envelope = try decoder.decode(Envelope.self, from: data)
            guard envelope.schemaVersion == 1 else { throw RapportWorkError.unsupportedVersion }
            result = RapportArchiveSnapshot(reports: envelope.reports, templates: envelope.templates)
        }
        try validate(result); return result
    }
    func save(_ snapshot: RapportArchiveSnapshot) throws {
        _ = try load()
        try validate(snapshot)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(Envelope(schemaVersion: 1, reports: snapshot.reports, templates: snapshot.templates))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
    private func validate(_ snapshot: RapportArchiveSnapshot) throws {
        guard Set(snapshot.reports.map(\.id)).count == snapshot.reports.count, Set(snapshot.templates.map(\.id)).count == snapshot.templates.count else { throw RapportWorkError.invalidArchive }
        try snapshot.reports.forEach { try $0.validateWorkHistory() }
        try snapshot.templates.forEach { try $0.validate() }
    }
}
