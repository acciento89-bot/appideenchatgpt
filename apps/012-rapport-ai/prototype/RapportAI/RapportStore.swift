import Foundation
import SwiftUI

@MainActor
final class RapportStore: ObservableObject {
    @Published private(set) var reports: [RapportDraft] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("RapportAI", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("reports.json")

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func save(_ report: RapportDraft) {
        var updated = report
        updated.updatedAt = Date()
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = updated
        } else {
            reports.insert(updated, at: 0)
        }
        reports.sort { $0.updatedAt > $1.updatedAt }
        persist()
    }

    func delete(at offsets: IndexSet) {
        reports.remove(atOffsets: offsets)
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([RapportDraft].self, from: data) else { return }
        reports = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func persist() {
        guard let data = try? encoder.encode(reports) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

@MainActor
final class UsageMeter: ObservableObject {
    @Published private(set) var usedThisMonth = 0
    let freeLimit = 5

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        refreshPeriod()
    }

    var remaining: Int { max(0, freeLimit - usedThisMonth) }
    var mayGenerate: Bool { usedThisMonth < freeLimit }

    func recordGeneration() {
        refreshPeriod()
        usedThisMonth += 1
        defaults.set(usedThisMonth, forKey: "rapport.usage.count")
    }

    private func refreshPeriod(now: Date = Date()) {
        let components = calendar.dateComponents([.year, .month], from: now)
        let period = "\(components.year ?? 0)-\(components.month ?? 0)"
        if defaults.string(forKey: "rapport.usage.period") != period {
            defaults.set(period, forKey: "rapport.usage.period")
            defaults.set(0, forKey: "rapport.usage.count")
        }
        usedThisMonth = defaults.integer(forKey: "rapport.usage.count")
    }
}
