extends Control

const BG := Color("0b1714")
const SURFACE := Color("13231e")
const SURFACE_2 := Color("193029")
const TEXT := Color("f4fbf7")
const MUTED := Color("9eb5aa")
const GREEN := Color("49d28b")
const GREEN_DARK := Color("183f30")
const GOLD := Color("f3b553")
const RED := Color("ef756b")

var game: GameState
var sfx: SfxBank
var current_tab := "betrieb"
var content: VBoxContainer
var money_label: Label
var level_label: Label
var income_label: Label
var progress_bar: ProgressBar
var job_label: Label
var job_time_label: Label
var primary_button: Button
var workshop_visual: WorkshopVisual
var toast_layer: Control
var last_money_display := -1.0
var nav_buttons: Dictionary = {}


func _ready() -> void:
	set_process(false)
	game = GameState.new()
	add_child(game)
	sfx = SfxBank.new()
	add_child(sfx)
	game.job_completed.connect(_on_job_completed)
	game.level_up.connect(_on_level_up)
	game.notice.connect(_show_toast)
	_build_shell()
	_switch_tab("betrieb")
	set_process(true)
	if game.offline_reward > 0.0:
		_show_offline_dialog()


func _process(_delta: float) -> void:
	_update_live_header()
	_update_active_job()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var safe_top := MarginContainer.new()
	safe_top.add_theme_constant_override("margin_left", 20)
	safe_top.add_theme_constant_override("margin_right", 20)
	safe_top.add_theme_constant_override("margin_top", 18)
	safe_top.add_theme_constant_override("margin_bottom", 12)
	root.add_child(safe_top)
	safe_top.add_child(_build_header())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	root.add_child(_build_nav())

	toast_layer = Control.new()
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(toast_layer)


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var eyebrow := _label("KAMILUNAVO GAMES", 10, GREEN)
	eyebrow.add_theme_constant_override("letter_spacing", 1)
	brand.add_child(eyebrow)
	var title := _label("IDLE HANDWERKER", 23, TEXT, true)
	brand.add_child(title)
	row.add_child(brand)

	var balance := VBoxContainer.new()
	balance.alignment = BoxContainer.ALIGNMENT_CENTER
	money_label = _label("120 €", 20, TEXT, true)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance.add_child(money_label)
	income_label = _label("+0 €/s", 11, GREEN)
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance.add_child(income_label)
	row.add_child(balance)
	return row


func _build_nav() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(SURFACE, 0, Color.TRANSPARENT, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)
	var items := [
		["betrieb", "Betrieb", "HA"],
		["auftraege", "Aufträge", "AU"],
		["ausbau", "Ausbau", "UP"],
		["team", "Team", "TE"],
	]
	for item in items:
		var button := Button.new()
		button.name = "nav_%s" % item[0]
		button.text = "%s\n%s" % [item[2], item[1]]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 58
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_switch_tab.bind(item[0]))
		row.add_child(button)
		nav_buttons[item[0]] = button
	return panel


func _switch_tab(tab_id: String) -> void:
	current_tab = tab_id
	for child in content.get_children():
		child.queue_free()
	for id in ["betrieb", "auftraege", "ausbau", "team"]:
		var button: Button = nav_buttons.get(id)
		if button:
			_style_nav(button, id == tab_id)
	match tab_id:
		"betrieb": _build_dashboard()
		"auftraege": _build_jobs()
		"ausbau": _build_upgrades()
		"team": _build_team()


