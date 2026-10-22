package de.kamilunavo.rapportai.model

import java.math.BigDecimal
import java.util.UUID
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class WorkKind { LABOR, MATERIAL, MEASUREMENT }
data class WorkItem(
    val id: String = UUID.randomUUID().toString(), val kind: WorkKind, val description: String,
    val unit: String, val minutes: Int? = null, val quantityValue: String? = null,
) {
    val quantity: BigDecimal? get() = quantityValue?.toBigDecimal()
    companion object {
        fun labor(description: String, minutes: Int) = WorkItem(kind = WorkKind.LABOR, description = description.trim(), unit = "min", minutes = minutes).also { it.validate() }
        fun quantity(kind: WorkKind, description: String, amount: String, unit: String): WorkItem {
            require(kind != WorkKind.LABOR)
            val text = amount.trim().replace(',', '.')
            require(text.matches(Regex("[0-9]{1,12}(\\.[0-9]{1,3})?")))
            val number = text.toBigDecimal()
            require(number >= BigDecimal.ZERO && number <= BigDecimal("999999999.999"))
            return WorkItem(kind = kind, description = description.trim(), unit = unit.trim(), quantityValue = number.stripTrailingZeros().toPlainString()).also { it.validate() }
        }
        fun blank(kind: WorkKind, description: String, unit: String) = WorkItem(kind = kind, description = description, unit = if (kind == WorkKind.LABOR) "min" else unit)
    }
    fun validate() {
        requireValidWorkID(id); require(description.isNotBlank() && unit.isNotBlank())
        if (kind == WorkKind.LABOR) require(quantityValue == null && unit == "min" && (minutes == null || minutes in 0..1000000))
        else {
            require(minutes == null)
            quantityValue?.let { require(it.matches(Regex("[0-9]{1,12}(\\.[0-9]{1,3})?")) && it.toBigDecimal() >= BigDecimal.ZERO && it.toBigDecimal() <= BigDecimal("999999999.999")) }
        }
    }
}
class WorkTotals(items: List<WorkItem>) {
    val laborMinutes: Int
    val incompleteCount: Int
    private val quantities: Map<Pair<WorkKind, String>, BigDecimal>
    init {
        require(items.size <= 1000 && items.map { it.id.lowercase(Locale.ROOT) }.toSet().size == items.size)
        items.forEach { it.validate() }
        laborMinutes = items.filter { it.kind == WorkKind.LABOR }.sumOf { it.minutes ?: 0 }
        incompleteCount = items.count { if (it.kind == WorkKind.LABOR) it.minutes == null else it.quantity == null }
        quantities = items.filter { it.kind != WorkKind.LABOR && it.quantity != null }.groupBy { it.kind to it.unit.trim() }
            .mapValues { (_, entries) -> entries.fold(BigDecimal.ZERO) { sum, item -> sum + item.quantity!! } }
    }
    fun quantity(kind: WorkKind, unit: String): BigDecimal = quantities[kind to unit.trim()] ?: BigDecimal.ZERO
}
data class WorkTemplateLine(val kind: WorkKind, val description: String, val unit: String)
data class WorkTemplate(val id: String = UUID.randomUUID().toString(), val name: String, val trade: Trade, val lines: List<WorkTemplateLine>) {
    constructor(name: String, trade: Trade, items: List<WorkItem>) : this(name = name.trim(), trade = trade, lines = items.map { WorkTemplateLine(it.kind, it.description, it.unit) }) { WorkTotals(items); validate() }
    fun instantiate(): List<WorkItem> = lines.map { WorkItem.blank(it.kind, it.description, it.unit) }
    fun validate() { requireValidWorkID(id); require(name.isNotBlank() && lines.isNotEmpty()); WorkTotals(instantiate()) }
}
data class WorkRevisionContent(
    val reportID: String, val trade: Trade, val customer: String, val location: String, val system: String,
    val rawText: String, val reportText: String, val tone: Tone, val createdAt: Long, val workItems: List<WorkItem>,
) {
    companion object {
        fun from(report: Rapport) = WorkRevisionContent(report.id, report.trade, report.customer, report.location, report.system, report.rawText, report.reportText, report.tone, report.createdAt, report.workItems.map { it.copy() })
    }
    fun validate() { requireValidWorkID(reportID); WorkTotals(workItems) }
}
data class WorkRevision(val id: String = UUID.randomUUID().toString(), val number: Int, val at: Long, val content: WorkRevisionContent)
data class WorkAcknowledgement(val id: String = UUID.randomUUID().toString(), val revisionID: String, val name: String, val note: String, val at: Long)
data class WorkWorkspace(val reports: List<Rapport>, val templates: List<WorkTemplate>)

