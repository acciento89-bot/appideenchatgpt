package de.kamilunavo.rapportai.billing

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class EntitlementPurchaseProcessorTest {
    private val knownProduct = "de.kamilunavo.rapportai.pro.monthly"

    @Test fun restoredUnacknowledgedPurchaseIsRetriedAndGrantedOnlyAfterAcknowledgement() {
        val acknowledgements = mutableListOf<Pair<String, (Boolean) -> Unit>>()
        val entitlements = mutableListOf<Boolean>()
        val processor = EntitlementPurchaseProcessor(
            productIds = setOf(knownProduct),
            acknowledge = { token, complete -> acknowledgements += token to complete },
            onEntitlementChanged = entitlements::add
        )
        val purchase = EntitlementPurchase(
            productIds = listOf(knownProduct),
            token = "purchase-token",
            state = EntitlementPurchaseState.PURCHASED,
            acknowledged = false
        )

        processor.process(listOf(purchase), revokeIfMissing = true)
        assertEquals(listOf(false), entitlements)
        assertEquals("purchase-token", acknowledgements.single().first)

        acknowledgements.removeAt(0).second(false)
        assertEquals(listOf(false), entitlements)

        processor.process(listOf(purchase), revokeIfMissing = true)
        assertEquals(1, acknowledgements.size)
        acknowledgements.single().second(true)
        assertEquals(listOf(false, false, true), entitlements)
    }

    @Test fun pendingAndUnknownProductsNeverGrantOrAcknowledge() {
        val acknowledgedTokens = mutableListOf<String>()
        val entitlements = mutableListOf<Boolean>()
        val processor = EntitlementPurchaseProcessor(
            productIds = setOf(knownProduct),
            acknowledge = { token, _ -> acknowledgedTokens += token },
            onEntitlementChanged = entitlements::add
        )

        processor.process(
            listOf(
                EntitlementPurchase(listOf(knownProduct), "pending", EntitlementPurchaseState.PENDING, false),
                EntitlementPurchase(listOf("other.product"), "other", EntitlementPurchaseState.PURCHASED, true)
            ),
            revokeIfMissing = true
        )

        assertTrue(acknowledgedTokens.isEmpty())
        assertEquals(listOf(false), entitlements)
    }

    @Test fun acknowledgedKnownPurchaseGrantsWithoutAcknowledgingAgain() {
        var acknowledgementRequested = false
        var entitled = false
        val processor = EntitlementPurchaseProcessor(
            productIds = setOf(knownProduct),
            acknowledge = { _, _ -> acknowledgementRequested = true },
            onEntitlementChanged = { entitled = it }
        )

        processor.process(
            listOf(EntitlementPurchase(listOf(knownProduct), "owned", EntitlementPurchaseState.PURCHASED, true)),
            revokeIfMissing = true
        )

        assertTrue(entitled)
        assertFalse(acknowledgementRequested)
    }
}