func _build_dashboard() -> void:
	var hero := PanelContainer.new()
	hero.custom_minimum_size.y = 238
	hero.add_theme_stylebox_override("panel", _box(Color("1b3c2e"), 24, Color("2c6048"), 1))
	var hero_margin := MarginContainer.new()
	_set_margins(hero_margin, 20, 20, 18, 18)
	hero.add_child(hero_margin)
	var hero_v := VBoxContainer.new()
	hero_v.add_theme_constant_override("separation", 9)
	hero_margin.add_child(hero_v)
	var top := HBoxContainer.new()
	var badge := _pill("DEIN BETRIEB", GREEN_DARK, GREEN)
	top.add_child(badge)
	top.add_spacer(false)
	level_label = _label("STUFE %d" % game.level, 12, GOLD, true)
	top.add_child(level_label)
	hero_v.add_child(top)

	var scene_row := HBoxContainer.new()
	scene_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_child(_label(_business_title(), 24, TEXT, true))
	copy.add_child(_label(_business_subtitle(), 13, MUTED))
	scene_row.add_child(copy)
	workshop_visual = WorkshopVisual.new()
	workshop_visual.custom_minimum_size = Vector2(162, 112)
	workshop_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_row.add_child(workshop_visual)
	hero_v.add_child(scene_row)

	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 10
	progress_bar.add_theme_stylebox_override("background", _box(Color("0d2119"), 6))
	progress_bar.add_theme_stylebox_override("fill", _box(GREEN, 6))
	hero_v.add_child(progress_bar)
	var job_row := HBoxContainer.new()
	job_label = _label("Bereit für den nächsten Auftrag", 12, TEXT, true)
	job_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	job_row.add_child(job_label)
	job_time_label = _label("", 12, GREEN, true)
	job_row.add_child(job_time_label)
	hero_v.add_child(job_row)
	content.add_child(hero)

	primary_button = Button.new()
	primary_button.text = "AUFTRAG STARTEN"
	primary_button.custom_minimum_size.y = 62
	primary_button.add_theme_font_size_override("font_size", 17)
	primary_button.add_theme_color_override("font_color", Color("071811"))
	primary_button.add_theme_stylebox_override("normal", _box(GREEN, 18))
	primary_button.add_theme_stylebox_override("hover", _box(Color("63e3a0"), 18))
	primary_button.add_theme_stylebox_override("pressed", _box(Color("2dbd76"), 18))
	primary_button.pressed.connect(_primary_action)
	content.add_child(primary_button)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 9)
	stat_row.add_child(_stat_card("AUFTRÄGE", str(game.completed_jobs), "erledigt"))
	stat_row.add_child(_stat_card("TEAM", str(_employee_count()), "Mitarbeiter"))
	stat_row.add_child(_stat_card("SERIE", "%d×" % game.current_streak, "max. %d×" % game.best_streak))
	content.add_child(stat_row)

	content.add_child(_section_title("Nächster Meilenstein", "MEHR"))
	content.add_child(_milestone_card())


func _build_jobs() -> void:
	content.add_child(_page_intro("Auftragsbörse", "Wähle Aufträge, verdiene Geld und steigere deinen Ruf."))
	for job in GameData.JOBS:
		content.add_child(_job_card(job))


func _build_upgrades() -> void:
	content.add_child(_page_intro("Betrieb ausbauen", "Investiere in Tempo, Qualität und automatisierte Einnahmen."))
	for upgrade in GameData.UPGRADES:
		content.add_child(_upgrade_card(upgrade))


func _build_team() -> void:
	content.add_child(_page_intro("Dein Team", "Mitarbeiter arbeiten weiter – auch wenn du nicht spielst."))
	var passive := _highlight_card("PASSIVES EINKOMMEN", GameData.format_money(game.passive_income_per_second(), true) + " / Sek.", "Offline bis zu 8 Stunden")
	content.add_child(passive)
	for employee in GameData.EMPLOYEES:
		content.add_child(_employee_card(employee))


func _job_card(job: Dictionary) -> Control:
	var card := _card_container()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	card.get_child(0).get_child(0).add_child(row)
	row.add_child(_icon_box(str(job.icon), job.color))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label(str(job.title), 16, TEXT, true))
	copy.add_child(_label(str(job.customer) + "  •  " + str(int(job.duration)) + " Sek.", 11, MUTED))
	var reward := float(job.reward) * game.job_reward_multiplier()
	copy.add_child(_label(GameData.format_money(reward) + "  +%d XP" % int(job.xp), 12, GREEN, true))
	row.add_child(copy)
	var button := Button.new()
	button.text = "Start"
	button.custom_minimum_size = Vector2(76, 44)
	button.disabled = game.level < int(job.level) or game.active_job_id != ""
	if game.level < int(job.level):
		button.text = "St. %d" % int(job.level)
	_style_small_button(button)
	button.pressed.connect(_start_job.bind(str(job.id), button))
	row.add_child(button)
	return card


func _upgrade_card(upgrade: Dictionary) -> Control:
	var level := int(game.upgrades.get(upgrade.id, 0))
	var cost := GameData.upgrade_cost(upgrade, level)
	var card := _card_container()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	card.get_child(0).get_child(0).add_child(row)
	row.add_child(_icon_box(str(upgrade.icon), Color("4acb88")))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label(str(upgrade.title), 15, TEXT, true))
	copy.add_child(_label(str(upgrade.description), 11, MUTED))
	copy.add_child(_label("Stufe %d" % level, 11, GOLD, true))
	row.add_child(copy)
	var button := Button.new()
	button.text = GameData.format_money(cost)
	button.custom_minimum_size = Vector2(92, 44)
	button.disabled = game.money < cost
	_style_small_button(button)
	button.pressed.connect(_buy_upgrade.bind(str(upgrade.id), button))
	row.add_child(button)
	return card


