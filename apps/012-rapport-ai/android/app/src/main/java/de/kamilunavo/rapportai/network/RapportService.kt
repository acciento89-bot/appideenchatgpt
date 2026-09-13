package de.kamilunavo.rapportai.network

import de.kamilunavo.rapportai.model.Rapport
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class RapportService {
    suspend fun generate(draft: Rapport): String = withContext(Dispatchers.IO) {
        require(draft.rawText.isNotBlank()) { "Bitte zuerst den Baustellenbericht einsprechen oder eingeben." }

        val connection = (URL(ENDPOINT).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 15_000
            readTimeout = 45_000
            doOutput = true
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("apikey", PUBLISHABLE_KEY)
        }
        val payload = JSONObject().apply {
            put("rawText", draft.rawText.trim())
            put("trade", draft.trade.title)
            put("customer", draft.customer.trim())
            put("location", draft.location.trim())
            put("system", draft.system.trim())
            put("tone", draft.tone.apiValue)
        }

        try {
            connection.outputStream.bufferedWriter(Charsets.UTF_8).use { it.write(payload.toString()) }
            val code = connection.responseCode
            val stream = if (code in 200..299) connection.inputStream else connection.errorStream
            val body = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            if (code !in 200..299) throw IllegalStateException("Der KI-Dienst ist gerade nicht erreichbar. Dein Text bleibt erhalten.")
            JSONObject(body).optString("report").trim().ifEmpty {
                throw IllegalStateException("Der Rapport konnte nicht gelesen werden. Bitte erneut versuchen.")
            }
        } catch (error: IllegalStateException) {
            throw error
        } catch (_: Exception) {
            throw IllegalStateException("Der KI-Dienst ist gerade nicht erreichbar. Dein Text bleibt erhalten.")
        } finally {
            connection.disconnect()
        }
    }

    private companion object {
        const val ENDPOINT = "https://bqctetqraszsvknczjjr.supabase.co/functions/v1/generate-rapport"
        const val PUBLISHABLE_KEY = "sb_publishable_g4PeQGT99Tz2ltwdAzyXrA_NoYDXsP9"
    }
}
