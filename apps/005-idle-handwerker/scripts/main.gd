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
var reputation_label: Label
var progress_bar: ProgressBar
var job_label: Label
var job_time_label: Label
var primary_button: Button
var workshop_visual: WorkshopVisual
var toast_layer: Control
var last_money_display := -1.0
var nav_buttons: Dictionary = {}
var job_buttons: Dictionary = {}
var header_margin: MarginContainer
var body_margin: MarginContainer
var nav_margin: MarginContainer
var header_row: HBoxContainer
var brand_eyebrow: Label
var brand_title: Label
var settings_button: Button
var main_scroll: ScrollContainer
var app_font: FontFile


func _ready() -> void:
	set_process(false)
	app_font = FontFile.new()
	app_font.data = Marshalls.base64_to_raw(EmbeddedFont.DATA)
	var app_theme := Theme.new()
	app_theme.default_font = app_font
	theme = app_theme
	game = GameState.new()
	add_child(game)
	sfx = SfxBank.new()
	add_child(sfx)
	sfx.set_enabled(game.sound_enabled)
	game.job_completed.connect(_on_job_completed)
	game.job_event_started.connect(_on_job_event_started)
	game.contract_signed.connect(_on_contract_signed)
	game.review_created.connect(_on_review_created)
	game.level_up.connect(_on_level_up)
	game.notice.connect(_show_toast)
	_build_shell()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_switch_tab("betrieb")
	set_process(true)
	if not game.tutorial_completed:
		_show_tutorial()
	elif game.offline_reward > 0.0:
		_show_offline_dialog()


func _process(_delta: float) -> void:
	_update_live_header()
	_update_active_job()
	_update_job_cooldowns()


func _notification(what: int) -> void:
	if not game:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		game.save_game()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 20)
	header_margin.add_theme_constant_override("margin_right", 20)
	header_margin.add_theme_constant_override("margin_top", 18)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(header_margin)
	header_margin.add_child(_build_header())

	main_scroll = ScrollContainer.new()
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.scroll_deadzone = 6
	root.add_child(main_scroll)
	body_margin = MarginContainer.new()
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 16)
	body_margin.add_theme_constant_override("margin_right", 16)
	body_margin.add_theme_constant_override("margin_bottom", 18)
	main_scroll.add_child(body_margin)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	body_margin.add_child(content)

	root.add_child(_build_nav())

	toast_layer = Control.new()
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(toast_layer)


func _build_header() -> Control:
	header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_eyebrow = _label("KAMILUNAVO GAMES", 10, GREEN)
	brand_eyebrow.add_theme_constant_override("letter_spacing", 1)
	brand.add_child(brand_eyebrow)
	brand_title = _label("IDLE HANDWERKER", 23, TEXT, true)
	brand.add_child(brand_title)
	header_row.add_child(brand)

	var balance := VBoxContainer.new()
	balance.alignment = BoxContainer.ALIGNMENT_CENTER
	balance.custom_minimum_size.x = 92
	money_label = _label("120 €", 20, TEXT, true)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	balance.add_child(money_label)
	income_label = _label("+0 €/s", 11, GREEN)
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	income_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	balance.add_child(income_label)
	reputation_label = _label("0 Ruf", 11, GOLD, true)
	reputation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reputation_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	balance.add_child(reputation_label)
	header_row.add_child(balance)

	settings_button = Button.new()
	settings_button.text = "OPT"
	settings_button.tooltip_text = "Einstellungen"
	settings_button.custom_minimum_size = Vector2(44, 44)
	settings_button.add_theme_font_size_override("font_size", 11)
	settings_button.add_theme_color_override("font_color", GREEN)
	settings_button.add_theme_stylebox_override("normal", UiSkin.dark_button())
	settings_button.add_theme_stylebox_override("hover", UiSkin.active_nav())
	settings_button.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	settings_button.pressed.connect(_show_settings)
	header_row.add_child(settings_button)
	return header_row


func _build_nav() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(SURFACE, 0, Color.TRANSPARENT, 0))
	nav_margin = MarginContainer.new()
	nav_margin.add_theme_constant_override("margin_left", 8)
	nav_margin.add_theme_constant_override("margin_right", 8)
	nav_margin.add_theme_constant_override("margin_top", 8)
	nav_margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(nav_margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	nav_margin.add_child(row)
	var items := [
		["betrieb", "Betrieb", "BT"],
		["auftraege", "Jobs", "AU"],
		["ausbau", "Ausbau", "UP"],
		["team", "Firma", "FI"],
		["ziele", "Ziele", "ZL"],
	]
	for item in items:
		var button := Button.new()
		button.name = "nav_%s" % item[0]
		button.text = "%s\n%s" % [item[2], item[1]]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 58
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_nav_selected.bind(item[0], button))
		row.add_child(button)
		nav_buttons[item[0]] = button
	return panel


func _switch_tab(tab_id: String) -> void:
	current_tab = tab_id
	job_buttons.clear()
	for child in content.get_children():
		child.queue_free()
	for id in ["betrieb", "auftraege", "ausbau", "team", "ziele"]:
		var button: Button = nav_buttons.get(id)
		if button:
			_style_nav(button, id == tab_id)
	match tab_id:
		"betrieb": _build_dashboard()
		"auftraege": _build_jobs()
		"ausbau": _build_upgrades()
		"team": _build_team()
		"ziele": _build_goals()
	_forward_touch_scrolling(content)
	_animate_tab_content()


