package de.kamilunavo.rapportai.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class BillingManager(
    context: Context,
    private val onEntitlementChanged: (Boolean) -> Unit
) {
    data class BillingState(
        val connected: Boolean = false,
        val products: Map<String, ProductDetails> = emptyMap(),
        val message: String? = null
    )

    private val _state = MutableStateFlow(BillingState())
    val state: StateFlow<BillingState> = _state

    private val client = BillingClient.newBuilder(context)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .setListener { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
                val active = purchases.any { it.purchaseState == com.android.billingclient.api.Purchase.PurchaseState.PURCHASED }
                purchases.filter { it.purchaseState == com.android.billingclient.api.Purchase.PurchaseState.PURCHASED && !it.isAcknowledged }
                    .forEach { purchase ->
                        client.acknowledgePurchase(
                            AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build()
                        ) { acknowledge ->
                            if (acknowledge.responseCode == BillingClient.BillingResponseCode.OK) onEntitlementChanged(true)
                        }
                    }
                if (active) onEntitlementChanged(true)
            } else if (result.responseCode != BillingClient.BillingResponseCode.USER_CANCELED) {
                _state.value = _state.value.copy(message = "Der Kauf wurde nicht abgeschlossen.")
            }
        }.build()

    fun connect() {
        if (client.isReady) return
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    _state.value = _state.value.copy(connected = true)
                    queryProducts()
                    restore()
                } else _state.value = _state.value.copy(message = "Google Play Billing ist gerade nicht verfügbar.")
            }
            override fun onBillingServiceDisconnected() {
                _state.value = _state.value.copy(connected = false)
            }
        })
    }

    private fun queryProducts() {
        val products = PRODUCT_IDS.map {
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(it)
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        }
        client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(products).build()) { result, details ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                _state.value = _state.value.copy(products = details.associateBy { it.productId })
            }
        }
    }

    fun purchase(activity: Activity, productId: String) {
        val details = _state.value.products[productId] ?: run {
            _state.value = _state.value.copy(message = "Das Angebot wird noch von Google Play verarbeitet.")
            return
        }
        val offerToken = details.subscriptionOfferDetails?.firstOrNull()?.offerToken ?: run {
            _state.value = _state.value.copy(message = "Für dieses Angebot ist noch kein Basisplan aktiv.")
            return
        }
        val params = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(details)
            .setOfferToken(offerToken)
            .build()
        client.launchBillingFlow(activity, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(params)).build())
    }

    fun restore() {
        if (!client.isReady) return
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                onEntitlementChanged(purchases.any { it.purchaseState == com.android.billingclient.api.Purchase.PurchaseState.PURCHASED })
            }
        }
    }

    fun clearMessage() { _state.value = _state.value.copy(message = null) }
    fun close() = client.endConnection()

    companion object {
        const val MONTHLY_ID = "de.kamilunavo.rapportai.pro.monthly"
        const val ANNUAL_ID = "de.kamilunavo.rapportai.pro.annual"
        val PRODUCT_IDS = listOf(MONTHLY_ID, ANNUAL_ID)
    }
}
