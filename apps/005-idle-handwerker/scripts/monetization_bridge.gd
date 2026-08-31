class_name MonetizationBridge
extends Node

signal purchase_completed(product_id: String, transaction_id: String)
signal purchase_failed(message: String)
signal product_prices_updated
signal restore_completed(message: String)
signal rewarded_completed
signal rewarded_unavailable(message: String)
signal rewarded_ready_changed(placement: String, ready: bool)

const PRODUCTS := [
	"de.kamilunavo.idlehandwerker.noads",
	"de.kamilunavo.idlehandwerker.starter",
	"de.kamilunavo.idlehandwerker.tokens.small",
	"de.kamilunavo.idlehandwerker.tokens.large",
]
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/1712485313"
const REWARDED_SETTING_PATHS := {
	"boost": "monetization/admob/rewarded_boost_id",
	"offline": "monetization/admob/rewarded_offline_id",
}

var _store: Object
var _product_prices: Dictionary = {}
var _rewarded_ads: Dictionary = {}
var _rewarded_loaders: Dictionary = {}
var _active_rewarded_placement := ""
var _active_rewarded_ad: RewardedAd
var _ads_started := false
var _ads_suspended := false
var _pending_product_id := ""


func _ready() -> void:
	_setup_storekit()
	if OS.get_name() == "iOS":
		_start_consent_flow()
	set_process(_store != null)


func _exit_tree() -> void:
	_shutdown_ads(true)


func handle_application_paused(paused: bool) -> void:
	if paused:
		_ads_suspended = true
		_shutdown_ads()
		return
	_ads_suspended = false
	if _ads_started:
		_load_rewarded("boost")
		_load_rewarded("offline")


func _setup_storekit() -> void:
	if not Engine.has_singleton("InAppStore"):
		return
	_store = Engine.get_singleton("InAppStore")
	if _store.has_method("set_auto_finish_transaction"):
		_store.call("set_auto_finish_transaction", true)
	if _store.has_method("request_product_info"):
		var result = _store.call("request_product_info", {"product_ids": PRODUCTS})
		if result != OK:
			purchase_failed.emit("Produktinformationen konnten nicht geladen werden.")


func _process(_delta: float) -> void:
	if _store == null or not _store.has_method("pop_pending_event"):
		return
	if _store.has_method("get_pending_event_count"):
		while int(_store.call("get_pending_event_count")) > 0:
			_handle_store_event(_store.call("pop_pending_event"))
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
		if not _pending_product_id.is_empty():
			purchase_failed.emit("Ein Kauf wird bereits verarbeitet.")
			return
		var result = _store.call("purchase", {"product_id": product_id})
		if result != OK:
			purchase_failed.emit("Der Kauf konnte nicht gestartet werden.")
		else:
			_pending_product_id = product_id
		return
	if OS.has_feature("editor"):
		purchase_completed.emit(product_id, "editor-%s-%d" % [product_id, Time.get_ticks_msec()])
	else:
		purchase_failed.emit("StoreKit ist in diesem Build nicht verfügbar.")


func restore_purchases() -> void:
	if _store != null and _store.has_method("restore_purchases"):
		var result = _store.call("restore_purchases")
		if result != OK:
			purchase_failed.emit("Die Wiederherstellung konnte nicht gestartet werden.")
	elif OS.has_feature("editor"):
		restore_completed.emit("Test-Wiederherstellung abgeschlossen.")
	else:
		purchase_failed.emit("Käufe konnten nicht wiederhergestellt werden.")


func get_localized_price(product_id: String, fallback: String = "") -> String:
	return str(_product_prices.get(product_id, fallback))


func show_rewarded_ad(placement: String = "boost") -> void:
	if OS.has_feature("editor"):
		rewarded_completed.emit()
		return
	if placement not in REWARDED_SETTING_PATHS:
		rewarded_unavailable.emit("Unbekannte Werbeplatzierung.")
		return
	var rewarded_ad = _rewarded_ads.get(placement)
	if rewarded_ad == null:
		rewarded_unavailable.emit("Das Belohnungsvideo wird noch geladen. Bitte gleich erneut versuchen.")
		_load_rewarded(placement)
		return
	_active_rewarded_placement = placement
	_active_rewarded_ad = rewarded_ad
	_rewarded_ads.erase(placement)
	rewarded_ready_changed.emit(placement, false)
	var full_screen_callback := FullScreenContentCallback.new()
	full_screen_callback.on_ad_clicked = _on_rewarded_noop
	full_screen_callback.on_ad_dismissed_full_screen_content = _on_rewarded_closed.bind(placement)
	full_screen_callback.on_ad_failed_to_show_full_screen_content = _on_rewarded_show_failed.bind(placement)
	full_screen_callback.on_ad_impression = _on_rewarded_noop
	full_screen_callback.on_ad_showed_full_screen_content = _on_rewarded_noop
	rewarded_ad.full_screen_content_callback = full_screen_callback
	rewarded_ad.on_ad_paid = _on_rewarded_paid_noop
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = _on_native_reward.bind(placement)
	rewarded_ad.show(reward_listener)


func show_privacy_options() -> void:
	if OS.get_name() != "iOS":
		return
	UserMessagingPlatform.show_privacy_options_form(_on_privacy_options_closed)


func privacy_options_required() -> bool:
	if OS.get_name() != "iOS":
		return false
	return (
		UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	)


