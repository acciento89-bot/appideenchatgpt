import Foundation

@main struct StructuredWorkTests {
    static func check(_ value: Bool, _ message: String) { precondition(value, message) }
    static func rejects(_ action: () throws -> Void, _ message: String) {
        do { try action(); fatalError(message) } catch {}
    }
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("reports.json")
        let archive = RapportArchive(url: file)
        // Protect existing bytes before testing convenience domain operations.
        for corrupt in ["broken", "{\"schemaVersion\":99,\"reports\":[],\"templates\":[]}", "[] trailing"] {
            try Data(corrupt.utf8).write(to: file)
            rejects({ _ = try archive.load() }, "unreadable/future/trailing archive cannot load")
            rejects({ try archive.save(RapportArchiveSnapshot(reports: [], templates: [])) }, "cannot overwrite unreadable archive")
            check(try Data(contentsOf: file) == Data(corrupt.utf8), "original corrupt bytes retained")
        }
        let legacyJSON = """
        [{"id":"11111111-1111-4111-8111-111111111111","trade":"plumbingHeating","customer":"Legacy customer","location":"Basement","system":"Boiler","rawText":"Entered facts","reportText":"Original narrative","tone":"factual","createdAt":"2026-10-01T08:00:00Z","updatedAt":"2026-10-02T09:00:00Z"}]
        """
        try Data(legacyJSON.utf8).write(to: file)
        let originalBytes = try Data(contentsOf: file)
        let legacy = try archive.load()
        check(try Data(contentsOf: file) == originalBytes, "legacy load never rewrites file")
        check(legacy.reports.count == 1 && legacy.templates.isEmpty, "legacy data migrates in memory")
        let old = legacy.reports[0]
        check(old.id.uuidString == "11111111-1111-4111-8111-111111111111" && old.reportText == "Original narrative", "legacy ID and original narrative retained")
        check(old.revisions.count == 1 && old.revisions[0].content.reportText == old.reportText, "legacy original becomes independent first revision")
        let laborA = try RapportWorkItem.labor(description: "Install", minutes: 75)
        let laborB = try RapportWorkItem.labor(description: "Check", minutes: 45)
        let a = try RapportWorkItem.quantity(kind: .material, description: "Pipe A", amount: "0,1", unit: "m")
        let b = try RapportWorkItem.quantity(kind: .material, description: "Pipe B", amount: "0.2", unit: "m")
        let mm = try RapportWorkItem.quantity(kind: .measurement, description: "Depth", amount: "25", unit: "mm")
        let totals = try RapportWorkTotals(items: [laborA, laborB, a, b, mm])
        check(totals.laborMinutes == 120, "75 + 45 minutes exact")
        check(totals.quantity(kind: .material, unit: "m") == Decimal(string: "0.3")!, "0.1 + 0.2 decimal exact")
        check(totals.quantity(kind: .measurement, unit: "mm") == Decimal(25), "unlike units and kinds remain separate")
        for invalid in ["", "NaN", "Infinity", "-1", "1.2345", "1000000000"] {
            rejects({ _ = try RapportWorkItem.quantity(kind: .material, description: "X", amount: invalid, unit: "m") }, "invalid quantity rejected")
        }
        rejects({ _ = try RapportWorkItem.labor(description: "X", minutes: -1) }, "negative duration rejected")
        rejects({ _ = try RapportWorkItem.labor(description: "X", minutes: 1000001) }, "duration limit checked")
        let template = try RapportWorkTemplate(name: "Heating service", trade: .plumbingHeating, items: [laborA, a, mm])
        let blank = template.instantiate()
        check(Set(blank.map(\.id)).isDisjoint(with: Set([laborA.id, a.id, mm.id])), "template copies use fresh IDs")
        check(blank.allSatisfy { $0.minutes == nil && $0.quantity == nil }, "template never copies completed facts")
        var draft = old
        draft.reportText = "Edited narrative"
        draft.workItems = [laborA, laborB, a, b, mm]
        let at = Date(timeIntervalSince1970: 1_800_000_000)
        let changed = try draft.savingRevision(at: at)
        check(changed.revisions.count == 2 && changed.revisions[0].content.reportText == "Original narrative", "new revision retains legacy original")
        let unchanged = try changed.savingRevision(at: at.addingTimeInterval(1))
        check(unchanged.revisions.count == 2, "unchanged save creates no duplicate revision")
        let acknowledged = try changed.acknowledging(revisionID: changed.revisions[1].id, name: "Alex", note: "Reviewed entered work", at: at)
        check(acknowledged.latestIsAcknowledged, "explicit acknowledgement bound to saved revision")
        var edited = acknowledged
        edited.workItems[0] = try RapportWorkItem.labor(description: "Install corrected", minutes: 90)
        let later = try edited.savingRevision(at: at.addingTimeInterval(2))
        check(!later.latestIsAcknowledged && later.acknowledgements.count == 1, "new work never inherits old acknowledgement")
        check(later.revisions[1].content.workItems[0].minutes == 75, "snapshots remain independent after edit")
        let snapshot = RapportArchiveSnapshot(reports: [later], templates: [template])
        try archive.save(snapshot)
        check(try archive.load() == snapshot, "cold reload preserves report versions/templates/acknowledgements")
        let validBytes = try Data(contentsOf: file)
        rejects({ try archive.save(RapportArchiveSnapshot(reports: [later, later], templates: [template])) }, "duplicate report identities rejected")
        check(try Data(contentsOf: file) == validBytes, "rejected save leaves prior valid bytes intact")
        try Data("broken after successful load".utf8).write(to: file)
        rejects({ try archive.save(snapshot) }, "external replacement rejected before overwrite")
        check(try Data(contentsOf: file) == Data("broken after successful load".utf8), "external replacement preserved")
        let textEN = later.structuredWorkText(german: false)
        let textDE = later.structuredWorkText(german: true)
        check(textEN.contains("Alex") && textEN.contains("75") && textEN.contains("not a digital signature"), "export preserves revision-bound acknowledgement truth")
        check(textDE.contains("Arbeitspositionen") && textDE.contains("mm"), "German factual worksheet contains entered units")
        print("PASS Rapport structured work: corrupt protection, legacy preservation, exact totals, blank templates, independent revisions, bound acknowledgement, atomic reload and DE/EN export")
    }
}
