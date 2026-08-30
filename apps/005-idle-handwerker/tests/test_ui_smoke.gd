extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
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
			if content.size.x > float(device_size.x) + 1.0:
				failures += 1
				printerr("FAIL: horizontal overflow in %s at %s: %.1f" % [tab_id, device_size, content.size.x])
		app.queue_free()
		await process_frame
	if failures == 0:
		print("All responsive UI smoke tests passed.")
	quit(failures)
