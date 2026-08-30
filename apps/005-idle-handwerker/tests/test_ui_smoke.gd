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
		for property in ["money_label", "income_label", "reputation_label"]:
			var status_label: Label = app.get(property)
			if not status_label or status_label.text == "" or status_label.text.contains("..."):
				failures += 1
				printerr("FAIL: header status '%s' is missing or truncated at %s" % [property, device_size])
			elif status_label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
				failures += 1
				printerr("FAIL: header status '%s' allows ellipsis at %s" % [property, device_size])
		var app_font: FontFile = app.get("app_font")
		if not app.theme or not app_font or app_font.data.is_empty() or app.theme.default_font != app_font:
			failures += 1
			printerr("FAIL: embedded app font is not active at %s" % device_size)
		var nav_buttons: Dictionary = app.get("nav_buttons")
		if nav_buttons.size() != 5:
			failures += 1
			printerr("FAIL: expected five navigation targets at %s" % device_size)
		var settings_button: Button = app.get("settings_button")
		var store_button: Button = app.get("store_button")
		if not settings_button or settings_button.text != "" or not settings_button.icon:
			failures += 1
			printerr("FAIL: settings header action is not a gear icon at %s" % device_size)
		if not store_button or store_button.text != "SHOP":
			failures += 1
			printerr("FAIL: shop is not a separate header action at %s" % device_size)
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
				if control.mouse_filter == Control.MOUSE_FILTER_STOP:
					failures += 1
					printerr("FAIL: %s blocks touch scrolling in %s at %s" % [control.name, tab_id, device_size])
			for label in _all_labels(content):
				var font := label.get_theme_font("font")
				if not font or font != app_font:
					failures += 1
					printerr("FAIL: label '%s' has no embedded font in %s at %s" % [label.text, tab_id, device_size])
				if label.text != "" and label.get_combined_minimum_size().y <= 0.0:
					failures += 1
					printerr("FAIL: label '%s' has no measurable height in %s at %s" % [label.text, tab_id, device_size])
				if label.text.length() >= 4 and not label.text.contains("\n") and label.size.x < 40.0 and label.size.y > 40.0:
					failures += 1
					printerr("FAIL: vertically collapsed label '%s' in %s at %s" % [label.text, tab_id, device_size])
			if tab_id == "team":
				for expected_text in ["TEAMRANG", "Mitarbeiter", "Azubi", "Monteur", "Meisterin"]:
					if not _has_label(content, expected_text):
						failures += 1
						printerr("FAIL: team progression label '%s' is missing at %s" % [expected_text, device_size])
			if tab_id == "auftraege":
				var section_action := _find_label(content, "STANDORTBONUS")
				if not section_action or section_action.autowrap_mode != TextServer.AUTOWRAP_OFF:
					failures += 1
					printerr("FAIL: section action can wrap vertically at %s" % device_size)
		app.call("_show_settings")
		await process_frame
		for expected_button in ["TUTORIAL ERNEUT ANSEHEN", "SPIELSTAND ZURÜCKSETZEN", "FERTIG"]:
			if not _has_button(app, expected_button):
				failures += 1
				printerr("FAIL: release setting '%s' is missing at %s" % [expected_button, device_size])
		var has_settings_scroll := false
		for control in _all_controls(app):
			if control is ScrollContainer and control != main_scroll and control.scroll_deadzone >= 1:
				has_settings_scroll = true
		if not has_settings_scroll:
			failures += 1
			printerr("FAIL: settings are not touch-scrollable at %s" % device_size)
		var sound_action := _find_button_prefix(app, "SOUND\n")
		if not _has_scroll_safe_button_skin(sound_action):
			failures += 1
			printerr("FAIL: settings action shows false pressed feedback while scrolling at %s" % device_size)
		for forbidden_shop_button in ["WERBEFREI KAUFEN", "STARTERPAKET", "250 BONUSMARKEN"]:
			if _has_button(app, forbidden_shop_button):
				failures += 1
				printerr("FAIL: shop action '%s' still appears inside settings at %s" % [forbidden_shop_button, device_size])
		var settings_close := _find_button(app, "X")
		if not settings_close:
			failures += 1
			printerr("FAIL: pinned settings close button is missing at %s" % device_size)
		else:
			settings_close.pressed.emit()
			await process_frame
			if _has_label(app, "Optionen"):
				failures += 1
				printerr("FAIL: settings cannot be closed at %s" % device_size)
		app.call("_show_store")
		await process_frame
		for expected_shop_button in ["WERBEFREI KAUFEN", "STARTERPAKET", "250 BONUSMARKEN", "SHOP SCHLIESSEN"]:
			if not _has_button(app, expected_shop_button):
				failures += 1
				printerr("FAIL: separate shop action '%s' is missing at %s" % [expected_shop_button, device_size])
		if not _has_scroll_safe_button_skin(_find_button(app, "STARTERPAKET")):
			failures += 1
			printerr("FAIL: shop action shows false pressed feedback while scrolling at %s" % device_size)
		var shop_close := _find_button(app, "SHOP SCHLIESSEN")
		if shop_close:
			shop_close.pressed.emit()
			await process_frame
			if _has_label(app, "Bonus & Käufe"):
				failures += 1
				printerr("FAIL: shop cannot be closed at %s" % device_size)
		app.call("_show_location_restart_confirmation", "downtown")
		await process_frame
		for expected_text in ["SHK · BETRIEBSENTSCHEIDUNG", "NEUER STANDORT · 02"]:
			if not _has_label(app, expected_text):
				failures += 1
				printerr("FAIL: themed city-change text '%s' is missing at %s" % [expected_text, device_size])
		for expected_button in ["BETRIEB ERÖFFNEN", "ABBRECHEN"]:
			if not _has_button(app, expected_button):
				failures += 1
				printerr("FAIL: themed city-change action '%s' is missing at %s" % [expected_button, device_size])
		if _has_native_confirmation_dialog(app):
			failures += 1
			printerr("FAIL: city change still uses an unreadable native dialog at %s" % device_size)
		var game = app.get("game")
		game.offline_reward = 125.0
		game.offline_elapsed_seconds = 3600.0
		app.call("_show_offline_dialog")
		await process_frame
		if not _has_button(app, "EINNAHMEN EINSAMMELN"):
			failures += 1
			printerr("FAIL: themed offline return screen is missing at %s" % device_size)
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


