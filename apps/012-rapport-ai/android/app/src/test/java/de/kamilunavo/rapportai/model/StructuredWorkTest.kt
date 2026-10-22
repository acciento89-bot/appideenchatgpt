package de.kamilunavo.rapportai.model

import de.kamilunavo.rapportai.data.WorkWorkspaceArchive
import org.junit.Assert.*
import org.junit.Test
import java.math.BigDecimal
import java.nio.file.Files

class StructuredWorkTest {
    @Test fun originalNotesRemainInCurrentAndSavedRevisionExports() {
        val rawOnly = Rapport(rawText = "Entered original note: valve checked", reportText = "")
        for (german in listOf(false, true)) {
            val text = rawOnly.structuredWorkText(german)
            assertTrue("current raw-only notes must survive actual shared/PDF appendix", text.contains(rawOnly.rawText))
            assertTrue(text.contains(if (german) "Ursprüngliche Notizen" else "Original notes"))
        }
        val first = rawOnly.savingRevision(1800000000000)
        val changed = first.copy(rawText = "Later entered note", reportText = "Separate edited narrative")
        val second = changed.preparingSave(first, 1800000000001)
        for (german in listOf(false, true)) {
            val text = second.structuredWorkText(german)
            assertTrue("old raw-only revision must retain its original notes", text.contains(rawOnly.rawText))
            assertTrue(text.contains(changed.rawText) && text.contains(changed.reportText))
            assertTrue(text.contains(if (german) "Version 1" else "Revision 1"))
            assertTrue(text.contains(if (german) "Version 2" else "Revision 2"))
        }
    }

    @Test fun blankTemplateQuantitiesAreNeverExportedAsZeroFacts() {
        val draft = Rapport(workItems = listOf(WorkItem.blank(WorkKind.MATERIAL, "Pipe", "m")))
        assertEquals(1, WorkTotals(draft.workItems).incompleteCount)
        assertFalse(draft.structuredWorkText(false).contains("Material: 0 m"))
        assertFalse(draft.structuredWorkText(true).contains("Material: 0 m"))
    }

    @Test fun corruptExistingBytesNeverGetReplacedAndLegacyFactsSurvive() {
        val directory = Files.createTempDirectory("rapport-work").toFile()
        try {
            val file = directory.resolve("workspace.json")
            val legacy = """[{"id":"11111111-1111-4111-8111-111111111111","trade":"PLUMBING_HEATING","customer":"Legacy customer","location":"Basement","system":"Boiler","rawText":"Entered facts","reportText":"Original narrative","tone":"FACTUAL","createdAt":1790841600000,"updatedAt":1790931600000}]"""
            val archive = WorkWorkspaceArchive(file) { legacy }
            for (corrupt in listOf("broken", "{\"schemaVersion\":99,\"reports\":[],\"templates\":[]}", "[] trailing")) {
                file.writeText(corrupt)
                assertThrows(Exception::class.java) { archive.load() }
                assertThrows(Exception::class.java) { archive.save(WorkWorkspace(emptyList(), emptyList())) }
                assertEquals(corrupt, file.readText())
            }
            file.delete()
            val loaded = archive.load()
            assertFalse(file.exists())
            val old = loaded.reports.single()
            assertEquals("11111111-1111-4111-8111-111111111111", old.id)
            assertEquals(1790841600000, old.createdAt)
            assertEquals("Original narrative", old.revisions.single().content.reportText)
            archive.save(loaded)
            assertEquals(loaded, archive.load())
            val before = file.readText()
            assertThrows(Exception::class.java) { archive.save(loaded.copy(reports = listOf(old, old))) }
            assertEquals(before, file.readText())
            file.writeText("replaced after load")
            assertThrows(Exception::class.java) { archive.save(loaded) }
            assertEquals("replaced after load", file.readText())
        } finally { directory.deleteRecursively() }
    }

    @Test fun exactEnteredTotalsAndBlankPrivateTemplates() {
        val labor = WorkItem.labor("Install", 75)
        val check = WorkItem.labor("Check", 45)
        val a = WorkItem.quantity(WorkKind.MATERIAL, "Pipe A", "0,1", "m")
        val b = WorkItem.quantity(WorkKind.MATERIAL, "Pipe B", "0.2", "m")
        val mm = WorkItem.quantity(WorkKind.MEASUREMENT, "Depth", "25", "mm")
        val totals = WorkTotals(listOf(labor, check, a, b, mm))
        assertEquals(120, totals.laborMinutes)
        assertTrue(Rapport(workItems = listOf(a, b)).structuredWorkText(false).contains("0.3 m"))
        assertEquals(0, totals.quantity(WorkKind.MATERIAL, "m").compareTo(BigDecimal("0.3")))
        assertEquals(0, totals.quantity(WorkKind.MEASUREMENT, "mm").compareTo(BigDecimal("25")))
        for (bad in listOf("", "NaN", "Infinity", "-1", "1.2345", "1000000000")) {
            assertThrows(Exception::class.java) { WorkItem.quantity(WorkKind.MATERIAL, "X", bad, "m") }
        }
        assertThrows(Exception::class.java) { WorkItem.labor("X", -1) }
        assertThrows(Exception::class.java) { WorkItem.labor("X", 1000001) }
        val template = WorkTemplate(name = "Heating service", trade = Trade.PLUMBING_HEATING, items = listOf(labor, a, mm))
        val blank = template.instantiate()
        assertTrue(blank.none { it.id in listOf(labor.id, a.id, mm.id) })
        assertTrue(blank.all { it.minutes == null && it.quantity == null })
    }

    @Test fun immutableRevisionAndAcknowledgementNeverFollowLaterEdits() {
        val at = 1800000000000L
        val first = Rapport(reportText = "Original narrative", workItems = listOf(WorkItem.labor("Install", 75))).savingRevision(at)
        val acknowledged = first.acknowledging(first.revisions.single().id, "Alex", "Reviewed entered work", at)
        assertTrue(acknowledged.latestIsAcknowledged)
        val stale = first.copy(reportText = "Stale editor", revisions = emptyList()).preparingSave(acknowledged, at + 1)
        assertEquals(2, stale.revisions.size)
        assertEquals(acknowledged.revisions.first(), stale.revisions.first())
        assertEquals(acknowledged.acknowledgements, stale.acknowledgements)
        assertFalse(stale.latestIsAcknowledged)
        val later = acknowledged.copy(reportText = "Changed", workItems = listOf(WorkItem.labor("Corrected", 90))).savingRevision(at + 1)
        assertEquals(2, later.revisions.size)
        assertEquals(75, later.revisions.first().content.workItems.single().minutes)
        assertFalse(later.latestIsAcknowledged)
        assertEquals(1, later.acknowledgements.size)
        assertEquals(2, later.savingRevision(at + 2).revisions.size)
        assertTrue(later.structuredWorkText(false).contains("not a digital signature"))
        assertTrue(later.structuredWorkText(false).contains("Alex"))
        assertTrue(later.structuredWorkText(true).contains("Arbeitspositionen"))
    }
}
