package de.kamilunavo.rapportai.billing

internal enum class EntitlementPurchaseState { PENDING, PURCHASED, OTHER }

internal data class EntitlementPurchase(
    val productIds: List<String>,
    val token: String,
    val state: EntitlementPurchaseState,
    val acknowledged: Boolean
)

internal class EntitlementPurchaseProcessor(
    private val productIds: Set<String>,
    private val acknowledge: (String, (Boolean) -> Unit) -> Unit,
    private val onEntitlementChanged: (Boolean) -> Unit
) {
    fun process(purchases: List<EntitlementPurchase>, revokeIfMissing: Boolean) {
        val purchased = purchases.filter { purchase ->
            purchase.state == EntitlementPurchaseState.PURCHASED &&
                purchase.productIds.any(productIds::contains)
        }

        if (revokeIfMissing && purchased.none(EntitlementPurchase::acknowledged)) {
            onEntitlementChanged(false)
        }
        if (purchased.any(EntitlementPurchase::acknowledged)) {
            onEntitlementChanged(true)
        }
        purchased.filterNot(EntitlementPurchase::acknowledged).forEach { purchase ->
            acknowledge(purchase.token) { success ->
                if (success) onEntitlementChanged(true)
            }
        }
    }
}
