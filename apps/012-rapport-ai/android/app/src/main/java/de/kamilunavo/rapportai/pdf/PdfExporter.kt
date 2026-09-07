package de.kamilunavo.rapportai.pdf

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import de.kamilunavo.rapportai.model.CompanyProfile
import de.kamilunavo.rapportai.model.Rapport
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object PdfExporter {
    private const val PAGE_WIDTH = 595
    private const val PAGE_HEIGHT = 842
    private const val LEFT = 46f
    private const val RIGHT = 549f
    private const val TOP = 48f
    private const val BOTTOM = 790f

    fun create(context: Context, report: Rapport, profile: CompanyProfile): File {
        val directory = File(context.filesDir, "reports").apply { mkdirs() }
        val safeName = report.displayTitle.replace(Regex("[^A-Za-z0-9ÄÖÜäöüß_-]"), "_").take(40)
        val file = File(directory, "Rapport_${safeName}_${report.updatedAt}.pdf")
        val document = PdfDocument()
        val bodyLines = wrap(report.reportText.ifBlank { report.rawText }, 88)
        var pageNumber = 1
        var index = 0

        while (index < bodyLines.size || pageNumber == 1) {
            val page = document.startPage(PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, pageNumber).create())
            val canvas = page.canvas
            var y = drawHeader(canvas, report, profile, pageNumber)
            while (index < bodyLines.size && y < BOTTOM - 72f) {
                y = drawBodyLine(canvas, bodyLines[index], y)
                index++
            }
            if (index >= bodyLines.size) drawSignatures(canvas)
            drawFooter(canvas, pageNumber)
            document.finishPage(page)
            pageNumber++
        }
        FileOutputStream(file).use(document::writeTo)
        document.close()
        return file
    }

    private fun drawHeader(canvas: Canvas, report: Rapport, profile: CompanyProfile, page: Int): Float {
        val navy = Color.rgb(7, 17, 31)
        val cyan = Color.rgb(40, 215, 229)
        val orange = Color.rgb(255, 138, 50)
        val title = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = navy; textSize = 22f; typeface = Typeface.DEFAULT_BOLD }
        val label = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.DKGRAY; textSize = 8f; typeface = Typeface.DEFAULT_BOLD }
        val value = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = navy; textSize = 10f }

        canvas.drawRect(0f, 0f, PAGE_WIDTH.toFloat(), 15f, Paint().apply { color = cyan })
        canvas.drawRect(0f, 15f, PAGE_WIDTH.toFloat(), 21f, Paint().apply { color = orange })
        canvas.drawText(profile.companyName.ifBlank { "RAPPORT AI" }, LEFT, TOP + 13f, title)
        if (profile.ownerName.isNotBlank()) canvas.drawText(profile.ownerName, LEFT, TOP + 30f, value)
        val companyLine = listOf(profile.address, profile.phone, profile.email).filter(String::isNotBlank).joinToString(" · ")
        if (companyLine.isNotBlank()) canvas.drawText(companyLine.take(92), LEFT, TOP + 44f, value)

        if (profile.logoPath != null) runCatching { BitmapFactory.decodeFile(profile.logoPath) }.getOrNull()?.let { bitmap ->
            val ratio = bitmap.width.toFloat() / bitmap.height.coerceAtLeast(1)
            val height = 42f
            canvas.drawBitmap(bitmap, null, android.graphics.RectF(RIGHT - height * ratio, TOP - 5f, RIGHT, TOP - 5f + height), Paint(Paint.ANTI_ALIAS_FLAG))
        }
        canvas.drawLine(LEFT, TOP + 58f, RIGHT, TOP + 58f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = cyan; strokeWidth = 2f })

        var y = TOP + 84f
        canvas.drawText("ARBEITSRAPPORT", LEFT, y, title)
        val date = SimpleDateFormat("dd.MM.yyyy, HH:mm", Locale.GERMANY).format(Date(report.updatedAt))
        canvas.drawText("Nr. ${report.id.take(8).uppercase()} · $date", RIGHT - 180f, y, value)
        y += 24f
        if (page == 1) {
            y = drawField(canvas, "KUNDE / AUFTRAGGEBER", report.customer, y, label, value)
            y = drawField(canvas, "EINSATZORT", report.location, y, label, value)
            y = drawField(canvas, "OBJEKT / ANLAGE / BAUTEIL", report.system, y, label, value)
            y = drawField(canvas, "GEWERK", report.trade.title, y, label, value)
            y += 7f
        } else {
            canvas.drawText("Fortsetzung · ${report.displayTitle}", LEFT, y, value)
            y += 22f
        }
        canvas.drawText("AUSGEFÜHRTE ARBEITEN / FESTSTELLUNGEN", LEFT, y, label)
        canvas.drawLine(LEFT, y + 7f, RIGHT, y + 7f, Paint().apply { color = Color.LTGRAY })
        return y + 25f
    }

    private fun drawField(canvas: Canvas, name: String, content: String, y: Float, label: Paint, value: Paint): Float {
        canvas.drawText(name, LEFT, y, label)
        canvas.drawText(content.ifBlank { "—" }.take(88), LEFT + 145f, y, value)
        canvas.drawLine(LEFT, y + 7f, RIGHT, y + 7f, Paint().apply { color = Color.rgb(225, 229, 233) })
        return y + 24f
    }

    private fun drawBodyLine(canvas: Canvas, line: String, y: Float): Float {
        canvas.drawText(line, LEFT, y, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(25, 34, 45); textSize = 10.5f })
        return y + 15f
    }

    private fun drawSignatures(canvas: Canvas) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.DKGRAY; textSize = 8f }
        val y = BOTTOM - 35f
        canvas.drawLine(LEFT, y, LEFT + 210f, y, Paint().apply { color = Color.GRAY })
        canvas.drawLine(RIGHT - 210f, y, RIGHT, y, Paint().apply { color = Color.GRAY })
        canvas.drawText("Datum / Unterschrift Auftragnehmer", LEFT, y + 14f, paint)
        canvas.drawText("Datum / Unterschrift Auftraggeber", RIGHT - 210f, y + 14f, paint)
    }

    private fun drawFooter(canvas: Canvas, page: Int) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.GRAY; textSize = 7.5f }
        canvas.drawText("Mit Rapport AI erstellt · Inhalt vor Verwendung fachlich prüfen", LEFT, PAGE_HEIGHT - 28f, paint)
        canvas.drawText("Seite $page", RIGHT - 36f, PAGE_HEIGHT - 28f, paint)
    }

    private fun wrap(text: String, max: Int): List<String> = buildList {
        text.replace("\r", "").split("\n").forEach { paragraph ->
            if (paragraph.isBlank()) {
                add("")
            } else {
                var line = ""
                paragraph.trim().split(Regex("\\s+")).forEach { word ->
                    if (line.isEmpty()) line = word
                    else if (line.length + word.length + 1 <= max) line += " $word"
                    else { add(line); line = word }
                }
                if (line.isNotEmpty()) add(line)
            }
        }
    }
}