func _nav_selected(tab_id: String, source: Control) -> void:
	if tab_id == current_tab:
		_punch(source)
		return
	sfx.play_cue("click")
	_haptic(12, 0.25)
	_switch_tab(tab_id)


func _animate_tab_content() -> void:
	if game.reduced_motion:
		content.modulate = Color.WHITE
		return
	content.modulate = Color(1.0, 1.0, 1.0, 0.25)
	var tween := create_tween()
	tween.tween_property(content, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _apply_responsive_layout() -> void:
	if not header_margin or not body_margin or not nav_margin:
		return
	var compact := get_viewport_rect().size.x <= 480.0
	var side := 12 if compact else 20
	var safe_top := 0
	var safe_bottom := 0
	var screen_size := DisplayServer.screen_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	if screen_size.y > 0 and safe_area.size.y > 0:
		var scale_y := get_viewport_rect().size.y / float(screen_size.y)
		safe_top = int(float(safe_area.position.y) * scale_y)
		safe_bottom = int(float(screen_size.y - safe_area.end.y) * scale_y)
	header_margin.add_theme_constant_override("margin_left", side)
	header_margin.add_theme_constant_override("margin_right", side)
	header_margin.add_theme_constant_override("margin_top", maxi(14 if compact else 18, safe_top + 6))
	body_margin.add_theme_constant_override("margin_left", 10 if compact else 16)
	body_margin.add_theme_constant_override("margin_right", 10 if compact else 16)
	nav_margin.add_theme_constant_override("margin_left", 4 if compact else 8)
	nav_margin.add_theme_constant_override("margin_right", 4 if compact else 8)
	nav_margin.add_theme_constant_override("margin_bottom", maxi(10 if compact else 14, safe_bottom + 6))
	for button in nav_buttons.values():
		button.add_theme_font_size_override("font_size", 9 if compact else 11)
	header_row.add_theme_constant_override("separation", 6 if compact else 12)
	brand_eyebrow.add_theme_font_size_override("font_size", 8 if compact else 10)
	brand_title.add_theme_font_size_override("font_size", 17 if compact else 23)
	money_label.add_theme_font_size_override("font_size", 16 if compact else 20)
	income_label.add_theme_font_size_override("font_size", 9 if compact else 11)
	reputation_label.add_theme_font_size_override("font_size", 9 if compact else 11)
	settings_button.custom_minimum_size = Vector2(40, 40) if compact else Vector2(44, 44)


func _build_dashboard() -> void:
	var hero := PanelContainer.new()
	hero.custom_minimum_size.y = 330 if _is_compact() else 238
	hero.add_theme_stylebox_override("panel", UiSkin.hero())
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

	var scene_row: BoxContainer = VBoxContainer.new() if _is_compact() else HBoxContainer.new()
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
	workshop_visual.set_progression(game.upgrades, game.employees, game.level, game.current_location_id, game.active_contracts)
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
	primary_button.add_theme_stylebox_override("normal", UiSkin.primary_button())
	primary_button.add_theme_stylebox_override("hover", UiSkin.primary_button())
	primary_button.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	primary_button.pressed.connect(_primary_action)
	content.add_child(primary_button)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 9)
	stat_row.add_child(_stat_card("AUFTRÄGE", str(game.completed_jobs), "erledigt"))
	stat_row.add_child(_stat_card("SERIE", "%d×" % game.current_streak, "Bestwert %d×" % game.best_streak))
	stat_row.add_child(_stat_card("WERT", GameData.format_money(game.company_value()), "Firmenwert"))
	content.add_child(stat_row)

	var location := game.current_location()
	content.add_child(_highlight_card("AKTIVER STANDORT · %s" % location.code, str(location.title), "+%d %% Auftragswert · %d/%d Tagesziele" % [int((float(location.multiplier) - 1.0) * 100.0), game.completed_daily_missions(), GameData.DAILY_MISSIONS.size()]))
	content.add_child(_reputation_card())
	content.add_child(_review_summary_card())
	if game.active_job_id != "" and not game.active_event().is_empty():
		var event := game.active_event()
		content.add_child(_event_card(event))

	content.add_child(_section_title("Nächster Meilenstein", "MEHR"))
	content.add_child(_milestone_card())


func _build_jobs() -> void:
	content.add_child(_page_intro("Auftragsbörse", "Wähle Aufträge, verdiene Geld und steigere deinen Ruf."))
	content.add_child(_section_title("Einsatzgebiet", "STANDORTBONUS"))
	content.add_child(_location_selector())
	content.add_child(_section_title("Verfügbare Aufträge", str(game.current_location().title).to_upper()))
	for job in GameData.JOBS:
		if str(job.location) == game.current_location_id and not bool(job.get("major", false)):
			content.add_child(_job_card(job))
	var has_major := false
	for job in GameData.JOBS:
		if str(job.location) == game.current_location_id and bool(job.get("major", false)):
			has_major = true
	if has_major:
		content.add_child(_section_title("Großprojekte", "PREMIUM-AUFTRÄGE"))
		for job in GameData.JOBS:
			if str(job.location) == game.current_location_id and bool(job.get("major", false)):
				content.add_child(_job_card(job))


