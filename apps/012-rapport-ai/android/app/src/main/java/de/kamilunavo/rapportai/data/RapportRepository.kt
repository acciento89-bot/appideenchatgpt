package de.kamilunavo.rapportai.data

import android.content.Context
import de.kamilunavo.rapportai.model.*
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class RapportRepository(context: Context) {
    private val prefs = context.getSharedPreferences("rapport_ai", Context.MODE_PRIVATE)

    private val archive = WorkWorkspaceArchive(java.io.File(context.filesDir, "RapportAI/workspace.json")) {
        prefs.getString("reports_v1", null)
    }

    fun loadWorkspace(): WorkWorkspace = archive.load().let { it.copy(reports = it.reports.sortedByDescending(Rapport::updatedAt)) }

    fun save(report: Rapport): WorkWorkspace {
        val current = loadWorkspace()
        val saved = report.preparingSave(current.reports.firstOrNull { it.id == report.id })
        return persist(current.copy(reports = listOf(saved) + current.reports.filterNot { it.id == saved.id }))
    }

    fun delete(id: String): WorkWorkspace {
        val current = loadWorkspace()
        return persist(current.copy(reports = current.reports.filterNot { it.id == id }))
    }

    fun saveTemplate(template: WorkTemplate): WorkWorkspace {
        template.validate()
        val current = loadWorkspace()
        return persist(current.copy(templates = current.templates.filterNot { it.id == template.id } + template))
    }

    fun deleteTemplate(id: String): WorkWorkspace {
        val current = loadWorkspace()
        return persist(current.copy(templates = current.templates.filterNot { it.id == id }))
    }

    fun acknowledge(reportID: String, revisionID: String, name: String, note: String): WorkWorkspace {
        val current = loadWorkspace()
        val stored = requireNotNull(current.reports.firstOrNull { it.id == reportID })
        val updated = stored.acknowledging(revisionID, name, note)
        return persist(current.copy(reports = current.reports.map { if (it.id == reportID) updated else it }))
    }

    private fun persist(workspace: WorkWorkspace): WorkWorkspace {
        archive.save(workspace)
        return workspace
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
        val current = currentMonth()
        if (prefs.getString("usage_month", "") != current) {
            prefs.edit().putString("usage_month", current).putInt("usage_count", 0).apply()
            return 0
        }
        return prefs.getInt("usage_count", 0)
    }

    fun recordGeneration(): Int {
        val next = usedThisMonth() + 1
        prefs.edit().putString("usage_month", currentMonth()).putInt("usage_count", next).apply()
        return next
    }

    private fun currentMonth(): String = SimpleDateFormat("yyyy-MM", Locale.ROOT).format(Date())

}
