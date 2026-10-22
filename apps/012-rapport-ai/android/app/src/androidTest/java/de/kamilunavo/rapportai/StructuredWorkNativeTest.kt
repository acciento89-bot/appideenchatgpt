package de.kamilunavo.rapportai

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import de.kamilunavo.rapportai.data.WorkWorkspaceArchive
import de.kamilunavo.rapportai.model.*
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.math.BigDecimal

/** Actual free-user UI. No fixture injection, generation, entitlement changes or transactions. */
@RunWith(AndroidJUnit4::class)
class StructuredWorkNativeTest {
    @get:Rule val ui = createAndroidComposeRule<MainActivity>()
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext
    private val device get() = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
    private val customer = "Wartung Musterhaus"
    private val notes = "Ursprüngliche Prüfung ÄÖÜ Δ Σ – Heizkreis geprüft.\n" + (1..12).joinToString("\n") { "Messprotokoll $it: Nur vor Ort eingegebene Feststellungen; keine automatisch ergänzten Werte." }
    private val firstText = "Heizkreis geprüft und Wartung dokumentiert."
    private val secondText = "Heizkreis geprüft; zweite gespeicherte Fassung mit Ergänzung."
    private fun s(id: Int) = context.getString(id)
    private fun button(value: String): SemanticsNodeInteraction {
        val match=hasText(value) and hasClickAction()
        val modal=match and hasAnyAncestor(isDialog())
        return if(ui.onAllNodes(modal).fetchSemanticsNodes().size==1) ui.onNode(modal) else ui.onNode(match)
    }
    private fun closeDialog(title: String) {
        ui.onNode(hasText(s(R.string.work_close)) and hasClickAction() and hasAnyAncestor(isDialog() and hasAnyDescendant(hasText(title)))).performClick()
        ui.waitForIdle()
    }
    private fun field(value: String) = ui.onNode(hasText(value) and hasSetTextAction())
    private fun click(value: String) { val n=button(value); if (!n.isDisplayed()) n.performScrollTo(); n.assertIsDisplayed().assertIsEnabled().performClick(); ui.waitForIdle() }
    private fun enter(label: String, value: String) { val n=field(label); if (!n.isDisplayed()) n.performScrollTo(); n.performTextReplacement(value); ui.waitForIdle() }
    private fun archive() = WorkWorkspaceArchive(File(context.filesDir,"RapportAI/workspace.json")).load()
    private fun capture(name: String) { ui.waitForIdle(); val f=File(context.filesDir,"native-proof/$name.png"); f.parentFile!!.mkdirs(); assertTrue(device.takeScreenshot(f)) }
    private fun startup() {
        assertEquals(35,Build.VERSION.SDK_INT)
        assertEquals("1",device.executeShellCommand("getprop ro.kernel.qemu").trim())
        assertEquals("de.kamilunavo.rapportai",context.packageName)
        assertEquals("1.2.0",context.packageManager.getPackageInfo(context.packageName,0).versionName)
        // A clean, account-free Google APIs device has no billing service. Acknowledge only this
        // exact known notice; never dismiss crashes, permission dialogs or unknown application errors.
        ui.waitUntil(10000) { ui.onAllNodesWithText("Google Play Billing ist gerade nicht verfügbar.").fetchSemanticsNodes().isNotEmpty() }
        ui.onNodeWithText("Google Play Billing ist gerade nicht verfügbar.").assertIsDisplayed()
        click("OK")
    }
    private fun add(kind: Int, label: String, amount: String, unit: String? = null, rotate: Boolean = false) {
        click(s(R.string.work_add)); click(s(kind)); enter(s(R.string.work_description),label)
        val amountLabel=s(if(kind==R.string.work_labor) R.string.work_minutes else R.string.work_quantity)
        enter(amountLabel,"-1"); button(s(R.string.work_save)).assertIsNotEnabled()
        enter(amountLabel,""); button(s(R.string.work_save)).assertIsNotEnabled()
        enter(amountLabel,amount)
        if(unit!=null) enter(s(R.string.work_unit),unit)
        if(rotate) { ui.activityRule.scenario.recreate(); ui.waitForIdle(); field(amountLabel).assertTextContains(amount); field(s(R.string.work_description)).assertTextContains(label) }
        click(s(R.string.work_save))
    }
    private fun openRevision(number: Int) {
        val n=ui.onNode(hasText(s(R.string.work_revision)+" $number ·",substring=true) and hasClickAction())
        if(!n.isDisplayed()) n.performScrollTo(); n.performClick(); ui.waitForIdle()
    }
    @Test fun positionsTemplateAcknowledgementRevisionAndPdfThroughRealUi() {
        try { exercisePositionsTemplateAndPdf() } catch(t: Throwable) { runCatching { capture("failure-screen"); File(context.filesDir,"native-proof/failure-semantics.txt").writeText(ui.onAllNodes(isRoot(),useUnmergedTree=true).printToString()) }; throw t }
    }
    private fun exercisePositionsTemplateAndPdf() {
        startup()
        enter("Kunde / Auftraggeber",customer); enter("Einsatzort","Musterstraße 12"); enter("Objekt / Anlage / Bauteil","Heizkreis EG")
        enter("Notizen vom Einsatz",notes)
        click(s(R.string.work_title)); enter(s(R.string.work_narrative),firstText)
        add(R.string.work_labor,"Wartung", "75",rotate=true)
        add(R.string.work_labor,"Dokumentation", "45")
        add(R.string.work_material,"Rohr Abschnitt A", "0.1","m")
        add(R.string.work_material,"Rohr Abschnitt B", "0.2","m")
        add(R.string.work_measurement,"Rohrdurchmesser", "25","mm")
        add(R.string.work_measurement,"Anlagendruck", "1.5","bar")
        ui.onNodeWithText(context.getString(R.string.work_total_minutes,120)).performScrollTo().assertIsDisplayed()
        capture("01-entered-positions")
        click(s(R.string.work_save_template)); enter(s(R.string.work_name),"Wartung ohne Kundendaten"); click(s(R.string.work_save))
        click(s(R.string.work_save)); assertEquals(1,archive().reports.single().revisions.size)
        click(s(R.string.work_save)); assertEquals(1,archive().reports.single().revisions.size)
        val first=archive().reports.single(); assertEquals(120,WorkTotals(first.workItems).laborMinutes)
        assertEquals(0,BigDecimal("0.3").compareTo(WorkTotals(first.workItems).quantity(WorkKind.MATERIAL,"m")))
        click(s(R.string.work_history)); openRevision(1); click(s(R.string.work_record_ack))
        enter(s(R.string.work_name),"Alex Muster"); enter(s(R.string.work_note),"Vor Ort geprüft Ä Δ Σ")
        button(s(R.string.work_save)).assertIsNotEnabled(); ui.onNode(isToggleable()).performClick(); click(s(R.string.work_save))
        ui.onNodeWithText("Alex Muster",substring=true).performScrollTo().assertIsDisplayed(); capture("02-local-acknowledgement")
        closeDialog(s(R.string.work_revision)+" 1"); closeDialog(s(R.string.work_history))
        enter(s(R.string.work_narrative),secondText); click(s(R.string.work_save))
        val saved=archive().reports.single(); assertEquals(2,saved.revisions.size); assertEquals(firstText,saved.revisions.first().content.reportText)
        assertEquals(secondText,saved.revisions.last().content.reportText); assertEquals(1,saved.acknowledgements.size)
        assertEquals(saved.revisions.first().id,saved.acknowledgements.single().revisionID); assertFalse(saved.latestIsAcknowledged)
        click(s(R.string.work_history)); openRevision(2)
        ui.onAllNodesWithText("Alex Muster",substring=true).assertCountEquals(0); capture("03-new-unacknowledged-revision")
        closeDialog(s(R.string.work_revision)+" 2"); closeDialog(s(R.string.work_history)); click(s(R.string.work_back))
        click(s(R.string.work_pdf))
        // The actual production button saved then generated the real PDF and launched Android's chooser.
        assertTrue(device.wait(androidx.test.uiautomator.Until.hasObject(androidx.test.uiautomator.By.pkg("android")),10000))
        device.pressBack(); ui.waitForIdle()
        val files=File(context.filesDir,"reports").listFiles()!!.filter { it.extension=="pdf" }; assertEquals(1,files.size)
        val dir=File(context.filesDir,"native-proof").apply { mkdirs() }; files.single().copyTo(File(dir,"actual-report.pdf"))
        PdfRenderer(ParcelFileDescriptor.open(files.single(),ParcelFileDescriptor.MODE_READ_ONLY)).use { renderer ->
            assertTrue(renderer.pageCount in 2..12)
            File(dir,"pdf-page-count.txt").writeText(renderer.pageCount.toString())
            for(i in 0 until renderer.pageCount) renderer.openPage(i).use { page ->
                val bitmap=Bitmap.createBitmap(page.width*2,page.height*2,Bitmap.Config.ARGB_8888)
                bitmap.eraseColor(android.graphics.Color.WHITE); page.render(bitmap,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                File(dir,"pdf-page-${i+1}.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }; bitmap.recycle()
            }
        }
        ui.onNodeWithContentDescription("Neuen Rapport beginnen").performClick()
        click(s(R.string.work_title)); click(s(R.string.work_templates)); click(s(R.string.work_use_template))
        ui.onNodeWithText(context.getString(R.string.work_incomplete,6)).performScrollTo().assertIsDisplayed()
        capture("04-blank-template")
        assertEquals(1,archive().reports.size); assertEquals(1,archive().templates.size)
        assertTrue(archive().templates.single().instantiate().all { it.minutes==null && it.quantity==null })
        assertEquals(0,context.getSharedPreferences("rapport_ai",0).getInt("usage_count",0))
        assertFalse(context.getSharedPreferences("rapport_ai",0).getBoolean("pro_active",false))
    }
    @Test fun coldReopenRetainsExactHistoryAndTemplate() {
        startup(); click("Rapporte"); ui.onNodeWithText(customer).assertIsDisplayed(); click("Bearbeiten")
        click(s(R.string.work_title)); click(s(R.string.work_history)); openRevision(1)
        ui.onNodeWithText("Alex Muster",substring=true).performScrollTo().assertIsDisplayed(); capture("05-cold-reopened")
        val saved=archive().reports.single(); assertEquals(2,saved.revisions.size); assertEquals(notes,saved.rawText)
        assertEquals(firstText,saved.revisions.first().content.reportText); assertEquals(secondText,saved.reportText)
        assertEquals(1,saved.acknowledgements.size); assertEquals(1,archive().templates.size)
        assertEquals(0,context.getSharedPreferences("rapport_ai",0).getInt("usage_count",0))
    }
}
