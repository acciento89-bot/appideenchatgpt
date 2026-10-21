extends SceneTree

const Board = preload("res://scripts/dispatch_board.gd")
const Geometry = preload("res://scripts/responsive_geometry.gd")
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _init() -> void:
	var board = Board.new()
	var normal: Dictionary = board.quote("armaturen", "azubi", "normal", "sanitaer")
	check(normal.quality == 80 and normal.duration == 120.0 and normal.reward_cents == 2800, "normal matching apprentice exact quote")
	var fast: Dictionary = board.quote("armaturen", "azubi", "schnell", "sanitaer")
	check(fast.quality == 68 and fast.duration == 90.0 and fast.reward_cents == 2380, "quick quality-duration-reward tradeoff")
	var careful: Dictionary = board.quote("armaturen", "azubi", "sorgfalt", "sanitaer")
	check(careful.quality == 88 and careful.duration == 168.0 and careful.reward_cents == 3080, "careful tradeoff")
	check(board.quote("armaturen", "azubi", "normal", "heizung").quality == 72, "unmatched specialization has no bonus")
	check(board.quote("armaturen", "meisterin", "normal", "sanitaer").quality == 88, "experience contributes explicit bounded quality")
	check(board.quote("unknown", "azubi", "normal", "sanitaer").is_empty(), "unknown order rejected")
	check(board.quote("armaturen", "unknown", "normal", "sanitaer").is_empty(), "unknown employee rejected")
	check(board.quote("armaturen", "azubi", "bad", "sanitaer").is_empty(), "unknown pace rejected")
	check(board.quote("armaturen", "azubi", "normal", "bad").is_empty(), "unknown specialization rejected")
	var staff := {"azubi": 1, "monteur": 1, "meisterin": 1}
	check(board.assign("armaturen", "azubi", "normal", {}, 10) == "", "no phantom employee")
	check(board.assign("heizcheck", "azubi", "normal", staff, 1) == "", "order level gate")
	var first: String = board.assign("armaturen", "azubi", "normal", staff, 10)
	check(first != "" and board.tasks.size() == 1, "assignment consumes one board slot")
	check(board.assign("armaturen", "monteur", "normal", staff, 10) == "", "same archetype cannot run twice")
	check(board.assign("heizcheck", "azubi", "normal", staff, 10) == "", "one hired unit cannot back two tasks")
	check(board.set_specialization("azubi", "heizung"), "specialization preference editable")
	check(board.tasks[0].quality == 80 and board.tasks[0].specialization == "sanitaer", "running quote remains independent snapshot")
	check(not board.set_specialization("azubi", "bad"), "invalid specialization rejected")
	var second: String = board.assign("heizcheck", "monteur", "normal", staff, 10)
	var third: String = board.assign("planung", "meisterin", "normal", staff, 10)
	check(second != "" and third != "" and board.tasks.size() == 3, "three bounded concurrent service orders")
	check(board.assign("armaturen", "azubi", "normal", {"azubi": 99}, 10) == "", "capacity fixed at three")
	check(board.collect(first).is_empty(), "unfinished task not collectible")
	board.advance(-1.0)
	board.advance(INF)
	board.advance(NAN)
	check(board.tasks[0].remaining == 120.0, "invalid elapsed does not mutate timers")
	board.advance(60.0)
	check(board.tasks[0].remaining == 60.0 and board.collect(first).is_empty(), "timer advances exactly once")
	var encoded: Dictionary = board.to_payload()
	var restored = Board.from_payload(encoded)
	check(restored != null and restored.to_payload() == encoded, "JSON value archive roundtrip preserves exact active snapshots")
	encoded.tasks[0].remaining = 1.0
	check(board.tasks[0].remaining == 60.0, "serialized dictionaries do not alias running board")
	board.advance(60.0)
	var receipt: Dictionary = board.collect(first)
	check(receipt.reward_cents == 2800 and receipt.quality == 80 and board.tasks.size() == 2, "explicit collect yields frozen bonus and frees slot")
	check(board.collect(first).is_empty(), "repeat collect grants nothing")
	var new_id: String = board.assign("armaturen", "azubi", "normal", staff, 10)
	check(new_id != first and new_id != "", "task identities monotonic after collection")
	board.advance(1.0e20)
	check(board.tasks.all(func(task: Dictionary) -> bool: return task.remaining == 0.0), "bounded offline advancement finishes finite tasks without autostart")
	check(board.tasks.size() == 3, "finished tasks still occupy resources until collect")
	for task in board.tasks.duplicate(true):
		board.collect(task.id)
	check(board.history.size() == 4, "completion receipts retained")
	for index in range(6):
		var id: String = board.assign("armaturen", "azubi", "normal", staff, 10)
		board.advance(1000.0)
		board.collect(id)
	check(board.history.size() == 5, "receipt history bounded at five")
	check(Board.from_payload({}) == null, "missing board field migrated by caller only; malformed present board fails")
	var valid: Dictionary = board.to_payload()
	var bad: Dictionary = valid.duplicate(true)
	bad.schema_version = 2
	check(Board.from_payload(bad) == null, "future version cannot silently overwrite")
	bad = valid.duplicate(true)
	bad.profiles.azubi = "bad"
	check(Board.from_payload(bad) == null, "malformed saved profile rejected")
	bad = valid.duplicate(true)
	bad.next_id = 1
	check(Board.from_payload(bad) == null, "reused monotonic identity rejected against history")
	var working = Board.new()
	working.assign("armaturen", "azubi", "normal", staff, 10)
	var live: Dictionary = working.to_payload()
	bad = live.duplicate(true)
	bad.tasks[0].reward_cents = 999999
	check(Board.from_payload(bad) == null, "tampered noncanonical quote rejected")
	bad = live.duplicate(true)
	bad.tasks[0].remaining = -1
	check(Board.from_payload(bad) == null, "negative timer rejected")
	bad = live.duplicate(true)
	bad.tasks.append(bad.tasks[0].duplicate(true))
	check(Board.from_payload(bad) == null, "duplicate task identity rejected")
	bad = live.duplicate(true)
	bad.tasks[0].remaining = "20"
	check(Board.from_payload(bad) == null, "coerced timer text rejected")
	check(Geometry.insets(Rect2i(0, 0, 1000, 2000), Rect2i(30, 100, 930, 1800), Vector2(500, 1000)) == Vector4(15, 50, 20, 50), "all four screen safe edges map to logical window")
	check(Geometry.insets(Rect2i(100, 200, 600, 800), Rect2i(0, 100, 1000, 1800), Vector2(300, 400)) == Vector4.ZERO, "window contained by safe area needs no fullscreen insets")
	check(Geometry.insets(Rect2i(100, 50, 600, 800), Rect2i(120, 80, 550, 700), Vector2(300, 400)) == Vector4(10, 15, 15, 35), "translated window scales safe intersection exactly")
	check(Geometry.insets(Rect2i(0, 0, 0, 0), Rect2i(0, 0, 100, 100), Vector2(300, 400)) == Vector4.ZERO, "invalid geometry safe fallback")
	check(Geometry.insets(Rect2i(0, 0, 600, 800), Rect2i(900, 900, 100, 100), Vector2(300, 400)) == Vector4.ZERO, "disjoint safe area does not invent giant margins")
	if failures == 0:
		print("ALL IDLE DISPATCH BOARD TESTS PASSED: %d checks" % checks)
	quit(1 if failures else 0)
