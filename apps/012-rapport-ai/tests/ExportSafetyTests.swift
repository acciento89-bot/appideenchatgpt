import Foundation

@main struct ExportSafetyTests {
    static func main() throws {
        var rawOnly = RapportDraft()
        rawOnly.rawText = "Manually entered only note: valve checked at customer site"
        rawOnly.reportText = ""
        for german in [false, true] {
            let text = rawOnly.structuredWorkText(german: german)
            precondition(text.contains(rawOnly.rawText), "current raw-only narrative must survive actual shared/PDF appendix")
            precondition(text.contains(german ? "Ursprüngliche Notizen" : "Original notes"), "entered notes must be labelled as original notes")
        }
        let first = try rawOnly.savingRevision(at: Date(timeIntervalSince1970: 1_800_000_000))
        var changed = first
        changed.rawText = "Later original note: no earlier details copied"
        changed.reportText = "Separate edited narrative"
        let second = try changed.preparingSave(preserving: first, at: Date(timeIntervalSince1970: 1_800_000_001))
        for german in [false, true] {
            let text = second.structuredWorkText(german: german)
            precondition(text.contains(rawOnly.rawText), "earlier raw-only revision notes must remain present in shared/PDF appendix")
            precondition(text.contains(changed.rawText) && text.contains(changed.reportText), "current original notes and edited narrative must both survive")
            precondition(text.contains(german ? "Version 1" : "Revision 1") && text.contains(german ? "Version 2" : "Revision 2"), "original notes must stay attached to saved versions")
        }
        print("PASS Rapport export safety: labelled current and saved original raw-only notes survive DE/EN shared and PDF appendix")
    }
}
