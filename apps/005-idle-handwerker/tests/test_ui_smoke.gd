extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
	if ProjectSettings.get_setting("gui/theme/default_font_multichannel_signed_distance_field", true):
		failures += 1
		printerr("FAIL: MSDF fallback font rendering must stay disabled for iOS")
	var scene: PackedScene = load("res://main.tscn")
	var device_sizes := [
		Vector2i(320, 568),
		Vector2i(390, 844),
		Vector2i(430, 932),
		Vector2i(440, 956),
	]
	for device_size in device_sizes:
		root.size = device_size
		var app := scene.instantiate()
		root.add_child(app)
		await process_frame
		await process_frame
		var main_scroll: ScrollContainer = app.get("main_scroll")
		if not main_scroll or main_scroll.scroll_deadzone < 1:
			failures += 1
			printerr("FAIL: touch scrolling is not configured at %s" % device_size)
		var brand_title: Label = app.get("brand_title")
		if not brand_title or brand_title.get_combined_minimum_size().x <= 0.0:
			failures += 1
			printerr("FAIL: header text has no measurable width at %s" % device_size)
		var nav_buttons: Dictionary = app.get("nav_buttons")
		if nav_buttons.size() != 5:
			failures += 1
			printerr("FAIL: expected five navigation targets at %s" % device_size)
		for tab_id in ["betrieb", "auftraege", "ausbau", "team", "ziele"]:
			app.call("_switch_tab", tab_id)
			await process_frame
			var content: Control = app.get("content")
			if content.get_child_count() == 0:
				failures += 1
				printerr("FAIL: empty tab %s at %s" % [tab_id, device_size])
			var logical_width: float = float(app.size.x)
			if content.size.x > logical_width + 1.0:
				failures += 1
				printerr("FAIL: horizontal overflow in %s at %s: %.1f > %.1f logical" % [tab_id, device_size, content.size.x, logical_width])
			for control in _all_controls(content):
				if not control is BaseButton and control.mouse_filter == Control.MOUSE_FILTER_STOP:
					failures += 1
					printerr("FAIL: %s blocks touch scrolling in %s at %s" % [control.name, tab_id, device_size])
		app.queue_free()
		await process_frame
	if failures == 0:
		print("All responsive UI smoke tests passed.")
	quit(failures)


func _all_controls(node: Node) -> Array[Control]:
	var controls: Array[Control] = []
	for child in node.get_children():
		if child is Control:
			controls.append(child)
		controls.append_array(_all_controls(child))
	return controls
