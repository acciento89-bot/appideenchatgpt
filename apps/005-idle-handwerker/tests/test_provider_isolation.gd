extends SceneTree
# Removing the QA guards would invoke the fake store, poll its transaction queue,
# or grant rewards. External native providers are replaced; bridge logic is real.
const Bridge = preload("res://scripts/monetization_bridge.gd")
class FakeStore extends RefCounted:
	var calls := 0
	func purchase(_request: Dictionary) -> int:
		calls += 1
		return OK
	func restore_purchases() -> int:
		calls += 1
		return OK
	func pop_pending_event() -> Variant:
		calls += 1
		return null
	func get_pending_event_count() -> int:
		calls += 1
		return 0
class BoundaryBridge extends Bridge:
	var setup_calls := 0
	func _setup_storekit() -> void: setup_calls += 1
	func _setup_android_store() -> void: setup_calls += 1
	func _start_consent_flow() -> void: setup_calls += 1
	func _current_ad_consent_status() -> int: return 3
	func _start_ads_sdk() -> void: setup_calls += 1
var failures := 0
var checks := 0
var grants := 0
var restores := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + label)
func _init() -> void: call_deferred("run")
func run() -> void:
	var flag := "--idlehandwerkerProviderDisabledQA"
	var isolated := OS.get_cmdline_args().has(flag) or OS.get_cmdline_user_args().has(flag)
	var bridge := BoundaryBridge.new()
	var store := FakeStore.new()
	bridge._store = store
	bridge.purchase_completed.connect(func(_id, _tx): grants += 1)
	bridge.rewarded_completed.connect(func(): grants += 1)
	bridge.restore_completed.connect(func(_message): restores += 1)
	bridge._ready()
	bridge.purchase(Bridge.PRODUCTS[0])
	bridge.restore_purchases()
	bridge._process(0)
	bridge._consent_update_requested = true
	bridge._initialize_ads()
	bridge._handle_store_event({"type":"purchase", "result":"ok", "product_id":Bridge.PRODUCTS[0], "transaction_id":"FAKE-ONLY"})
	bridge._active_rewarded_placement = "boost"
	bridge._on_native_reward(null, "boost", bridge._ad_request_generation)
	if isolated:
		check(bridge.setup_calls == 0, "explicit QA initializes no store or ads")
		check(store.calls == 0, "explicit QA performs no purchase, restore or polling")
		check(grants == 0 and restores == 0, "explicit QA never grants or reconciles rewards/entitlements")
		check(not bridge._can_request_ads(), "explicit QA cannot request ads after lifecycle callbacks")
	else:
		check(bridge.setup_calls == 2, "ordinary Debug keeps setup and allowed fake SDK initialization")
		check(store.calls == 3, "ordinary Debug keeps fake purchase/restore/polling; actual=%d" % store.calls)
		check(grants == 2, "ordinary Debug keeps fake transaction and reward processing")
	if bridge.has_method("provider_qa_policy"):
		check(not bridge.call("provider_qa_policy", false, PackedStringArray([flag])), "shipping Release ignores QA flag")
		check(not bridge.call("provider_qa_policy", true, PackedStringArray()), "ordinary Debug ignores absent flag")
		check(bridge.call("provider_qa_policy", true, PackedStringArray([flag])), "explicit Debug flag enables isolation")
	else:
		check(false, "debug-only QA policy exists")
	bridge.free()
	if failures == 0: print("ALL IDLE PROVIDER ISOLATION TESTS PASSED: %d checks; QA=%s" % [checks, isolated])
	quit(1 if failures else 0)
