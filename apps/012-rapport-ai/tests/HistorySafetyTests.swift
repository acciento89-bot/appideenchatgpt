import Foundation

@main struct HistorySafetyTests {
    static func main() throws {
        var draft = RapportDraft()
        draft.reportText = "First"
        draft.workItems = [try .quantity(kind: .material, description: "A", amount: "0.1", unit: "m"), try .quantity(kind: .material, description: "B", amount: "0.2", unit: "m")]
        let at = Date(timeIntervalSince1970: 1_800_000_000)
        let first = try draft.savingRevision(at: at)
        let acknowledged = try first.acknowledging(revisionID: first.revisions[0].id, name: "Alex", note: "Reviewed", at: at)
        // A detail editor can remain open while a separate history sheet records acknowledgement.
        var staleEditor = first
        staleEditor.reportText = "Edited while history was open"
        staleEditor.revisions = []
        let merged = try staleEditor.preparingSave(preserving: acknowledged, at: at.addingTimeInterval(1))
        precondition(merged.revisions.count == 2 && merged.revisions[0] == acknowledged.revisions[0], "saving stale editor must preserve stored snapshots")
        precondition(merged.acknowledgements == acknowledged.acknowledgements && !merged.latestIsAcknowledged, "stale editor cannot erase or transfer acknowledgement")
        precondition(merged.structuredWorkText(german: false).contains("0.3 m"), "actual export contains exact grouped quantities")
        precondition(merged.structuredWorkText(german: true).contains("Material"), "German export translates kind labels")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let blocked = directory.appendingPathComponent("blocked")
        try Data("retain".utf8).write(to: blocked)
        do {
            try RapportArchive(url: blocked.appendingPathComponent("reports.json")).save(RapportArchiveSnapshot(reports: [merged], templates: []))
            fatalError("unwritable archive parent must fail")
        } catch {}
        let retained = try String(contentsOf: blocked, encoding: .utf8)
        precondition(retained == "retain", "write failure preserves existing path")
        print("PASS Rapport native integration safety: stale editor retains history/ack, exact grouped DEEN export, blocked destination preserved")
    }
}