internal fun requireValidWorkID(value: String) { require(UUID.fromString(value).toString().equals(value, ignoreCase = true)) }
fun Rapport.validateWorkHistory() {
    requireValidWorkID(id); WorkTotals(workItems)
    require(revisions.map { it.id.lowercase(Locale.ROOT) }.toSet().size == revisions.size)
    require(acknowledgements.map { it.id.lowercase(Locale.ROOT) }.toSet().size == acknowledgements.size)
    revisions.forEachIndexed { index, revision ->
        requireValidWorkID(revision.id)
        require(revision.number == index + 1 && revision.content.reportID == id && revision.content.createdAt == createdAt)
        revision.content.validate()
    }
    acknowledgements.forEach { ack -> requireValidWorkID(ack.id); require(ack.name.isNotBlank() && revisions.any { it.id == ack.revisionID }) }
}
fun Rapport.savingRevision(at: Long = System.currentTimeMillis()): Rapport {
    validateWorkHistory()
    val content = WorkRevisionContent.from(this)
    val next = if (revisions.lastOrNull()?.content != content) revisions + WorkRevision(number = revisions.size + 1, at = at, content = content) else revisions
    return copy(revisions = next, updatedAt = at)
}
fun Rapport.preparingSave(preserving: Rapport?, at: Long = System.currentTimeMillis()): Rapport {
    if (preserving == null) return savingRevision(at)
    preserving.validateWorkHistory()
    require(preserving.id == id)
    return copy(createdAt = preserving.createdAt, revisions = preserving.revisions.toList(), acknowledgements = preserving.acknowledgements.toList()).savingRevision(at)
}
fun Rapport.acknowledging(revisionID: String, name: String, note: String, at: Long = System.currentTimeMillis()): Rapport {
    validateWorkHistory(); require(name.isNotBlank() && revisions.any { it.id == revisionID })
    return copy(acknowledgements = acknowledgements + WorkAcknowledgement(revisionID = revisionID, name = name.trim(), note = note.trim(), at = at))
}
val Rapport.latestIsAcknowledged: Boolean get() = revisions.lastOrNull()?.let { last -> last.content == WorkRevisionContent.from(this) && acknowledgements.any { it.revisionID == last.id } } ?: false
fun Rapport.structuredWorkText(german: Boolean): String {
    fun l(de: String, en: String) = if (german) de else en
    fun kind(kind: WorkKind) = when (kind) { WorkKind.LABOR -> l("Arbeitszeit", "Labor"); WorkKind.MATERIAL -> "Material"; WorkKind.MEASUREMENT -> l("Messwert", "Measurement") }
    fun decimal(value: BigDecimal): String = value.stripTrailingZeros().toPlainString().let { if (german) it.replace('.', ',') else it }
    fun rows(items: List<WorkItem>) = items.map {
        val value = if (it.kind == WorkKind.LABOR) it.minutes?.let { value -> "$value min" } else it.quantity?.let { value -> "${decimal(value)} ${it.unit}" }
        "• ${it.description} [${kind(it.kind)}]: ${value ?: l("Nicht angegeben", "Not entered")}"
    }
    val date = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.ROOT)
    val lines = mutableListOf(l("Arbeitspositionen", "Work line items"), l("Nur eingegebene Werte; keine durch KI ergänzten Messwerte.", "Entered facts only; no AI-added measurements."))
    if (rawText.isNotBlank()) lines += listOf("", l("Ursprüngliche Notizen", "Original notes"), rawText)
    if (reportText.isNotBlank()) lines += listOf("", l("Bearbeiteter Rapporttext", "Edited report text"), reportText)
    lines += rows(workItems)
    val totals = WorkTotals(workItems)
    lines += l("Arbeitszeit gesamt: ", "Total labor: ") + "${totals.laborMinutes} min"
    for (kind in listOf(WorkKind.MATERIAL, WorkKind.MEASUREMENT)) {
        workItems.filter { it.kind == kind && it.quantity != null }.map { it.unit.trim() }.distinct().sorted().forEach { unit -> lines += "${kind(kind)}: ${decimal(totals.quantity(kind, unit))} $unit" }
    }
    lines += l("Nicht ausgefüllte Positionen: ", "Unfilled entries: ") + totals.incompleteCount
    lines += listOf("", l("GESPEICHERTE VERSIONEN", "SAVED REVISIONS"))
    revisions.forEach { revision ->
        lines += listOf("", "${l("Version", "Revision")} ${revision.number} · ${date.format(Date(revision.at))}", revision.content.customer, revision.content.location, revision.content.system)
        if (revision.content.rawText.isNotBlank()) lines += listOf(l("Ursprüngliche Notizen", "Original notes"), revision.content.rawText)
        if (revision.content.reportText.isNotBlank()) lines += listOf(l("Bearbeiteter Rapporttext", "Edited report text"), revision.content.reportText)
        lines += rows(revision.content.workItems)
        acknowledgements.filter { it.revisionID == revision.id }.forEach { lines += listOf(l("Lokale Bestätigung: ", "Local acknowledgement: ") + it.name, it.note, date.format(Date(it.at))) }
    }
    lines += listOf("", if (latestIsAcknowledged) l("Aktuelle gespeicherte Version lokal bestätigt.", "Current saved revision locally acknowledged.") else l("Aktueller Inhalt nicht bestätigt.", "Current content is not acknowledged."), l("Bestätigung ist eine lokale Namenseingabe, keine digitale Signatur, Identitätsprüfung oder rechtssichere Abnahme. Zeitangaben stammen von der Geräteuhr. Frühere Bestätigungen gelten nur für die zugehörige Version.", "Acknowledgement is a local entered name, not a digital signature, identity verification or legally verified acceptance. Times come from the device clock. Earlier acknowledgements apply only to their associated revision."))
    return lines.joinToString("\n")
}
