import Foundation
import SwiftUI

@MainActor
final class RapportStore: ObservableObject {
    @Published private(set) var reports: [RapportDraft] = []
    @Published private(set) var templates: [RapportWorkTemplate] = []
    @Published private(set) var loadBlocked = false
    @Published var errorMessage: String?
    private let archive: RapportArchive

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        archive = RapportArchive(url: base.appendingPathComponent("RapportAI/reports.json"))
        reload()
    }
    func reload() {
        do {
            let snapshot = try archive.load()
            reports = snapshot.reports.sorted { $0.updatedAt > $1.updatedAt }
            templates = snapshot.templates
            loadBlocked = false; errorMessage = nil
        } catch { loadBlocked = true; errorMessage = "work.loadError" }
    }
    @discardableResult func save(_ report: RapportDraft) -> RapportDraft? {
        guard !loadBlocked else { errorMessage = "work.loadError"; return nil }
        guard !report.reportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !report.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !report.workItems.isEmpty else { errorMessage = "work.empty"; return nil }
        do {
            let updated = try report.preparingSave(preserving: reports.first { $0.id == report.id })
            var next = reports
            if let index = next.firstIndex(where: { $0.id == updated.id }) { next[index] = updated }
            else { next.insert(updated, at: 0) }
            return persist(RapportArchiveSnapshot(reports: next, templates: templates)) ? updated : nil
        } catch { errorMessage = "work.invalid"; return nil }
    }
    func delete(at offsets: IndexSet) { _ = deleteReports(offsets.compactMap { reports.indices.contains($0) ? reports[$0].id : nil }) }
    @discardableResult func deleteReports(_ ids: [UUID]) -> Bool { persist(RapportArchiveSnapshot(reports: reports.filter { !ids.contains($0.id) }, templates: templates)) }
    @discardableResult func saveTemplate(_ template: RapportWorkTemplate) -> Bool {
        do { try template.validate() } catch { errorMessage = "work.invalid"; return false }
        let next = templates.filter { $0.id != template.id } + [template]
        return persist(RapportArchiveSnapshot(reports: reports, templates: next))
    }
    @discardableResult func deleteTemplate(_ id: UUID) -> Bool { persist(RapportArchiveSnapshot(reports: reports, templates: templates.filter { $0.id != id })) }
    func acknowledge(reportID: UUID, revisionID: UUID, name: String, note: String) -> Bool {
        guard let index = reports.firstIndex(where: { $0.id == reportID }) else { errorMessage = "work.saveError"; return false }
        do {
            var next = reports
            next[index] = try next[index].acknowledging(revisionID: revisionID, name: name, note: note)
            return persist(RapportArchiveSnapshot(reports: next, templates: templates))
        } catch { errorMessage = "work.invalid"; return false }
    }
    private func persist(_ snapshot: RapportArchiveSnapshot) -> Bool {
        guard !loadBlocked else { errorMessage = "work.loadError"; return false }
        do {
            try archive.save(snapshot)
            reports = snapshot.reports.sorted { $0.updatedAt > $1.updatedAt }
            templates = snapshot.templates
            errorMessage = nil
            return true
        } catch { errorMessage = "work.saveError"; return false }
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
