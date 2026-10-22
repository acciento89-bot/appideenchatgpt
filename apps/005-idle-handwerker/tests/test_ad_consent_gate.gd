extends SceneTree
const Bridge = preload("res://scripts/monetization_bridge.gd")
class FakeBridge extends Bridge:
	var consent_status := 0
	var sdk_starts := 0
	func _current_ad_consent_status() -> int: return consent_status
	func _start_ads_sdk() -> void: sdk_starts += 1
class FakeAd extends RewardedAd:
	var was_destroyed := false
	func _init(): super(-101)
	func destroy() -> void: was_destroyed = true
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _init() -> void: call_deferred("run")
func run() -> void:
	# No native SDKs, real ads, purchases or reward transactions can run in this test.
	MobileAds._plugin = null
	RewardedAdLoader._plugin = null
	RewardedAd._plugin = null
	var initial = FakeBridge.new()
	initial._initialize_ads()
	check(not initial._ads_started, "unknown first session must not start ads")
	var has_session_gate := initial.get_property_list().any(func(p): return p.name == "_consent_update_requested")
	check(has_session_gate, "consent update must be recorded per session")
	initial.free()
	if not has_session_gate:
		quit(1)
		return
	for updated in [false, true]:
		for status in [-1, 0, 1, 2, 3]:
			var bridge = FakeBridge.new()
			bridge.set("_consent_update_requested", updated)
			bridge.consent_status = status
			bridge._initialize_ads()
			var allowed: bool = updated and status in [1, 3]
			check(bridge._ads_started == allowed, "session/status gate %s/%s" % [updated, status])
			check(bridge.sdk_starts == (1 if allowed else 0), "SDK only starts after allowed consent")
			bridge._initialize_ads()
			check(bridge.sdk_starts == (1 if allowed else 0), "repeated callbacks do not duplicate SDK initialization")
			bridge.free()
	var platform_bridge = FakeBridge.new()
	var has_platform_ids := platform_bridge.has_method("_rewarded_id_for_platform")
	check(has_platform_ids, "Android must not reuse the iOS rewarded placement")
	if has_platform_ids:
		var android_path := "monetization/admob/android/rewarded_boost_id"
		var ios_path := "monetization/admob/rewarded_boost_id"
		var original_android = ProjectSettings.get_setting(android_path, null)
		var original_ios = ProjectSettings.get_setting(ios_path, null)
		ProjectSettings.set_setting(android_path, "ca-app-pub-1111111111111111/1111111111")
		ProjectSettings.set_setting(ios_path, "ca-app-pub-2222222222222222/2222222222")
		check(platform_bridge.call("_rewarded_id_for_platform", "boost", "Android") == "ca-app-pub-1111111111111111/1111111111", "Android uses own placement")
		check(platform_bridge.call("_rewarded_id_for_platform", "boost", "iOS") == "ca-app-pub-2222222222222222/2222222222", "iOS keeps existing production workflow placement")
		ProjectSettings.set_setting(android_path, "ca-app-pub-3940256099942544/5224354917")
		check(platform_bridge.call("_rewarded_id_for_platform", "boost", "Android") == "", "Android release rejects example publisher")
		ProjectSettings.set_setting(android_path, null)
		check(platform_bridge.call("_rewarded_id_for_platform", "boost", "Android") == "", "missing Android placement never falls back to iOS/test ID")
		check(platform_bridge.call("_rewarded_id_for_platform", "unknown", "Android") == "", "unknown placement is rejected")
		ProjectSettings.set_setting(android_path, original_android)
		ProjectSettings.set_setting(ios_path, original_ios)
	platform_bridge.free()
	var changed = FakeBridge.new()
	changed.set("_consent_update_requested", true)
	changed.consent_status = 3
	changed._ads_started = true
	# Keep the fake bridge from initiating any load while testing invalidation.
	changed._ads_suspended = true
	var cached = FakeAd.new()
	changed._rewarded_ads["boost"] = cached
	changed._rewarded_loaders["boost"] = "old request"
	changed._on_privacy_options_closed(null)
	check(cached.was_destroyed and changed._rewarded_ads.is_empty(), "changed options discard cached ads even when status remains OBTAINED")
	check(changed._rewarded_loaders.is_empty(), "changed options invalidate in-flight requests")
	var current_generation: int = changed._ad_request_generation
	check(current_generation > 0, "privacy changes advance request generation")
	changed._rewarded_loaders["boost"] = "new request"
	var stale = FakeAd.new()
	changed._on_rewarded_loaded(stale, "boost", current_generation - 1)
	check(stale.was_destroyed and changed._rewarded_ads.is_empty(), "old obtained-session callback is destroyed")
	check(changed._rewarded_loaders.get("boost") == "new request", "stale success retains new loader")
	changed._on_rewarded_load_failed(null, "boost", current_generation - 1)
	check(changed._rewarded_loaders.get("boost") == "new request", "stale failure retains new loader")
	var active = FakeAd.new()
	changed._active_rewarded_ad = active
	changed._active_rewarded_placement = "boost"
	changed._on_native_reward(null, "boost", current_generation - 1)
	check(changed._active_rewarded_placement == "boost", "old reward cannot consume newer active placement")
	changed._on_rewarded_closed("boost", current_generation - 1)
	changed._on_rewarded_show_failed(null, "boost", current_generation - 1)
	check(not active.was_destroyed, "stale fullscreen callbacks cannot destroy newer active ad")
	changed._shutdown_ads(true)
	changed.free()
	var revoked = FakeBridge.new()
	revoked.set("_consent_update_requested", true)
	revoked.consent_status = 2
	var late = FakeAd.new()
	revoked._on_rewarded_loaded(late, "boost", revoked._ad_request_generation)
	check(late.was_destroyed and revoked._rewarded_ads.is_empty(), "late ad after revoked consent is discarded")
	revoked._on_consent_information_update_failed(null)
	check(revoked.sdk_starts == 0, "consent update error never bypasses required status")
	revoked.free()
	if failures == 0: print("ALL IDLE AD CONSENT TESTS PASSED: %d checks" % checks)
	quit(1 if failures else 0)