func _handle_store_event(event: Variant) -> void:
	if not event is Dictionary:
		return
	var result := str(event.get("result", "ok"))
	var event_type := str(event.get("type", event.get("event", "")))
	var event_product_id := str(event.get("product_id", event.get("productId", "")))
	if result == "error":
		if event_type == "purchase" and event_product_id == _pending_product_id:
			_pending_product_id = ""
			purchase_failed.emit(str(event.get("error", "Der Kauf ist fehlgeschlagen.")))
		else:
			push_warning("StoreKit-Ereignis fehlgeschlagen: %s" % str(event))
		return
	if result == "completed":
		if event_type == "restore":
			restore_completed.emit("Käufe wurden wiederhergestellt.")
		return
	match event_type:
		"product_info":
			_update_product_prices(event)
		"purchase", "purchase_success", "restore", "restore_success":
			var product_id := event_product_id
			var transaction_id := str(event.get("transaction_id", event.get("transactionId", "")))
			if product_id in PRODUCTS:
				if event_type.begins_with("purchase") and product_id == _pending_product_id:
					_pending_product_id = ""
				purchase_completed.emit(product_id, transaction_id)
		"purchase_error", "restore_error", "error":
			purchase_failed.emit(str(event.get("message", "StoreKit-Fehler")))


func _update_product_prices(event: Dictionary) -> void:
	var ids: Array = event.get("ids", [])
	var prices: Array = event.get("localized_prices", [])
	for index in mini(ids.size(), prices.size()):
		_product_prices[str(ids[index])] = str(prices[index])
	product_prices_updated.emit()


func _start_consent_flow() -> void:
	var params := ConsentRequestParameters.new()
	params.tag_for_under_age_of_consent = false
	UserMessagingPlatform.consent_information.update(
		params,
		_on_consent_information_updated,
		_on_consent_information_update_failed
	)


func _on_consent_information_updated() -> void:
	var consent_information := UserMessagingPlatform.consent_information
	if (
		consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
		and consent_information.get_is_consent_form_available()
	):
		UserMessagingPlatform.load_consent_form(
			_on_consent_form_loaded,
			_on_consent_form_load_failed
		)
		return
	_initialize_ads()


func _initialize_ads() -> void:
	if _ads_started:
		return
	_ads_started = true
	# Contextual/non-personalized requests keep the game independent of ATT tracking permission.
	MobileAds.set_publisher_first_party_id_enabled(false)
	MobileAds.initialize()
	_load_rewarded("boost")
	_load_rewarded("offline")


func _on_consent_information_update_failed(_form_error: FormError) -> void:
	_initialize_ads()


func _on_consent_form_loaded(form: ConsentForm) -> void:
	form.show(_on_consent_form_closed)


func _on_consent_form_load_failed(_form_error: FormError) -> void:
	_initialize_ads()


func _on_consent_form_closed(_form_error: FormError) -> void:
	_initialize_ads()


func _on_privacy_options_closed(form_error: FormError) -> void:
	if form_error != null:
		purchase_failed.emit("Datenschutzoptionen konnten nicht geöffnet werden.")


func _load_rewarded(placement: String) -> void:
	if (
		not _ads_started
		or _ads_suspended
		or _rewarded_loaders.has(placement)
		or _rewarded_ads.has(placement)
	):
		return
	var setting_path := str(REWARDED_SETTING_PATHS[placement])
	var unit_id := str(ProjectSettings.get_setting(setting_path, TEST_REWARDED_ID))
	if unit_id.is_empty():
		unit_id = TEST_REWARDED_ID
	var request := AdRequest.new()
	request.extras = {"npa": "1"}
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = _on_rewarded_loaded.bind(placement)
	callback.on_ad_failed_to_load = _on_rewarded_load_failed.bind(placement)
	var loader := RewardedAdLoader.new()
	_rewarded_loaders[placement] = loader
	loader.load(unit_id, request, callback)


func _on_rewarded_loaded(rewarded_ad: RewardedAd, placement: String) -> void:
	_rewarded_loaders.erase(placement)
	if _ads_suspended:
		rewarded_ad.destroy()
		return
	rewarded_ad.on_ad_paid = _on_rewarded_paid_noop
	_rewarded_ads[placement] = rewarded_ad
	rewarded_ready_changed.emit(placement, true)


func _on_rewarded_load_failed(error: LoadAdError, placement: String) -> void:
	_rewarded_loaders.erase(placement)
	rewarded_ready_changed.emit(placement, false)
	if error != null:
		push_warning("Rewarded-Ad '%s' konnte nicht geladen werden (%d): %s" % [placement, error.code, error.message])


func _on_native_reward(_reward: RewardedItem, placement: String) -> void:
	if placement == _active_rewarded_placement:
		_active_rewarded_placement = ""
		rewarded_completed.emit()


func _on_rewarded_closed(placement: String) -> void:
	_destroy_active_rewarded()
	_load_rewarded(placement)


func _on_rewarded_show_failed(_error: AdError, placement: String) -> void:
	_active_rewarded_placement = ""
	_destroy_active_rewarded()
	rewarded_unavailable.emit("Das Belohnungsvideo konnte nicht gestartet werden.")
	_load_rewarded(placement)


func _on_rewarded_noop() -> void:
	pass


func _on_rewarded_paid_noop(_ad_value: AdValue) -> void:
	pass


func _shutdown_ads(clear_loaders: bool = false) -> void:
	_active_rewarded_placement = ""
	_destroy_active_rewarded()
	for placement in _rewarded_ads.keys():
		var rewarded_ad = _rewarded_ads.get(placement)
		if rewarded_ad != null and rewarded_ad.has_method("destroy"):
			rewarded_ad.destroy()
		rewarded_ready_changed.emit(str(placement), false)
	_rewarded_ads.clear()
	if clear_loaders:
		_rewarded_loaders.clear()


func _destroy_active_rewarded() -> void:
	if _active_rewarded_ad != null:
		_active_rewarded_ad.destroy()
		_active_rewarded_ad = null
