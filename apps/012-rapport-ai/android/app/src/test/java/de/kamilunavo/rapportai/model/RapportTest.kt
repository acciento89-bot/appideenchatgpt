package de.kamilunavo.rapportai.model

import org.junit.Assert.assertEquals
import org.junit.Test

class RapportTest {
    @Test fun displayTitlePrefersCustomerThenSystem() {
        assertEquals("Muster GmbH", Rapport(customer = "Muster GmbH", system = "Kessel").displayTitle)
        assertEquals("Kessel", Rapport(system = "Kessel").displayTitle)
        assertEquals("Neuer Arbeitsrapport", Rapport().displayTitle)
    }

    @Test fun allApiToneValuesMatchBackendContract() {
        assertEquals(listOf("factual", "customerFriendly", "insurance"), Tone.entries.map { it.apiValue })
    }
}
