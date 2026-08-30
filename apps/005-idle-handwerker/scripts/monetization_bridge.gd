class_name MonetizationBridge
extends Node

signal purchase_completed(product_id: String, transaction_id: String)
signal purchase_failed(message: String)
signal rewarded_completed
signal rewarded_unavailable(message: String)

const PRODUCTS := [
	"de.kamilunavo.idlehandwerker.noads",
	"de.kamilunavo.idlehandwerker.starter",
	"de.kamilunavo.idlehandwerker.tokens.small",
	"de.kamilunavo.idlehandwerker.tokens.large",
]

var _store: Object
var _ads: Object


func _ready() -> void:
	if Engine.has_singleton("InAppStore"):
		_store = Engine.get_singleton("InAppStore")
	if Engine.has_singleton("AdMob"):
		_ads = Engine.get_singleton("AdMob")
		for signal_name in ["rewarded_ad_earned_reward", "rewarded_earned_reward", "rewarded"]:
			if _ads.has_signal(signal_name):
				_ads.connect(signal_name, _on_native_reward)
				break
	set_process(_store != null)


func _process(_delta: float) -> void:
	if _store == null or not _store.has_method("pop_pending_event"):
		return
	while true:
		var event = _store.call("pop_pending_event")
		if event == null:
			break
		_handle_store_event(event)


func purchase(product_id: String) -> void:
	if product_id not in PRODUCTS:
		purchase_failed.emit("Unbekanntes Produkt.")
		return
	if _store != null and _store.has_method("purchase"):
		_store.call("purchase", {"product_id": product_id})
		return
	if OS.has_feature("editor"):
		purchase_completed.emit(product_id, "editor-%s-%d" % [product_id, Time.get_ticks_msec()])
	else:
		purchase_failed.emit("StoreKit ist in diesem Build nicht verfügbar.")


func restore_purchases() -> void:
	if _store != null and _store.has_method("restore_purchases"):
		_store.call("restore_purchases")
	else:
		purchase_failed.emit("Käufe konnten nicht wiederhergestellt werden.")


func show_rewarded_ad() -> void:
	if _ads != null and _ads.has_method("show_rewarded_ad"):
		_ads.call("show_rewarded_ad")
		return
	if OS.has_feature("editor"):
		rewarded_completed.emit()
	else:
		rewarded_unavailable.emit("Belohnungswerbung ist gerade nicht verfügbar.")


func _handle_store_event(event: Variant) -> void:
	if not event is Dictionary:
		return
	var event_type := str(event.get("type", event.get("event", "")))
	if event_type in ["purchase", "purchase_success", "restore", "restore_success"]:
		var product_id := str(event.get("product_id", event.get("productId", "")))
		var transaction_id := str(event.get("transaction_id", event.get("transactionId", "")))
		if product_id in PRODUCTS:
			purchase_completed.emit(product_id, transaction_id)
	elif event_type in ["purchase_error", "restore_error", "error"]:
		purchase_failed.emit(str(event.get("message", "StoreKit-Fehler")))


func _on_native_reward(_value: Variant = null, _currency: Variant = null) -> void:
	rewarded_completed.emit()