func _employee_card(employee: Dictionary) -> Control:
	var owned := int(game.employees.get(employee.id, 0))
	var cost := GameData.employee_cost(employee, owned)
	var card := _card_container()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	card.get_child(0).get_child(0).add_child(row)
	row.add_child(_avatar(str(employee.title).substr(0, 1), employee.color))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label(str(employee.title), 15, TEXT, true))
	copy.add_child(_label(str(employee.trade) + "  •  Im Team: %d" % owned, 11, MUTED))
	copy.add_child(_label("+%s / Sek." % GameData.format_money(float(employee.income), true), 11, GREEN, true))
	row.add_child(copy)
	var button := Button.new()
	button.text = "Einstellen\n" + GameData.format_money(cost)
	button.custom_minimum_size = Vector2(98, 48)
	button.disabled = game.money < cost
	_style_small_button(button)
	button.pressed.connect(_hire.bind(str(employee.id), button))
	row.add_child(button)
	return card


func _primary_action() -> void:
	if game.active_job_id != "":
		_switch_tab("auftraege")
		return
	for job in GameData.JOBS:
		if game.level >= int(job.level):
			_start_job(str(job.id), primary_button)
			return


func _start_job(job_id: String, source: Control) -> void:
	if game.start_job(job_id):
		sfx.play_cue("start")
		_haptic(22, 0.35)
		_punch(source)
		_switch_tab("betrieb")


func _buy_upgrade(upgrade_id: String, source: Control) -> void:
	if game.buy_upgrade(upgrade_id):
		sfx.play_cue("upgrade")
		_haptic(35, 0.55)
		_punch(source)
		_refresh_current_tab()


func _hire(employee_id: String, source: Control) -> void:
	if game.hire_employee(employee_id):
		sfx.play_cue("upgrade")
		_haptic(35, 0.55)
		_punch(source)
		_refresh_current_tab()


func _refresh_current_tab() -> void:
	_switch_tab(current_tab)


func _update_live_header() -> void:
	if not money_label:
		return
	if absf(last_money_display - game.money) >= 0.01:
		money_label.text = GameData.format_money(game.money, true)
		last_money_display = game.money
	income_label.text = "+%s /s" % GameData.format_money(game.passive_income_per_second(), true)
	if level_label:
		level_label.text = "STUFE %d" % game.level


func _update_active_job() -> void:
	if not progress_bar or not primary_button:
		return
	if game.active_job_id == "":
		if workshop_visual:
			workshop_visual.set_job("", 0.0)
		progress_bar.value = 0.0
		job_label.text = "Bereit für den nächsten Auftrag"
		job_time_label.text = ""
		primary_button.text = "AUFTRAG STARTEN"
		return
	var job := game.get_job(game.active_job_id)
	if workshop_visual:
		workshop_visual.set_job(game.active_job_id, game.active_job_progress())
	progress_bar.value = game.active_job_progress() * 100.0
	job_label.text = str(job.title)
	job_time_label.text = "%.1f s" % game.active_job_remaining
	primary_button.text = "AUFTRAG LÄUFT  •  %d %%" % int(game.active_job_progress() * 100.0)


func _on_job_completed(job: Dictionary, reward: float) -> void:
	sfx.play_cue("coin")
	_haptic(70, 0.8)
	if current_tab == "betrieb":
		_refresh_current_tab()
		if workshop_visual:
			workshop_visual.celebrate()
	_show_reward_burst("+" + GameData.format_money(reward), job.color)
	_show_toast("Auftrag erledigt · Serie %d×" % game.current_streak)


func _on_level_up(new_level: int) -> void:
	sfx.play_cue("level")
	_haptic(120, 1.0)
	_show_reward_burst("BETRIEBSSTUFE %d!" % new_level, GOLD)


func _show_offline_dialog() -> void:
	var reward := game.claim_offline_reward()
	var dialog := AcceptDialog.new()
	dialog.title = "Dein Team war fleißig"
	dialog.dialog_text = "Während deiner Abwesenheit hat dein Betrieb\n%s erwirtschaftet." % GameData.format_money(reward, true)
	dialog.ok_button_text = "Einnahmen einsammeln"
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 180))
	dialog.confirmed.connect(dialog.queue_free)


