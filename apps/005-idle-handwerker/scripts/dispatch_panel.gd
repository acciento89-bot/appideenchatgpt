class_name DispatchPanel
extends VBoxContainer

signal close_requested
var game: GameState
var employee_picker: OptionButton
var order_picker: OptionButton
var pace_picker: OptionButton
var quote_label: Label
var assign_button: Button
var task_box: VBoxContainer
var history_box: VBoxContainer
var status_label: Label
var _signature := ""
var _progress_controls: Dictionary = {}
var _profile_pickers: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var heading := HBoxContainer.new()
	add_child(heading)
	var title := _label("TEAM-EINSATZTAFEL", 19)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := _button("X")
	close.tooltip_text = "Einsatztafel schließen"
	close.custom_minimum_size = Vector2(44, 44)
	close.pressed.connect(func() -> void: close_requested.emit())
	heading.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.name = "DispatchScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	scroll.follow_focus = true
	add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	body.add_child(_label("Bis zu drei kleine Teamaufträge parallel. Dein bestehendes passives Personal- und Vertragseinkommen läuft unverändert weiter. Teamboni geben keine Auftrags-XP, Bewertungen oder Serienpunkte.", 12))
	body.add_child(_label("SPEZIALISIERUNGEN", 15))
	body.add_child(_label("Gilt für neue Einsätze dieses Mitarbeitertyps. Laufende Einsätze behalten ihre Auswahl und ihren Bonus.", 12))
	for employee in DispatchBoard.STAFF:
		var row := VBoxContainer.new()
		body.add_child(row)
		row.add_child(_label(_staff_title(employee), 13))
		var picker := OptionButton.new()
		picker.custom_minimum_size.y = 44
		picker.mouse_filter = Control.MOUSE_FILTER_PASS
		for specialty in DispatchBoard.SPECIALIZATIONS:
			picker.add_item(_specialty_title(specialty))
		picker.select(DispatchBoard.SPECIALIZATIONS.find(game.dispatch_board.profiles[employee]))
		picker.item_selected.connect(func(index: int) -> void:
			if not game.dispatch_specialize(employee, DispatchBoard.SPECIALIZATIONS[index]):
				picker.select(DispatchBoard.SPECIALIZATIONS.find(game.dispatch_board.profiles[employee]))
			_refresh_quote()
		)
		_profile_pickers[employee] = picker
		row.add_child(picker)
	body.add_child(_label("NEUEN TEAMEINSATZ PLANEN", 15))
	employee_picker = _picker("DispatchEmployee", ["Azubi", "Monteur", "Meisterin"])
	body.add_child(_label("Mitarbeitertyp", 12)); body.add_child(employee_picker)
	var order_titles: Array[String] = []
	for order in DispatchBoard.ORDERS: order_titles.append(str(order.title) + " · Stufe %d" % int(order.level))
	order_picker = _picker("DispatchOrder", order_titles)
	body.add_child(_label("Teamauftrag", 12)); body.add_child(order_picker)
	pace_picker = _picker("DispatchPace", ["Schnell · −12 Qualität", "Normal · ausgeglichen", "Sorgfalt · +8 Qualität"])
	pace_picker.select(1)
	body.add_child(_label("Arbeitsweise", 12)); body.add_child(pace_picker)
	quote_label = _label("", 15)
	quote_label.name = "DispatchQuote"
	body.add_child(quote_label)
	status_label = _label("", 12)
	body.add_child(status_label)
	assign_button = _button("Einsatz starten")
	assign_button.name = "DispatchAssign"
	assign_button.pressed.connect(func() -> void:
		game.dispatch_assign(str(DispatchBoard.ORDERS[order_picker.selected].id), DispatchBoard.STAFF[employee_picker.selected], DispatchBoard.PACES[pace_picker.selected])
		refresh_progress()
	)
	body.add_child(assign_button)
	for picker in [employee_picker, order_picker, pace_picker]:
		picker.item_selected.connect(func(_index: int) -> void: _refresh_quote())
	body.add_child(_label("LAUFENDE EINSÄTZE", 15))
	body.add_child(_label("Fertige Einsätze belegen bis zum Einsammeln einen Mitarbeiter und Einsatzplatz. Offline laufen die Timer höchstens acht Stunden weiter; es startet kein Folgeauftrag.", 12))
	task_box = VBoxContainer.new()
	task_box.add_theme_constant_override("separation", 12)
	body.add_child(task_box)
	body.add_child(_label("LETZTE EINGESAMMELTE EINSÄTZE", 15))
	history_box = VBoxContainer.new()
	history_box.add_theme_constant_override("separation", 8)
	body.add_child(history_box)
	var bottom_close := _button("Einsatztafel schließen")
	bottom_close.pressed.connect(func() -> void: close_requested.emit())
	add_child(bottom_close)
	refresh_progress()

func _process(_delta: float) -> void:
	refresh_progress()

