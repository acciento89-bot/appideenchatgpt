package de.kamilunavo.rapportai.model

import java.util.UUID

enum class Trade(val title: String) {
    GENERAL("Allgemeines Handwerk"),
    PLUMBING_HEATING("Sanitär & Heizung"),
    ELECTRICAL("Elektro"),
    PAINTING("Maler & Lackierer"),
    CARPENTRY("Tischler & Schreiner"),
    ROOFING("Dach & Fassade"),
    CONSTRUCTION("Bau & Ausbau"),
    FACILITY("Hausmeisterservice"),
    OTHER("Sonstiges Gewerk")
}

enum class Tone(val title: String, val apiValue: String) {
    FACTUAL("Sachlich", "factual"),
    CUSTOMER_FRIENDLY("Kundenfreundlich", "customerFriendly"),
    DOCUMENTATION("Dokumentation", "insurance")
}

data class Rapport(
    val id: String = UUID.randomUUID().toString(),
    val trade: Trade = Trade.GENERAL,
    val customer: String = "",
    val location: String = "",
    val system: String = "",
    val rawText: String = "",
    val reportText: String = "",
    val tone: Tone = Tone.FACTUAL,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    val displayTitle: String
        get() = customer.trim().ifEmpty { system.trim().ifEmpty { "Neuer Arbeitsrapport" } }
}

data class CompanyProfile(
    val companyName: String = "",
    val ownerName: String = "",
    val address: String = "",
    val phone: String = "",
    val email: String = "",
    val logoPath: String? = null
)