func _all_labels(node: Node) -> Array[Label]:
	var labels: Array[Label] = []
	for child in node.get_children():
		if child is Label:
			labels.append(child)
		labels.append_array(_all_labels(child))
	return labels


func _has_button(node: Node, text: String) -> bool:
	return _find_button(node, text) != null


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var nested := _find_button(child, text)
		if nested:
			return nested
	return null


func _find_button_prefix(node: Node, prefix: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text.begins_with(prefix):
			return child
		var nested := _find_button_prefix(child, prefix)
		if nested:
			return nested
	return null


func _has_scroll_safe_button_skin(button: Button) -> bool:
	if not button or button.focus_mode != Control.FOCUS_NONE or button.mouse_filter != Control.MOUSE_FILTER_PASS:
		return false
	var normal := button.get_theme_stylebox("normal")
	var hover := button.get_theme_stylebox("hover")
	var pressed := button.get_theme_stylebox("pressed")
	if not normal is StyleBoxTexture or not hover is StyleBoxTexture or not pressed is StyleBoxTexture:
		return false
	return normal.texture == hover.texture and normal.texture == pressed.texture


func _has_label(node: Node, text: String) -> bool:
	return _find_label(node, text) != null


func _find_label(node: Node, text: String) -> Label:
	for child in node.get_children():
		if child is Label and child.text == text:
			return child
		var nested := _find_label(child, text)
		if nested:
			return nested
	return null


func _has_native_confirmation_dialog(node: Node) -> bool:
	for child in node.get_children():
		if child is ConfirmationDialog:
			return true
		if _has_native_confirmation_dialog(child):
			return true
	return false
