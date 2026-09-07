package de.kamilunavo.rapportai.data

import android.content.Context
import de.kamilunavo.rapportai.model.CompanyProfile
import de.kamilunavo.rapportai.model.Rapport
import de.kamilunavo.rapportai.model.Tone
import de.kamilunavo.rapportai.model.Trade
import org.json.JSONArray
import org.json.JSONObject
import java.time.YearMonth

class RapportRepository(context: Context) {
    private val prefs = context.getSharedPreferences("rapport_ai", Context.MODE_PRIVATE)

    fun loadReports(): List<Rapport> = runCatching {
        val array = JSONArray(prefs.getString("reports_v1", "[]"))
        buildList {
            for (index in 0 until array.length()) add(array.getJSONObject(index).toRapport())
        }.sortedByDescending { it.updatedAt }
    }.getOrDefault(emptyList())

    fun save(report: Rapport): List<Rapport> {
        val updated = report.copy(updatedAt = System.currentTimeMillis())
        val reports = loadReports().filterNot { it.id == report.id }.toMutableList()
        reports.add(0, updated)
        persistReports(reports)
        return reports
    }

    fun delete(id: String): List<Rapport> {
        val reports = loadReports().filterNot { it.id == id }
        persistReports(reports)
        return reports
    }

    fun loadProfile(): CompanyProfile = runCatching {
        JSONObject(prefs.getString("company_v1", "{}") ?: "{}").let {
            CompanyProfile(
                companyName = it.optString("companyName"),
                ownerName = it.optString("ownerName"),
                address = it.optString("address"),
                phone = it.optString("phone"),
                email = it.optString("email"),
                logoPath = it.optString("logoPath").takeIf(String::isNotBlank)
            )
        }
    }.getOrDefault(CompanyProfile())

    fun saveProfile(profile: CompanyProfile) {
        prefs.edit().putString("company_v1", JSONObject().apply {
            put("companyName", profile.companyName)
            put("ownerName", profile.ownerName)
            put("address", profile.address)
            put("phone", profile.phone)
            put("email", profile.email)
            put("logoPath", profile.logoPath ?: "")
        }.toString()).apply()
    }

    fun isPro(): Boolean = prefs.getBoolean("pro_active", false)
    fun setPro(active: Boolean) = prefs.edit().putBoolean("pro_active", active).apply()

    fun usedThisMonth(): Int {
        val current = YearMonth.now().toString()
        if (prefs.getString("usage_month", "") != current) {
            prefs.edit().putString("usage_month", current).putInt("usage_count", 0).apply()
            return 0
        }
        return prefs.getInt("usage_count", 0)
    }

    fun recordGeneration(): Int {
        val next = usedThisMonth() + 1
        prefs.edit().putString("usage_month", YearMonth.now().toString()).putInt("usage_count", next).apply()
        return next
    }

    private fun persistReports(reports: List<Rapport>) {
        prefs.edit().putString("reports_v1", JSONArray().apply {
            reports.forEach { put(it.toJson()) }
        }.toString()).apply()
    }

    private fun Rapport.toJson() = JSONObject().apply {
        put("id", id); put("trade", trade.name); put("customer", customer); put("location", location)
        put("system", system); put("rawText", rawText); put("reportText", reportText)
        put("tone", tone.name); put("createdAt", createdAt); put("updatedAt", updatedAt)
    }

    private fun JSONObject.toRapport() = Rapport(
        id = optString("id"),
        trade = runCatching { Trade.valueOf(optString("trade")) }.getOrDefault(Trade.GENERAL),
        customer = optString("customer"),
        location = optString("location"),
        system = optString("system"),
        rawText = optString("rawText"),
        reportText = optString("reportText"),
        tone = runCatching { Tone.valueOf(optString("tone")) }.getOrDefault(Tone.FACTUAL),
        createdAt = optLong("createdAt", System.currentTimeMillis()),
        updatedAt = optLong("updatedAt", System.currentTimeMillis())
    )
}