func _build_upgrades() -> void:
	content.add_child(_page_intro("Betrieb ausbauen", "Investiere in Tempo, Qualität und automatisierte Einnahmen."))
	content.add_child(_workshop_progress_card())
	for upgrade in GameData.UPGRADES:
		content.add_child(_upgrade_card(upgrade))


func _build_team() -> void:
	content.add_child(_page_intro("Firma & Stammkunden", "Baue dein Team auf und sichere dir dauerhafte Wartungsverträge."))
	var passive := _highlight_card("PASSIVES EINKOMMEN", GameData.format_money(game.passive_income_per_second(), true) + " / Sek.", "Team + Verträge · offline bis zu 8 Stunden")
	content.add_child(passive)
	content.add_child(_team_progress_card())
	content.add_child(_section_title("Stammkundenverträge", "%d / %d AKTIV" % [game.active_contracts.size(), GameData.CONTRACTS.size()]))
	for contract in GameData.CONTRACTS:
		content.add_child(_contract_card(contract))
	content.add_child(_section_title("Mitarbeiter", "%d IM TEAM" % game.total_employees()))
	for employee in GameData.EMPLOYEES:
		content.add_child(_employee_card(employee))


func _build_goals() -> void:
	content.add_child(_page_intro("Ziele & Erfolge", "Klare Etappen, tägliche Belohnungen und dauerhafte Meilensteine."))
	content.add_child(_highlight_card("HEUTIGER FORTSCHRITT", "%d / %d Ziele" % [game.completed_daily_missions(), GameData.DAILY_MISSIONS.size()], "Neue Tagesziele am nächsten Kalendertag"))
	content.add_child(_section_title("Tagesziele", "HEUTE"))
	for mission in GameData.DAILY_MISSIONS:
		content.add_child(_goal_card(mission, true))
	content.add_child(_section_title("Karriere-Erfolge", "DAUERHAFT"))
	for achievement in GameData.ACHIEVEMENTS:
		content.add_child(_goal_card(achievement, false))
	if not game.recent_reviews.is_empty():
		content.add_child(_section_title("Letzte Kundenstimmen", "BEWERTUNGEN"))
		for review in game.recent_reviews:
			content.add_child(_review_card(review))


func _job_card(job: Dictionary) -> Control:
	var card := _card_container()
	var is_major := bool(job.get("major", false))
	if is_major:
		card.add_theme_stylebox_override("panel", UiSkin.hero())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	card.get_child(0).get_child(0).add_child(row)
	row.add_child(_icon_box(str(job.icon), job.color))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_major:
		copy.add_child(_label("GROSSPROJEKT", 9, GOLD, true))
	copy.add_child(_label(str(job.title), 16, TEXT, true))
	copy.add_child(_label(str(job.customer) + "  •  " + str(int(job.duration)) + " Sek.", 11, MUTED))
	var reward := float(job.reward) * game.job_reward_multiplier() * game.streak_reward_multiplier() * game.location_reward_multiplier()
	copy.add_child(_label("Basis %s  +%d XP" % [GameData.format_money(reward), int(job.xp)], 12, GREEN, true))
	row.add_child(copy)
	var button := Button.new()
	button.text = "Start"
	button.custom_minimum_size = Vector2(76, 44)
	var required_reputation := int(job.get("reputation", 0))
	button.disabled = game.level < int(job.level) or game.reputation < required_reputation or game.active_job_id != "" or game.job_cooldown_remaining(str(job.id)) > 0.0
	if game.level < int(job.level):
		button.text = "St. %d" % int(job.level)
	elif game.reputation < required_reputation:
		button.text = "%d Ruf" % required_reputation
	elif game.job_cooldown_remaining(str(job.id)) > 0.0:
		button.text = "Warten\n%s" % game.format_cooldown(game.job_cooldown_remaining(str(job.id)))
	_style_small_button(button)
	button.pressed.connect(_start_job.bind(str(job.id), button))
	row.add_child(button)
	job_buttons[str(job.id)] = button
	return card


func _location_selector() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	for location in GameData.LOCATIONS:
		var selected := str(location.id) == game.current_location_id
		var unlocked := game.level >= int(location.level)
		var card := _card_container()
		if selected:
			card.add_theme_stylebox_override("panel", UiSkin.hero())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.get_child(0).get_child(0).add_child(row)
		row.add_child(_icon_box(str(location.code), GOLD if selected else GREEN))
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_child(_label(str(location.title), 15, TEXT, true))
		var subtitle := str(location.subtitle) if unlocked else "Freischaltung ab Stufe %d" % int(location.level)
		var subtitle_label := _label(subtitle, 10, MUTED)
		subtitle_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		copy.add_child(subtitle_label)
		if unlocked and game.requires_location_restart(str(location.id)):
			var restart_hint := _label("NEUER BETRIEB · OPERATIVER NEUSTART", 9, GOLD, true)
			restart_hint.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			copy.add_child(restart_hint)
		copy.add_child(_label("+%d %% Auftragswert" % int((float(location.multiplier) - 1.0) * 100.0), 10, GOLD, true))
		row.add_child(copy)
		var button := Button.new()
		button.text = "Aktiv" if selected else (("Eröffnen" if game.requires_location_restart(str(location.id)) else "Wählen") if unlocked else "St. %d" % int(location.level))
		button.disabled = selected or not unlocked or game.active_job_id != ""
		button.custom_minimum_size = Vector2(76, 44)
		_style_small_button(button)
		button.pressed.connect(_select_location.bind(str(location.id), button))
		row.add_child(button)
		box.add_child(card)
	return box


