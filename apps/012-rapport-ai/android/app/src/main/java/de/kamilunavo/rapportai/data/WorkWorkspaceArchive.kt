package de.kamilunavo.rapportai.data

import de.kamilunavo.rapportai.model.*
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.io.File
import java.io.FileOutputStream
import java.math.BigDecimal
import java.util.Locale

internal object WorkWorkspaceCodec {
    private fun root(text: String): Any {
        val token = JSONTokener(text); val result = token.nextValue()
        require(token.nextClean() == 0.toChar()) { "Trailing archive content" }; return result
    }
    private fun JSONObject.string(key: String): String { val value = get(key); require(value is String); return value }
    private fun JSONObject.long(key: String): Long { val value = get(key); require(value is Number); return BigDecimal(value.toString()).longValueExact() }
    private fun JSONObject.array(key: String) = getJSONArray(key)
    private fun <T> JSONArray.read(action: (JSONObject) -> T) = (0 until length()).map { action(getJSONObject(it)) }
    private fun <T> array(items: List<T>, encode: (T) -> JSONObject) = JSONArray().apply { items.forEach { put(encode(it)) } }
    private fun item(value: WorkItem) = JSONObject().put("id", value.id).put("kind", value.kind.name).put("description", value.description).put("unit", value.unit).apply {
        value.minutes?.let { put("minutes", it) }; value.quantityValue?.let { put("quantityValue", it) }
    }
    private fun item(value: JSONObject) = WorkItem(value.string("id"), WorkKind.valueOf(value.string("kind")), value.string("description"), value.string("unit"),
        if (value.has("minutes")) value.long("minutes").also { require(it >= Int.MIN_VALUE.toLong() && it <= Int.MAX_VALUE.toLong()) }.toInt() else null,
        if (value.has("quantityValue")) value.string("quantityValue") else null)
    private fun content(value: WorkRevisionContent) = JSONObject().put("reportID", value.reportID).put("trade", value.trade.name).put("customer", value.customer).put("location", value.location).put("system", value.system)
        .put("rawText", value.rawText).put("reportText", value.reportText).put("tone", value.tone.name).put("createdAt", value.createdAt).put("workItems", array(value.workItems, ::item))
    private fun content(value: JSONObject) = WorkRevisionContent(value.string("reportID"), Trade.valueOf(value.string("trade")), value.string("customer"), value.string("location"), value.string("system"), value.string("rawText"), value.string("reportText"), Tone.valueOf(value.string("tone")), value.long("createdAt"), value.array("workItems").read(::item))
    private fun revision(value: WorkRevision) = JSONObject().put("id", value.id).put("number", value.number).put("at", value.at).put("content", content(value.content))
    private fun revision(value: JSONObject): WorkRevision {
        val number = value.long("number"); require(number >= 1 && number <= Int.MAX_VALUE.toLong())
        return WorkRevision(value.string("id"), number.toInt(), value.long("at"), content(value.getJSONObject("content")))
    }
    private fun ack(value: WorkAcknowledgement) = JSONObject().put("id", value.id).put("revisionID", value.revisionID).put("name", value.name).put("note", value.note).put("at", value.at)
    private fun ack(value: JSONObject) = WorkAcknowledgement(value.string("id"), value.string("revisionID"), value.string("name"), value.string("note"), value.long("at"))
    private fun report(value: Rapport) = JSONObject().put("id", value.id).put("trade", value.trade.name).put("customer", value.customer).put("location", value.location).put("system", value.system)
        .put("rawText", value.rawText).put("reportText", value.reportText).put("tone", value.tone.name).put("createdAt", value.createdAt).put("updatedAt", value.updatedAt)
        .put("workItems", array(value.workItems, ::item)).put("revisions", array(value.revisions, ::revision)).put("acknowledgements", array(value.acknowledgements, ::ack))
    private fun report(value: JSONObject): Rapport {
        val result = Rapport(value.string("id"), Trade.valueOf(value.string("trade")), value.string("customer"), value.string("location"), value.string("system"), value.string("rawText"), value.string("reportText"), Tone.valueOf(value.string("tone")), value.long("createdAt"), value.long("updatedAt"),
            if (value.has("workItems")) value.array("workItems").read(::item) else emptyList(), emptyList(), if (value.has("acknowledgements")) value.array("acknowledgements").read(::ack) else emptyList())
        return result.copy(revisions = if (value.has("revisions")) value.array("revisions").read(::revision) else listOf(WorkRevision(number = 1, at = result.updatedAt, content = WorkRevisionContent.from(result))))
    }
    private fun template(value: WorkTemplate) = JSONObject().put("id", value.id).put("name", value.name).put("trade", value.trade.name).put("lines", array(value.lines) { JSONObject().put("kind", it.kind.name).put("description", it.description).put("unit", it.unit) })
    private fun template(value: JSONObject) = WorkTemplate(value.string("id"), value.string("name"), Trade.valueOf(value.string("trade")), value.array("lines").read { WorkTemplateLine(WorkKind.valueOf(it.string("kind")), it.string("description"), it.string("unit")) })
    fun legacy(text: String): WorkWorkspace {
        val value = root(text); require(value is JSONArray)
        return WorkWorkspace(value.read(::report), emptyList()).also(::validate)
    }
    fun decode(text: String): WorkWorkspace {
        val value = root(text); require(value is JSONObject && value.long("schemaVersion") == 1L)
        return WorkWorkspace(value.array("reports").read(::report), value.array("templates").read(::template)).also(::validate)
    }
    fun encode(value: WorkWorkspace): String {
        validate(value)
        return JSONObject().put("schemaVersion", 1).put("reports", array(value.reports, ::report)).put("templates", array(value.templates, ::template)).toString()
    }
    fun validate(value: WorkWorkspace) {
        require(value.reports.map { it.id.lowercase(Locale.ROOT) }.toSet().size == value.reports.size)
        require(value.templates.map { it.id.lowercase(Locale.ROOT) }.toSet().size == value.templates.size)
        value.reports.forEach { it.validateWorkHistory() }; value.templates.forEach { it.validate() }
    }
}

/** All production file operations are available on API24. Legacy preferences are never written here. */
class WorkWorkspaceArchive(private val file: File, private val legacy: () -> String? = { null }) {
    fun load(): WorkWorkspace = if (file.exists()) WorkWorkspaceCodec.decode(file.readText(Charsets.UTF_8))
        else legacy()?.let(WorkWorkspaceCodec::legacy) ?: WorkWorkspace(emptyList(), emptyList())
    fun save(snapshot: WorkWorkspace) {
        load(); val bytes = WorkWorkspaceCodec.encode(snapshot).toByteArray(Charsets.UTF_8)
        val directory = requireNotNull(file.absoluteFile.parentFile)
        require(directory.isDirectory || directory.mkdirs())
        val temp = File.createTempFile("rapport-work-", ".tmp", directory)
        try {
            FileOutputStream(temp).use { it.write(bytes); it.fd.sync() }
            // Same-directory rename replaces atomically on Android's local POSIX filesystem.
            // If the platform refuses replacement, fail without deleting the destination.
            check(temp.renameTo(file)) { "Cannot replace report archive" }
        } finally { temp.delete() }
    }
}