func _picker(id: String, labels: Array) -> OptionButton:
	var picker := OptionButton.new()
	picker.name = id
	picker.fit_to_longest_item = false
	picker.clip_text = true
	picker.custom_minimum_size.y = 44
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.mouse_filter = Control.MOUSE_FILTER_PASS
	for label in labels: picker.add_item(str(label))
	return picker

func _label(text: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color("f4f8fb"))
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.add_theme_stylebox_override("normal", UiSkin.primary_button())
	button.add_theme_stylebox_override("hover", UiSkin.primary_button())
	button.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	button.add_theme_stylebox_override("disabled", UiSkin.dark_button())
	button.add_theme_color_override("font_color", Color("f4f8fb"))
	button.add_theme_font_size_override("font_size", 13)
	return button

func _staff_title(id: String) -> String:
	return {"azubi": "Azubi", "monteur": "Monteur", "meisterin": "Meisterin"}.get(id, id)

func _specialty_title(id: String) -> String:
	return {"sanitaer": "Sanitär", "heizung": "Heizung", "planung": "Planung"}.get(id, id)

func _refresh_quote() -> void:
	if not is_instance_valid(quote_label): return
	var staff: String = DispatchBoard.STAFF[employee_picker.selected]
	var order: Dictionary = DispatchBoard.ORDERS[order_picker.selected]
	var pace: String = DispatchBoard.PACES[pace_picker.selected]
	var specialty: String = game.dispatch_board.profiles[staff]
	var result: Dictionary = game.dispatch_board.quote(str(order.id), staff, pace, specialty)
	quote_label.text = "%d %% Qualität · %d Sek.\nBonus: %s · %s" % [int(result.quality), int(ceil(float(result.duration))), GameData.format_money(float(result.reward_cents) / 100.0, true), _specialty_title(specialty)]
	var duplicate := false
	for task in game.dispatch_board.tasks:
		if task.order_id == order.id: duplicate = true
	var available := game.dispatch_available(staff)
	assign_button.disabled = game.storage_blocked or available < 1 or game.level < int(order.level) or duplicate or game.dispatch_board.tasks.size() >= DispatchBoard.MAX_TASKS
	status_label.text = "%d frei · %d / 3 Einsatzplätze" % [available, game.dispatch_board.tasks.size()]
	if game.storage_blocked:
		status_label.text += "\nSpielstand konnte nicht geladen werden. Vorhandene Daten bleiben erhalten. Bitte Speicher prüfen und App neu starten."
	elif game.level < int(order.level): status_label.text += "\nVerfügbar ab Betriebsstufe %d." % int(order.level)
	elif duplicate: status_label.text += "\nDieser Teamauftrag läuft bereits."
	elif available == 0: status_label.text += "\nZuerst Mitarbeiter einstellen oder fertigen Einsatz einsammeln."

func refresh_progress() -> void:
	if not is_instance_valid(task_box): return
	var signature := JSON.stringify([game.dispatch_board.tasks.map(func(task: Dictionary) -> Array: return [task.id]), game.dispatch_board.history])
	if signature != _signature:
		_signature = signature
		for child in task_box.get_children(): child.queue_free()
		for child in history_box.get_children(): child.queue_free()
		_progress_controls.clear()
		if game.dispatch_board.tasks.is_empty(): task_box.add_child(_label("Kein Teameinsatz aktiv.", 13))
		for task in game.dispatch_board.tasks:
			var card := VBoxContainer.new()
			card.add_theme_constant_override("separation", 5)
			task_box.add_child(card)
			card.add_child(_label(str(game.dispatch_board.order_for(task.order_id).title), 15))
			card.add_child(_label("%s · %s · %d %% · %s" % [_staff_title(task.employee_id), _specialty_title(task.specialization), int(task.quality), GameData.format_money(float(task.reward_cents) / 100.0, true)], 12))
			var timer := _label("", 13)
			card.add_child(timer)
			var collect := _button("Bonus einsammeln")
			collect.name = "DispatchCollect" + str(task.id)
			collect.disabled = float(task.remaining) > 0.0 or game.storage_blocked
			var id: String = task.id
			collect.pressed.connect(func() -> void: game.dispatch_collect(id); refresh_progress())
			card.add_child(collect)
			_progress_controls[task.id] = {"timer": timer, "collect": collect}
		if game.dispatch_board.history.is_empty(): history_box.add_child(_label("Noch kein Teameinsatz eingesammelt.", 12))
		for receipt in game.dispatch_board.history:
			history_box.add_child(_label("%s · %s · %d %% · %s" % [str(game.dispatch_board.order_for(receipt.order_id).title), _staff_title(receipt.employee_id), int(receipt.quality), GameData.format_money(float(receipt.reward_cents) / 100.0, true)], 12))
	for task in game.dispatch_board.tasks:
		if _progress_controls.has(task.id):
			_progress_controls[task.id].timer.text = "Fertig · Bonus abholen" if float(task.remaining) <= 0.0 else "%s verbleibend" % game.format_cooldown(float(task.remaining))
			_progress_controls[task.id].collect.disabled = float(task.remaining) > 0.0 or game.storage_blocked
	_refresh_quote()