func _goal_card(item: Dictionary, daily: bool) -> Control:
	var progress := game.daily_mission_progress(item) if daily else game.achievement_progress(item)
	var claimed := bool(game.daily_claimed.get(item.id, false)) if daily else bool(game.achievements_claimed.get(item.id, false))
	var ready := progress >= float(item.target)
	var card := _card_container()
	var box: VBoxContainer = card.get_child(0).get_child(0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_icon_box("✓" if claimed else ("!" if ready else "•"), GOLD if ready else GREEN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label(str(item.title), 15, TEXT, true))
	copy.add_child(_label(str(item.description), 10, MUTED))
	copy.add_child(_label("Belohnung  " + GameData.format_money(float(item.reward)), 10, GOLD, true))
	row.add_child(copy)
	var button := Button.new()
	var fractional := absf(float(item.target) - round(float(item.target))) > 0.01
	var progress_text := "%.1f / %.1f" % [progress, float(item.target)] if fractional else "%d / %d" % [int(progress), int(item.target)]
	button.text = "Erhalten" if claimed else ("Abholen" if ready else progress_text)
	button.disabled = claimed or not ready
	button.custom_minimum_size = Vector2(88, 44)
	_style_small_button(button)
	button.pressed.connect(_claim_goal.bind(str(item.id), daily, button))
	row.add_child(button)
	box.add_child(row)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 7
	bar.value = progress / maxf(1.0, float(item.target)) * 100.0
	bar.add_theme_stylebox_override("background", _box(Color("0a1713"), 4))
	bar.add_theme_stylebox_override("fill", _box(GOLD if ready else GREEN, 4))
	box.add_child(bar)
	return card


func _event_card(event: Dictionary) -> Control:
	var card := _card_container()
	card.add_theme_stylebox_override("panel", UiSkin.hero())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.get_child(0).get_child(0).add_child(row)
	row.add_child(_icon_box(str(event.code), GOLD))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label("BONUSEREIGNIS · " + str(event.title), 13, GOLD, true))
	copy.add_child(_label(str(event.description), 10, MUTED))
	copy.add_child(_label("+%d %% Lohn  ·  +%d %% XP" % [int((float(event.reward_multiplier) - 1.0) * 100.0), int((float(event.xp_multiplier) - 1.0) * 100.0)], 11, GREEN, true))
	row.add_child(copy)
	return card


func _reputation_card() -> Control:
	var rank := game.reputation_rank()
	var next_rank := game.next_reputation_rank()
	var card := _card_container()
	var box: VBoxContainer = card.get_child(0).get_child(0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_icon_box(str(rank.code), GOLD))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label("REPUTATION", 10, GREEN, true))
	copy.add_child(_label(str(rank.title), 15, TEXT, true))
	var status := "%d Rufpunkte · Höchster Rang" % game.reputation if next_rank.is_empty() else "%d / %d bis %s" % [game.reputation, int(next_rank.minimum), str(next_rank.title)]
	copy.add_child(_label(status, 10, MUTED))
	row.add_child(copy)
	box.add_child(row)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 7
	bar.value = 100.0 if next_rank.is_empty() else float(game.reputation) / maxf(1.0, float(next_rank.minimum)) * 100.0
	bar.add_theme_stylebox_override("background", _box(Color("0a1713"), 4))
	bar.add_theme_stylebox_override("fill", _box(GOLD, 4))
	box.add_child(bar)
	return card


func _review_summary_card() -> Control:
	var card := _card_container()
	var box: VBoxContainer = card.get_child(0).get_child(0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_icon_box("★", GOLD))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label("KUNDENBEWERTUNG", 10, GREEN, true))
	var rating_text := "Noch offen" if game.quality_samples == 0 else "%.1f / 5,0" % game.customer_rating
	copy.add_child(_label(rating_text, 20, TEXT, true))
	var caption := "Noch keine Bewertung" if game.recent_reviews.is_empty() else "%d %% Qualität · %s" % [game.last_job_quality, str(game.recent_reviews[0].customer)]
	copy.add_child(_label(caption, 10, MUTED))
	row.add_child(copy)
	box.add_child(row)
	return card


func _review_card(review: Dictionary) -> Control:
	var card := _card_container()
	var box: VBoxContainer = card.get_child(0).get_child(0)
	var top := HBoxContainer.new()
	var customer := _label(str(review.customer), 13, TEXT, true)
	customer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(customer)
	top.add_child(_label("★".repeat(int(review.stars)), 13, GOLD, true))
	box.add_child(top)
	var quote := _label("„%s“" % str(review.text), 11, MUTED)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(quote)
	box.add_child(_label("%s · %d %% Qualität" % [str(review.job), int(review.quality)], 9, GREEN, true))
	return card


