extends SceneTree
const DispatchUI = preload("res://scripts/dispatch_panel.gd")
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var path := "user://dispatch-ui-%d.json" % OS.get_process_id()
	for dimensions in [Vector2i(320, 568), Vector2i(844, 390), Vector2i(744, 1133), Vector2i(1280, 720)]:
		root.size = dimensions
		var game = GameState.new()
		game.save_path = path
		game.employees = {"azubi": 1, "monteur": 1, "meisterin": 1}
		game.level = 10
		var panel = DispatchUI.new()
		panel.game = game
		root.add_child(panel)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await process_frame; await process_frame
		var staff: OptionButton = panel.find_child("DispatchEmployee", true, false)
		var order: OptionButton = panel.find_child("DispatchOrder", true, false)
		var pace: OptionButton = panel.find_child("DispatchPace", true, false)
		var assign: Button = panel.find_child("DispatchAssign", true, false)
		var quote: Label = panel.find_child("DispatchQuote", true, false)
		check(staff != null and order != null and pace != null and assign != null and quote != null, "actual board editable controls present at %s" % dimensions)
		if assign and quote:
			check(quote.text.contains("80 %") and quote.text.contains("28,00"), "actual default quote presents exact quality/reward")
			assign.pressed.emit()
			await process_frame; await process_frame
			check(game.dispatch_board.tasks.size() == 1, "actual assign control starts task")
			var selected_pace: int = pace.selected
			game.dispatch_board.advance(120.0)
			panel.refresh_progress()
			check(pace.selected == selected_pace, "timer refresh preserves visible selection")
			var collect: Button = panel.find_child("DispatchCollect*", true, false)
			check(collect != null and not collect.disabled, "finished actual task exposes enabled collect")
			if collect: collect.pressed.emit()
			await process_frame
			check(game.dispatch_board.tasks.is_empty() and is_equal_approx(game.money, 148.0), "actual collect pays exactly once")
		var logical: Vector2 = panel.get_viewport_rect().size
		print("DISPATCH LAYOUT physical=%s logical=%s panel=%s" % [dimensions, logical, panel.size])
		check(panel.size.x <= logical.x + 1.0, "panel respects resized logical viewport width")
		var scroll: ScrollContainer = panel.find_child("DispatchScroll", true, false)
		if scroll: print("DISPATCH SCROLL height=%s available=%s" % [scroll.size.y, logical.y])
		check(scroll != null and scroll.size.y <= logical.y, "short or wide board remains scrollable inside logical window")
		panel.queue_free(); await process_frame
		game.free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures == 0: print("ALL IDLE DISPATCH UI TESTS PASSED: %d checks" % checks)
	quit(1 if failures else 0)