func _show_toast(message: String) -> void:
	if not toast_layer:
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(Color("eefbf4"), 14))
	panel.position = Vector2(24, size.y - 160)
	panel.size = Vector2(size.x - 48, 54)
	var label := _label(message, 12, Color("10241c"), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	toast_layer.add_child(panel)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(1.8)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(panel.queue_free)


func _show_reward_burst(message: String, color: Color) -> void:
	var label := _label(message, 25, color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(30, size.y * 0.43)
	label.size = Vector2(size.x - 60, 52)
	toast_layer.add_child(label)
	label.scale = Vector2(0.7, 0.7)
	label.pivot_offset = label.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 90.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.75)
	tween.chain().tween_callback(label.queue_free)


func _milestone_card() -> Control:
	var next := game.level + 1
	var needed := GameData.xp_for_level(game.level)
	var card := _card_container()
	var box: VBoxContainer = card.get_child(0).get_child(0)
	var row := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label("Betriebsstufe %d" % next, 15, TEXT, true))
	copy.add_child(_label("Neue Aufträge und bessere Kunden", 11, MUTED))
	row.add_child(copy)
	row.add_child(_label("%d / %d XP" % [game.xp, needed], 12, GOLD, true))
	box.add_child(row)
	var bar := ProgressBar.new()
	bar.value = float(game.xp) / float(needed) * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size.y = 8
	bar.add_theme_stylebox_override("background", _box(Color("0d1916"), 5))
	bar.add_theme_stylebox_override("fill", _box(GOLD, 5))
	box.add_child(bar)
	return card


func _page_intro(title: String, subtitle: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(_label(title, 25, TEXT, true))
	var copy := _label(subtitle, 13, MUTED)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(copy)
	return box


func _section_title(title: String, action: String) -> Control:
	var row := HBoxContainer.new()
	row.add_child(_label(title, 17, TEXT, true))
	row.add_spacer(false)
	row.add_child(_label(action, 10, GREEN, true))
	return row


func _stat_card(title: String, value: String, caption: String) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _box(SURFACE, 16, Color("203b33"), 1))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	var t := _label(title, 9, MUTED, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var v := _label(value, 15, TEXT, true)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(v)
	var c := _label(caption, 9, MUTED)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(c)
	card.add_child(box)
	card.custom_minimum_size.y = 82
	return card


func _highlight_card(kicker: String, value: String, caption: String) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(GREEN_DARK, 18, Color("2f7354"), 1))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_label(kicker, 10, GREEN, true))
	box.add_child(_label(value, 24, TEXT, true))
	box.add_child(_label(caption, 11, MUTED))
	card.add_child(box)
	card.custom_minimum_size.y = 116
	return card


func _card_container() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(SURFACE, 18, Color("203a32"), 1))
	var margin := MarginContainer.new()
	_set_margins(margin, 14, 14, 13, 13)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)
	return card


func _icon_box(text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(52, 52)
	panel.add_theme_stylebox_override("panel", _box(Color(color, 0.14), 14, Color(color, 0.55), 1))
	var label := _label(text, 13, color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _avatar(letter: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(52, 52)
	panel.add_theme_stylebox_override("panel", _box(color, 26))
	var label := _label(letter, 20, Color("0b1813"), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _pill(text: String, bg: Color, fg: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(bg, 10, Color(fg, 0.35), 1))
	var label := _label("  " + text + "  ", 9, fg, true)
	panel.add_child(label)
	return panel


func _label(value: String, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(color, 0.2))
	return label


func _box(color: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_color = border_color
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	return box


func _set_margins(margin: MarginContainer, left: int, right: int, top: int, bottom: int) -> void:
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)


func _style_small_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("0a1b14"))
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _box(GREEN, 12))
	button.add_theme_stylebox_override("pressed", _box(Color("2bbd75"), 12))
	button.add_theme_stylebox_override("disabled", _box(Color("253a33"), 12))


func _style_nav(button: Button, active: bool) -> void:
	var fg := GREEN if active else MUTED
	button.add_theme_color_override("font_color", fg)
	button.add_theme_stylebox_override("normal", _box(GREEN_DARK if active else Color.TRANSPARENT, 13))
	button.add_theme_stylebox_override("pressed", _box(Color("234b39"), 13))


func _punch(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2(0.94, 0.94), 0.07)
	tween.tween_property(control, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)


func _haptic(duration_ms: int, strength: float) -> void:
	Input.vibrate_handheld(duration_ms, strength)


func _employee_count() -> int:
	var total := 0
	for value in game.employees.values():
		total += int(value)
	return total


func _business_title() -> String:
	if game.level >= 8:
		return "Handwerks-Imperium"
	if game.level >= 5:
		return "Meisterbetrieb"
	if game.level >= 3:
		return "Aufstrebender Betrieb"
	return "Kleine Werkstatt"


func _business_subtitle() -> String:
	return "%d Aufträge erledigt  •  %d Mitarbeiter" % [game.completed_jobs, _employee_count()]