func _contract_card(contract: Dictionary) -> Control:
	var active := bool(game.active_contracts.get(contract.id, false))
	var unlocked := game.level >= int(contract.level) and game.reputation >= int(contract.reputation)
	var card := _card_container()
	if active:
		card.add_theme_stylebox_override("panel", UiSkin.hero())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.get_child(0).get_child(0).add_child(row)
	row.add_child(_icon_box(str(contract.code), GOLD if active else GREEN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label(str(contract.title), 14, TEXT, true))
	copy.add_child(_label(str(contract.client), 10, GOLD, true))
	var description := _label(str(contract.description), 10, MUTED)
	description.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	copy.add_child(description)
	var payout := _label("%s je %s  ·  %s/s" % [GameData.format_money(float(contract.payout)), _format_income_interval(float(contract.interval)), GameData.format_money(float(contract.payout) / float(contract.interval), true)], 10, GREEN, true)
	payout.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	copy.add_child(payout)
	row.add_child(copy)
	var button := Button.new()
	button.text = "Aktiv" if active else ("Vertrag" if unlocked else "St. %d\n%d Ruf" % [int(contract.level), int(contract.reputation)])
	button.disabled = active or not unlocked
	button.custom_minimum_size = Vector2(84, 48)
	_style_small_button(button)
	button.pressed.connect(_sign_contract.bind(str(contract.id), button))
	row.add_child(button)
	return card


func _team_progress_card() -> Control:
	var rank := game.team_rank()
	var next_rank := game.next_team_rank()
	var team_size := game.total_employees()
	var card := _card_container()
	card.add_theme_stylebox_override("panel", UiSkin.hero())
	var box: VBoxContainer = card.get_child(0).get_child(0)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(_icon_box(str(rank.code), GREEN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label("TEAMRANG", 9, GREEN, true))
	copy.add_child(_label(str(rank.title), 16, TEXT, true))
	var bonus := _label("%d Mitarbeiter · +%d Qualität" % [team_size, int(rank.quality_bonus)], 10, GOLD, true)
	bonus.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	copy.add_child(bonus)
	top.add_child(copy)
	box.add_child(top)
	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 8
	progress.add_theme_stylebox_override("background", _box(Color("0d1916"), 5))
	progress.add_theme_stylebox_override("fill", _box(GREEN, 5))
	var caption: String
	if next_rank.is_empty():
		progress.value = 100.0
		caption = "Höchster Teamrang erreicht"
	else:
		var current_minimum := int(rank.minimum)
		var next_minimum := int(next_rank.minimum)
		progress.value = float(team_size - current_minimum) / float(next_minimum - current_minimum) * 100.0
		caption = "Noch %d Einstellungen bis %s" % [next_minimum - team_size, str(next_rank.title)]
	box.add_child(progress)
	var progress_copy := _label(caption, 10, MUTED)
	progress_copy.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	box.add_child(progress_copy)
	return card


func _workshop_progress_card() -> Control:
	var card := _card_container()
	var box: VBoxContainer = card.get_child(0).get_child(0)
	var row: BoxContainer = VBoxContainer.new() if _is_compact() else HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var preview := WorkshopVisual.new()
	preview.custom_minimum_size = Vector2(150, 112)
	preview.set_progression(game.upgrades, game.employees, game.level, game.current_location_id, game.active_contracts)
	row.add_child(preview)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label("DEINE WERKSTATT", 13, GOLD, true))
	var workshop_copy := _label("Jeder Ausbau wird im Betrieb sichtbar.", 11, MUTED)
	workshop_copy.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	copy.add_child(workshop_copy)
	var workshop_levels := _label("Werkzeug %d  ·  Fuhrpark %d  ·  Büro %d" % [int(game.upgrades.tools), int(game.upgrades.van), int(game.upgrades.office)], 11, GREEN, true)
	workshop_levels.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	copy.add_child(workshop_levels)
	copy.add_child(_label("Team vor Ort: %d" % game.total_employees(), 11, TEXT, true))
	row.add_child(copy)
	box.add_child(row)
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
	var description := _label(str(upgrade.description), 11, MUTED)
	description.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	copy.add_child(description)
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
		if game.level >= int(job.level) and str(job.location) == game.current_location_id:
			_start_job(str(job.id), primary_button)
			return


func _select_location(location_id: String, source: Control) -> void:
	if game.requires_location_restart(location_id):
		_show_location_restart_confirmation(location_id)
		return
	_apply_location_selection(location_id, source)


func _apply_location_selection(location_id: String, source: Control = null) -> void:
	if game.select_location(location_id):
		sfx.play_cue("upgrade")
		_haptic(30, 0.5)
		if is_instance_valid(source):
			_punch(source)
		_refresh_current_tab()


func _show_location_restart_confirmation(location_id: String) -> void:
	var location: Dictionary = {}
	for candidate in GameData.LOCATIONS:
		if str(candidate.id) == location_id:
			location = candidate
			break
	if location.is_empty():
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Neuen Betrieb eröffnen?"
	dialog.dialog_text = "%s ist ein neuer Karriereabschnitt. Geld, Ausbau, Personal, Verträge und Serie starten dort bei null. Stufe, Ruf, Bewertungen und Erfolge bleiben erhalten." % str(location.title)
	dialog.ok_button_text = "Betrieb eröffnen"
	dialog.cancel_button_text = "Noch nicht"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		_apply_location_selection(location_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(380, 250))


func _claim_goal(goal_id: String, daily: bool, source: Control) -> void:
	var claimed := game.claim_daily_mission(goal_id) if daily else game.claim_achievement(goal_id)
	if claimed:
		sfx.play_cue("coin")
		_haptic(60, 0.75)
		_punch(source)
		_show_reward_burst("BELOHNUNG ABGEHOLT", GOLD)
		_refresh_current_tab()


func _sign_contract(contract_id: String, source: Control) -> void:
	if game.sign_contract(contract_id):
		sfx.play_cue("contract")
		_haptic(95, 0.9)
		_punch(source)
		_refresh_current_tab()


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
	reputation_label.text = "%d Ruf" % game.reputation
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
	var event := game.active_event()
	job_label.text = str(job.title) if event.is_empty() else "%s  ·  %s" % [job.title, event.code]
	job_time_label.text = "%.1f s" % game.active_job_remaining
	primary_button.text = "AUFTRAG LÄUFT  •  %d %%" % int(game.active_job_progress() * 100.0)


func _update_job_cooldowns() -> void:
	if job_buttons.is_empty():
		return
	for job_id in job_buttons:
		var button: Button = job_buttons[job_id]
		if not is_instance_valid(button):
			continue
		var job := game.get_job(str(job_id))
		if job.is_empty():
			continue
		var remaining := game.job_cooldown_remaining(str(job_id))
		var required_reputation := int(job.get("reputation", 0))
		button.disabled = game.level < int(job.level) or game.reputation < required_reputation or game.active_job_id != "" or remaining > 0.0
		if game.level < int(job.level):
			button.text = "St. %d" % int(job.level)
		elif game.reputation < required_reputation:
			button.text = "%d Ruf" % required_reputation
		elif remaining > 0.0:
			button.text = "Warten\n%s" % game.format_cooldown(remaining)
		else:
			button.text = "Start"


func _on_job_completed(job: Dictionary, reward: float) -> void:
	sfx.play_cue("coin")
	_haptic(70, 0.8)
	if current_tab == "betrieb":
		_refresh_current_tab()
		if workshop_visual:
			workshop_visual.celebrate(game.current_streak)
	_show_reward_burst("+" + GameData.format_money(reward), job.color)
	_show_toast("Auftrag erledigt · Serie %d× · %d Ruf" % [game.current_streak, game.reputation])


func _on_job_event_started(event: Dictionary) -> void:
	sfx.play_cue("event")
	_haptic(45, 0.65)
	_show_event_reveal(event)


func _on_contract_signed(contract: Dictionary) -> void:
	_show_reward_burst("NEUER STAMMKUNDE", GOLD)
	_show_toast("%s zahlt jetzt dauerhaft" % contract.client)


func _on_review_created(review: Dictionary) -> void:
	sfx.play_cue("review")
	_show_review_reveal(review)


func _show_review_reveal(review: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.z_index = 22
	panel.add_theme_stylebox_override("panel", UiSkin.hero())
	panel.position = Vector2(24, size.y * 0.27)
	panel.size = Vector2(size.x - 48, 168)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var kicker := _label("NEUE KUNDENBEWERTUNG", 10, GREEN, true)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var stars := _label("★".repeat(int(review.stars)), 25, GOLD, true)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stars)
	var quote := _label("„%s“" % str(review.text), 11, MUTED)
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(quote)
	var quality := _label("%d %% Arbeitsqualität" % int(review.quality), 11, TEXT, true)
	quality.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(quality)
	panel.add_child(box)
	toast_layer.add_child(panel)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.82, 0.82)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(2.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(panel.queue_free)


func _show_event_reveal(event: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.z_index = 20
	panel.add_theme_stylebox_override("panel", UiSkin.hero())
	panel.position = Vector2(24, size.y * 0.29)
	panel.size = Vector2(size.x - 48, 138)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_label("BONUSEREIGNIS · " + str(event.code), 10, GOLD, true))
	var title := _label(str(event.title), 21, TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var description := _label(str(event.description), 11, MUTED)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)
	panel.add_child(box)
	toast_layer.add_child(panel)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.84, 0.84)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(1.65)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(panel.queue_free)


func _on_level_up(new_level: int) -> void:
	sfx.play_cue("level")
	_haptic(120, 1.0)
	_show_reward_burst("BETRIEBSSTUFE %d!" % new_level, GOLD)


func _show_offline_dialog() -> void:
	var pending_reward := game.offline_reward
	var overlay := ColorRect.new()
	overlay.color = Color("07100ef2")
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 70
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(370.0, size.x - 28.0), minf(500.0, size.y - 44.0))
	panel.add_theme_stylebox_override("panel", UiSkin.hero())
	center.add_child(panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 26, 26, 28, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	var eyebrow := _label("WILLKOMMEN ZURÜCK", 10, GREEN, true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var medallion := PanelContainer.new()
	medallion.custom_minimum_size = Vector2(84, 84)
	medallion.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medallion.add_theme_stylebox_override("panel", UiSkin.medallion())
	var medallion_text := _label("OFF", 17, GOLD, true)
	medallion_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medallion_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	medallion.add_child(medallion_text)
	box.add_child(medallion)
	var title := _label("Dein Team war fleißig", 22, TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var duration := _format_offline_duration(game.offline_elapsed_seconds)
	var body := _label("Während deiner Abwesenheit von %s lief dein Betrieb weiter." % duration, 12, MUTED)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	box.add_child(body)
	var reward_label := _label(GameData.format_money(pending_reward, true), 30, GOLD, true)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(reward_label)
	var detail := _label("50 % Offline-Effizienz · maximal 8 Stunden", 10, GREEN, true)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(detail)
	var collect := Button.new()
	collect.text = "EINNAHMEN EINSAMMELN"
	collect.custom_minimum_size.y = 60
	collect.add_theme_font_size_override("font_size", 14)
	collect.add_theme_color_override("font_color", Color("071811"))
	collect.add_theme_stylebox_override("normal", UiSkin.primary_button())
	collect.add_theme_stylebox_override("hover", UiSkin.primary_button())
	collect.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	collect.pressed.connect(func() -> void:
		var collected := game.claim_offline_reward()
		sfx.play_cue("coin")
		_haptic(55, 0.7)
		overlay.queue_free()
		_update_live_header()
		_show_toast("Offline-Ertrag: +%s" % GameData.format_money(collected, true))
	)
	box.add_child(collect)


func _format_offline_duration(seconds: float) -> String:
	var total_minutes := maxi(1, int(round(seconds / 60.0)))
	var hours := int(total_minutes / 60)
	var minutes := total_minutes % 60
	if hours <= 0:
		return "%d Minuten" % minutes
	if minutes == 0:
		return "%d Stunden" % hours
	return "%d Std. %d Min." % [hours, minutes]


func _format_income_interval(seconds: float) -> String:
	var minutes := int(round(seconds / 60.0))
	if minutes < 60:
		return "%d Min." % minutes
	var hours := int(minutes / 60)
	var remainder := minutes % 60
	if remainder == 0:
		return "%d Std." % hours
	return "%d Std. %d Min." % [hours, remainder]


func _show_settings() -> void:
	sfx.play_cue("click")
	var overlay := ColorRect.new()
	overlay.color = Color("07100ee8")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 60
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(390.0, size.x - 28.0), minf(650.0, size.y - 36.0))
	panel.add_theme_stylebox_override("panel", UiSkin.hero())
	center.add_child(panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 24, 24, 26, 22)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)
	box.add_child(_label("SPIELEINSTELLUNGEN", 10, GREEN, true))
	box.add_child(_label("Dein Betrieb, dein Spielgefühl", 22, TEXT, true))
	var description := _label("Diese Optionen werden lokal im Spielstand gespeichert.", 11, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var sound_button := _settings_button("Sound", "Auftrags- und Belohnungseffekte")
	var haptic_button := _settings_button("Haptik", "Vibration bei wichtigen Aktionen")
	var motion_button := _settings_button("Bewegung reduzieren", "Weniger Übergänge und Skalierung")
	box.add_child(sound_button)
	box.add_child(haptic_button)
	box.add_child(motion_button)
	var refresh := func() -> void:
		sound_button.text = "SOUND\n%s" % ("AN" if game.sound_enabled else "AUS")
		haptic_button.text = "HAPTIK\n%s" % ("AN" if game.haptics_enabled else "AUS")
		motion_button.text = "BEWEGUNG REDUZIEREN\n%s" % ("AN" if game.reduced_motion else "AUS")
	refresh.call()
	sound_button.pressed.connect(func() -> void:
		game.set_preference("sound", not game.sound_enabled)
		sfx.set_enabled(game.sound_enabled)
		if game.sound_enabled:
			sfx.play_cue("click")
		refresh.call()
	)
	haptic_button.pressed.connect(func() -> void:
		game.set_preference("haptics", not game.haptics_enabled)
		_haptic(25, 0.4)
		refresh.call()
	)
	motion_button.pressed.connect(func() -> void:
		game.set_preference("reduced_motion", not game.reduced_motion)
		refresh.call()
	)
	var tutorial_button := _settings_button("TUTORIAL ERNEUT ANSEHEN", "Die vier Schnellstart-Schritte erneut öffnen")
	tutorial_button.pressed.connect(func() -> void:
		sfx.play_cue("click")
		overlay.queue_free()
		_show_tutorial()
	)
	box.add_child(tutorial_button)
	var version := str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
	var privacy := _label("VERSION %s\nLokal gespeichert · keine Anmeldung · keine Werbung · kein Tracking" % version, 10, MUTED)
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	privacy.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	box.add_child(privacy)
	var reset_button := _settings_button("SPIELSTAND ZURÜCKSETZEN", "Alle lokalen Fortschritte dauerhaft löschen")
	reset_button.add_theme_color_override("font_color", RED)
	reset_button.pressed.connect(func() -> void:
		_show_reset_confirmation(overlay)
	)
	box.add_child(reset_button)
	var close := Button.new()
	close.text = "FERTIG"
	close.custom_minimum_size.y = 56
	close.add_theme_font_size_override("font_size", 14)
	close.add_theme_color_override("font_color", Color("071811"))
	close.add_theme_stylebox_override("normal", UiSkin.primary_button())
	close.add_theme_stylebox_override("hover", UiSkin.primary_button())
	close.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	close.pressed.connect(func() -> void:
		sfx.play_cue("click")
		overlay.queue_free()
	)
	box.add_child(close)
	_forward_touch_scrolling(box)


func _show_reset_confirmation(settings_overlay: Control) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Spielstand zurücksetzen?"
	dialog.dialog_text = "Geld, Ruf, Aufträge, Team und alle Verbesserungen werden dauerhaft gelöscht."
	dialog.ok_button_text = "Zurücksetzen"
	dialog.cancel_button_text = "Abbrechen"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		game.set_process(false)
		if game.delete_save():
			if is_instance_valid(settings_overlay):
				settings_overlay.queue_free()
			get_tree().reload_current_scene()
		else:
			game.set_process(true)
			_show_toast("Spielstand konnte nicht gelöscht werden.")
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(360, 220))


func _settings_button(title: String, description: String) -> Button:
	var button := Button.new()
	button.tooltip_text = description
	button.custom_minimum_size.y = 66
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", UiSkin.panel())
	button.add_theme_stylebox_override("hover", UiSkin.active_nav())
	button.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	button.text = title
	return button


func _show_tutorial() -> void:
	var steps := [
		["01 · DEIN ERSTER AUFTRAG", "Starte mit kleinen Reparaturen in der Nachbarschaft. Jeder Auftrag bringt Geld, XP und eine stärkere Auftragsserie."],
		["02 · BETRIEB AUSBAUEN", "Investiere Einnahmen in Werkzeug, Transporter und Büro. So steigen Lohn, Tempo und das passive Einkommen."],
		["03 · TEAM AUFBAUEN", "Mitarbeiter verdienen dauerhaft Geld – sogar bis zu acht Stunden während du nicht spielst."],
		["04 · NEUE STANDORTE", "Steige im Betriebslevel auf, erschließe Premium-Gebiete und hole tägliche Ziele sowie Karriere-Erfolge ab."],
	]
	var overlay := ColorRect.new()
	overlay.color = Color("09110fe8")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 430)
	panel.add_theme_stylebox_override("panel", UiSkin.hero())
	center.add_child(panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 26, 26, 28, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	var eyebrow := _label("KAMILUNAVO · SCHNELLSTART", 10, GREEN, true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var medallion := PanelContainer.new()
	medallion.custom_minimum_size = Vector2(82, 82)
	medallion.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medallion.add_theme_stylebox_override("panel", UiSkin.medallion())
	var medallion_text := _label("IH", 23, GOLD, true)
	medallion_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medallion_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	medallion.add_child(medallion_text)
	box.add_child(medallion)
	var title := _label("", 22, TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var body := _label("", 13, MUTED)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	var progress := _label("", 10, GOLD, true)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(progress)
	var next := Button.new()
	next.custom_minimum_size.y = 58
	next.add_theme_font_size_override("font_size", 15)
	next.add_theme_color_override("font_color", Color("071811"))
	next.add_theme_stylebox_override("normal", UiSkin.primary_button())
	next.add_theme_stylebox_override("hover", UiSkin.primary_button())
	next.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	box.add_child(next)
	var index := [0]
	var render_step := func() -> void:
		title.text = str(steps[index[0]][0])
		body.text = str(steps[index[0]][1])
		progress.text = "SCHRITT %d VON %d" % [index[0] + 1, steps.size()]
		next.text = "LOSLEGEN" if index[0] == steps.size() - 1 else "WEITER"
	render_step.call()
	next.pressed.connect(func() -> void:
		sfx.play_cue("start")
		_haptic(20, 0.35)
		if index[0] < steps.size() - 1:
			index[0] += 1
			render_step.call()
			_punch(panel)
			return
		game.finish_tutorial()
		overlay.queue_free()
		if game.offline_reward > 0.0:
			_show_offline_dialog()
	)


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
	label.scale = Vector2.ONE if game.reduced_motion else Vector2(0.7, 0.7)
	label.pivot_offset = label.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 90.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not game.reduced_motion:
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
	row.add_theme_constant_override("separation", 10)
	var heading := _label(title, 17, TEXT, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	row.add_child(heading)
	var action_label := _label(action, 10, GREEN, true)
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	row.add_child(action_label)
	return row


func _stat_card(title: String, value: String, caption: String) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiSkin.panel())
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
	card.add_theme_stylebox_override("panel", UiSkin.hero())
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
	card.add_theme_stylebox_override("panel", UiSkin.panel())
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
	panel.add_theme_stylebox_override("panel", UiSkin.medallion())
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
	label.custom_minimum_size.y = ceilf(float(font_size) * 1.45)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override("font", app_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(color, 0.2))
	return label


func _forward_touch_scrolling(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not child is BaseButton:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_forward_touch_scrolling(child)


func _is_compact() -> bool:
	return get_viewport_rect().size.x <= 480.0


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
	button.add_theme_stylebox_override("normal", UiSkin.primary_button())
	button.add_theme_stylebox_override("hover", UiSkin.primary_button())
	button.add_theme_stylebox_override("pressed", UiSkin.pressed_button())
	button.add_theme_stylebox_override("disabled", UiSkin.dark_button())


func _style_nav(button: Button, active: bool) -> void:
	var fg := GREEN if active else MUTED
	button.add_theme_color_override("font_color", fg)
	button.add_theme_stylebox_override("normal", UiSkin.active_nav() if active else _box(Color.TRANSPARENT, 13))
	button.add_theme_stylebox_override("hover", UiSkin.active_nav() if active else UiSkin.dark_button())
	button.add_theme_stylebox_override("pressed", UiSkin.pressed_button())


func _punch(control: Control) -> void:
	if game.reduced_motion:
		return
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2(0.94, 0.94), 0.07)
	tween.tween_property(control, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)


func _haptic(duration_ms: int, strength: float) -> void:
	if game.haptics_enabled:
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
