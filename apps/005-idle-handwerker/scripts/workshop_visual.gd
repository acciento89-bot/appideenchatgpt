class_name WorkshopVisual
extends Control

const INK := Color("0b1814")
const WALL := Color("17342a")
const WALL_LIGHT := Color("21483a")
const FLOOR := Color("10251e")
const GREEN := Color("4bd38c")
const GREEN_LIGHT := Color("8cf0b9")
const GOLD := Color("f3b553")
const BLUE := Color("6f92f4")
const SKIN := Color("e7ad7f")
const OVERALL := Color("315f96")
const WHITE := Color("edf8f2")

var active_job_id := ""
var job_progress := 0.0
var _time := 0.0
class_name WorkshopVisual
extends Control

const INK := Color("071522")
const WALL := Color("12324b")
const WALL_LIGHT := Color("245674")
const FLOOR := Color("0a2031")
const GREEN := Color("35b9e6")
const GREEN_LIGHT := Color("a6e7f5")
const GOLD := Color("f28c28")
const BLUE := Color("4a8fe7")
const SKIN := Color("e7ad7f")
const OVERALL := Color("315f96")
const WHITE := Color("f3f8fb")

var active_job_id := ""
var job_progress := 0.0
var _time := 0.0
var _particles: Array[Dictionary] = []
var _celebration_time := 0.0
var tool_level := 0
var van_level := 0
var office_level := 0
var team_size := 0
var business_level := 1
var location_id := "neighborhood"
var contract_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	_celebration_time = maxf(0.0, _celebration_time - delta)
	for particle in _particles:
		particle.position += particle.velocity * delta
		particle.velocity.y += 115.0 * delta
		particle.life -= delta
	_particles = _particles.filter(func(particle: Dictionary) -> bool: return particle.life > 0.0)
	queue_redraw()


func set_job(job_id: String, progress: float) -> void:
	active_job_id = job_id
	job_progress = clampf(progress, 0.0, 1.0)


func set_progression(upgrades: Dictionary, employees: Dictionary, level: int, current_location_id: String, contracts: Dictionary = {}) -> void:
	tool_level = int(upgrades.get("tools", 0))
	van_level = int(upgrades.get("van", 0))
	office_level = int(upgrades.get("office", 0))
	team_size = 0
	for value in employees.values():
		team_size += int(value)
	business_level = level
	location_id = current_location_id
	contract_count = contracts.size()
	queue_redraw()


func celebrate(streak := 1) -> void:
	_celebration_time = 1.2
	var amount := mini(52, 24 + streak * 4)
	for index in range(amount):
		var angle := lerpf(-PI * 0.92, -PI * 0.08, float(index) / float(amount - 1))
		var speed := 70.0 + float((index * 29) % 75)
		_particles.append({
			"position": Vector2(size.x * 0.63, size.y * 0.42),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": 0.75 + float(index % 5) * 0.09,
			"color": [GREEN, GOLD, BLUE, WHITE][index % 4],
			"radius": 2.0 + float(index % 3),
		})


func _draw() -> void:
	var width := size.x
	var height := size.y
	if width <= 1.0 or height <= 1.0:
		return

	# Workshop shell evolves from a small garage into a modern operation.
	var wall_color := WALL
	if business_level >= 5:
		wall_color = Color("173f5c")
	if business_level >= 9:
		wall_color = Color("1c4968")
	draw_rect(Rect2(0, 0, width, height), wall_color, true)
	for stripe in range(6):
		var x := float(stripe) * width / 6.0
		draw_rect(Rect2(x, 0, 1.0, height * 0.73), Color("2b5c78"), true)
	draw_rect(Rect2(0, height * 0.72, width, height * 0.28), FLOOR, true)
	draw_line(Vector2(0, height * 0.72), Vector2(width, height * 0.72), Color("347b9d"), 2.0)

	# Window and daylight.
	var window_rect := Rect2(width * 0.06, height * 0.12, width * 0.24, height * 0.29)
	draw_style_box(_flat_box(Color("c9edf7"), 5, Color("071522"), 3), window_rect)
	draw_line(Vector2(window_rect.position.x + window_rect.size.x * 0.5, window_rect.position.y), Vector2(window_rect.position.x + window_rect.size.x * 0.5, window_rect.end.y), WALL_LIGHT, 2.0)
	draw_line(Vector2(window_rect.position.x, window_rect.position.y + window_rect.size.y * 0.52), Vector2(window_rect.end.x, window_rect.position.y + window_rect.size.y * 0.52), WALL_LIGHT, 2.0)

	# Pipe installation changes subtly with the active job.
	var pipe_color := GOLD if active_job_id == "boiler" else Color("b4c8d4")
	var pipe_y := height * 0.18
	draw_line(Vector2(width * 0.36, pipe_y), Vector2(width * 0.72, pipe_y), pipe_color, 7.0, true)
	draw_line(Vector2(width * 0.72, pipe_y), Vector2(width * 0.72, height * 0.46), pipe_color, 7.0, true)
	draw_circle(Vector2(width * 0.72, height * 0.48), 8.0, GREEN if active_job_id != "" else Color("5d788b"))
	draw_circle(Vector2(width * 0.72, height * 0.48), 3.0, INK)

	# Workbench and tools.
	var bench_y := height * 0.61
	draw_rect(Rect2(width * 0.06, bench_y, width * 0.35, 8), Color("986239"), true)
	draw_rect(Rect2(width * 0.09, bench_y + 8, 6, height * 0.24), Color("604027"), true)
	draw_rect(Rect2(width * 0.36, bench_y + 8, 6, height * 0.24), Color("604027"), true)
	draw_line(Vector2(width * 0.14, bench_y - 2), Vector2(width * 0.14, bench_y - 19), GREEN_LIGHT, 4.0, true)
	draw_line(Vector2(width * 0.14, bench_y - 19), Vector2(width * 0.19, bench_y - 19), GREEN_LIGHT, 4.0, true)
	draw_line(Vector2(width * 0.25, bench_y - 2), Vector2(width * 0.30, bench_y - 18), GOLD, 4.0, true)
	_draw_progression_details(width, height, bench_y)

	_draw_worker(Vector2(width * 0.57, height * 0.66))
	_draw_van(Vector2(width * 0.79, height * 0.73), Vector2(width * 0.18, height * 0.17))

	if active_job_id != "":
		_draw_work_effect(Vector2(width * 0.68, height * 0.48))
	if active_job_id in ["school_heating", "villa_energy", "production_hall", "clinic_energy_center"]:
		_draw_major_project(width, height)

	for particle in _particles:
		draw_circle(particle.position, particle.radius, particle.color)


func _draw_major_project(width: float, height: float) -> void:
	var pulse := 0.55 + sin(_time * 5.0) * 0.15
	draw_style_box(_flat_box(Color("0b2234"), 4, GOLD, 2), Rect2(width * 0.32, height * 0.28, width * 0.24, height * 0.19))
	draw_line(Vector2(width * 0.35, height * 0.33), Vector2(width * 0.52, height * 0.33), BLUE, 2.0)
	draw_line(Vector2(width * 0.35, height * 0.38), Vector2(width * 0.48, height * 0.38), BLUE, 2.0)
	draw_circle(Vector2(width * 0.54, height * 0.3), 4.0 + pulse * 2.0, GOLD)
	draw_string(ThemeDB.fallback_font, Vector2(width * 0.34, height * 0.44), "GROSSPROJEKT", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, GOLD)


func _draw_progression_details(width: float, height: float, bench_y: float) -> void:
	# Each purchased tool level fills the shadow board visibly.
	if tool_level > 0:
		draw_style_box(_flat_box(Color("0d283d"), 4, Color("397999"), 1), Rect2(width * 0.055, height * 0.42, width * 0.36, height * 0.13))
		var shown_tools := mini(tool_level + 1, 6)
		for index in range(shown_tools):
			var x := width * 0.085 + float(index) * width * 0.047
			draw_line(Vector2(x, height * 0.45), Vector2(x + 3, height * 0.52), GREEN_LIGHT if index % 2 == 0 else GOLD, 3.0, true)

	# Digital office upgrade adds a glowing dispatch screen.
	if office_level > 0:
		var monitor := Rect2(width * 0.29, bench_y - height * 0.17, width * 0.105, height * 0.12)
		draw_style_box(_flat_box(Color("061826"), 3, GREEN, 1), monitor)
		for line in range(mini(office_level + 1, 4)):
			draw_line(monitor.position + Vector2(5, 6 + line * 5), monitor.position + Vector2(monitor.size.x - 5, 6 + line * 5), GREEN, 1.0)

	# Team members become visible as colored helmets on the rack.
	for index in range(mini(team_size, 5)):
		var helmet_center := Vector2(width * 0.43 + float(index) * 13.0, height * 0.31)
		draw_arc(helmet_center, 5.0, PI, TAU, 10, [GOLD, GREEN, BLUE][index % 3], 4.0, true)
		draw_line(helmet_center + Vector2(-6, 0), helmet_center + Vector2(6, 0), INK, 2.0)

	# Higher locations add a contract board and premium signage.
	if location_id != "neighborhood":
		draw_style_box(_flat_box(Color("dbeaf1"), 2, INK, 1), Rect2(width * 0.77, height * 0.1, width * 0.17, height * 0.19))
		draw_string(ThemeDB.fallback_font, Vector2(width * 0.79, height * 0.17), "AUFTRÄGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, WALL)
		for index in range(mini(contract_count, 4)):
			draw_circle(Vector2(width * 0.79 + index * 6.0, height * 0.24), 2.0, GOLD)
	if business_level >= 9:
		draw_string(ThemeDB.fallback_font, Vector2(width * 0.36, height * 0.1), "MEISTERBETRIEB", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, GOLD)


func _draw_worker(origin: Vector2) -> void:
	var working := active_job_id != ""
	var bob := sin(_time * (9.0 if working else 2.2)) * (2.2 if working else 0.8)
	if _celebration_time > 0.0:
		bob -= absf(sin(_time * 12.0)) * 7.0
	var body_origin := origin + Vector2(0, bob)

	# Legs and boots.
	draw_line(body_origin + Vector2(-7, 20), body_origin + Vector2(-9, 42), OVERALL, 7.0, true)
	draw_line(body_origin + Vector2(7, 20), body_origin + Vector2(10, 42), OVERALL, 7.0, true)
	draw_line(body_origin + Vector2(-12, 43), body_origin + Vector2(-4, 43), INK, 6.0, true)
	draw_line(body_origin + Vector2(7, 43), body_origin + Vector2(15, 43), INK, 6.0, true)

	# Body, head and helmet.
	draw_style_box(_flat_box(OVERALL, 7), Rect2(body_origin + Vector2(-15, -11), Vector2(30, 36)))
	draw_circle(body_origin + Vector2(0, -25), 12.0, SKIN)
	draw_arc(body_origin + Vector2(0, -27), 13.0, PI, TAU, 18, GOLD, 7.0, true)
	draw_rect(Rect2(body_origin + Vector2(-15, -28), Vector2(30, 5)), GOLD, true)
	draw_circle(body_origin + Vector2(-4, -25), 1.3, INK)
	draw_circle(body_origin + Vector2(4, -25), 1.3, INK)
	draw_arc(body_origin + Vector2(0, -20), 4.0, 0.15, PI - 0.15, 8, INK, 1.4, true)

	# Arms and active tool motion.
	var swing := sin(_time * 12.0) if working else sin(_time * 2.0) * 0.12
	if _celebration_time > 0.0:
		swing = -1.0
	var left_hand := body_origin + Vector2(-22, 5 + swing * 7.0)
	var right_hand := body_origin + Vector2(23, 3 - swing * 9.0)
	draw_line(body_origin + Vector2(-12, -2), left_hand, SKIN, 6.0, true)
	draw_line(body_origin + Vector2(12, -2), right_hand, SKIN, 6.0, true)
	if working:
		draw_line(right_hand, right_hand + Vector2(7, -15), Color("cad8d2"), 4.0, true)
		draw_line(right_hand + Vector2(2, -16), right_hand + Vector2(13, -13), GOLD, 5.0, true)


func _draw_van(center: Vector2, van_size: Vector2) -> void:
	var rect := Rect2(center - van_size * Vector2(0.5, 1.0), van_size)
	draw_style_box(_flat_box(Color("edf4f7"), 7), rect)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.56, 5), Vector2(rect.size.x * 0.34, rect.size.y * 0.35)), Color("a9d7e8"), true)
	var stripe_color := GOLD if van_level >= 3 else GREEN
	draw_rect(Rect2(rect.position + Vector2(8, rect.size.y * 0.42), Vector2(rect.size.x * 0.44, 5)), stripe_color, true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.36), "SHK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, WALL)
	if van_level >= 1:
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.1, -4), Vector2(rect.size.x * 0.58, 4)), Color("9bb8ac"), true)
	if van_level >= 4:
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.72), "24H", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, stripe_color)
	draw_circle(rect.position + Vector2(rect.size.x * 0.22, rect.size.y), 7.0, INK)
	draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y), 7.0, INK)
	draw_circle(rect.position + Vector2(rect.size.x * 0.22, rect.size.y), 3.0, Color("7f938b"))
	draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y), 3.0, Color("7f938b"))


func _draw_work_effect(center: Vector2) -> void:
	var pulse := 0.5 + sin(_time * 14.0) * 0.5
	for ray in range(5):
		var angle := float(ray) / 5.0 * TAU + _time * 0.8
		var inner := center + Vector2.from_angle(angle) * (7.0 + pulse * 2.0)
		var outer := center + Vector2.from_angle(angle) * (12.0 + pulse * 4.0)
		draw_line(inner, outer, GOLD, 2.0, true)
	if active_job_id == "tap" or active_job_id == "drain":
		var drop_y := fmod(_time * 34.0, 18.0)
		draw_circle(center + Vector2(15, drop_y), 2.2, BLUE)


func _flat_box(color: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
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
var _particles: Array[Dictionary] = []
var _celebration_time := 0.0
var tool_level := 0
var van_level := 0
var office_level := 0
var team_size := 0
var business_level := 1
var location_id := "neighborhood"
var contract_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	_celebration_time = maxf(0.0, _celebration_time - delta)
	for particle in _particles:
		particle.position += particle.velocity * delta
		particle.velocity.y += 115.0 * delta
		particle.life -= delta
	_particles = _particles.filter(func(particle: Dictionary) -> bool: return particle.life > 0.0)
	queue_redraw()


func set_job(job_id: String, progress: float) -> void:
	active_job_id = job_id
	job_progress = clampf(progress, 0.0, 1.0)


func set_progression(upgrades: Dictionary, employees: Dictionary, level: int, current_location_id: String, contracts: Dictionary = {}) -> void:
	tool_level = int(upgrades.get("tools", 0))
	van_level = int(upgrades.get("van", 0))
	office_level = int(upgrades.get("office", 0))
	team_size = 0
	for value in employees.values():
		team_size += int(value)
	business_level = level
	location_id = current_location_id
	contract_count = contracts.size()
	queue_redraw()


func celebrate(streak := 1) -> void:
	_celebration_time = 1.2
	var amount := mini(52, 24 + streak * 4)
	for index in range(amount):
		var angle := lerpf(-PI * 0.92, -PI * 0.08, float(index) / float(amount - 1))
		var speed := 70.0 + float((index * 29) % 75)
		_particles.append({
			"position": Vector2(size.x * 0.63, size.y * 0.42),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": 0.75 + float(index % 5) * 0.09,
			"color": [GREEN, GOLD, BLUE, WHITE][index % 4],
			"radius": 2.0 + float(index % 3),
		})


func _draw() -> void:
	var width := size.x
	var height := size.y
	if width <= 1.0 or height <= 1.0:
		return

	# Workshop shell evolves from a small garage into a modern operation.
	var wall_color := WALL
	if business_level >= 5:
		wall_color = Color("1a3c31")
	if business_level >= 9:
		wall_color = Color("203f36")
	draw_rect(Rect2(0, 0, width, height), wall_color, true)
	for stripe in range(6):
		var x := float(stripe) * width / 6.0
		draw_rect(Rect2(x, 0, 1.0, height * 0.73), Color("285343"), true)
	draw_rect(Rect2(0, height * 0.72, width, height * 0.28), FLOOR, true)
	draw_line(Vector2(0, height * 0.72), Vector2(width, height * 0.72), Color("34745a"), 2.0)

	# Window and daylight.
	var window_rect := Rect2(width * 0.06, height * 0.12, width * 0.24, height * 0.29)
	draw_style_box(_flat_box(Color("bdebdc"), 5, Color("0c2019"), 3), window_rect)
	draw_line(Vector2(window_rect.position.x + window_rect.size.x * 0.5, window_rect.position.y), Vector2(window_rect.position.x + window_rect.size.x * 0.5, window_rect.end.y), WALL_LIGHT, 2.0)
	draw_line(Vector2(window_rect.position.x, window_rect.position.y + window_rect.size.y * 0.52), Vector2(window_rect.end.x, window_rect.position.y + window_rect.size.y * 0.52), WALL_LIGHT, 2.0)

	# Pipe installation changes subtly with the active job.
	var pipe_color := GOLD if active_job_id == "boiler" else Color("a9c1b7")
	var pipe_y := height * 0.18
	draw_line(Vector2(width * 0.36, pipe_y), Vector2(width * 0.72, pipe_y), pipe_color, 7.0, true)
	draw_line(Vector2(width * 0.72, pipe_y), Vector2(width * 0.72, height * 0.46), pipe_color, 7.0, true)
	draw_circle(Vector2(width * 0.72, height * 0.48), 8.0, GREEN if active_job_id != "" else Color("59766b"))
	draw_circle(Vector2(width * 0.72, height * 0.48), 3.0, INK)

	# Workbench and tools.
	var bench_y := height * 0.61
	draw_rect(Rect2(width * 0.06, bench_y, width * 0.35, 8), Color("986239"), true)
	draw_rect(Rect2(width * 0.09, bench_y + 8, 6, height * 0.24), Color("604027"), true)
	draw_rect(Rect2(width * 0.36, bench_y + 8, 6, height * 0.24), Color("604027"), true)
	draw_line(Vector2(width * 0.14, bench_y - 2), Vector2(width * 0.14, bench_y - 19), GREEN_LIGHT, 4.0, true)
	draw_line(Vector2(width * 0.14, bench_y - 19), Vector2(width * 0.19, bench_y - 19), GREEN_LIGHT, 4.0, true)
	draw_line(Vector2(width * 0.25, bench_y - 2), Vector2(width * 0.30, bench_y - 18), GOLD, 4.0, true)
	_draw_progression_details(width, height, bench_y)

	_draw_worker(Vector2(width * 0.57, height * 0.66))
	_draw_van(Vector2(width * 0.79, height * 0.73), Vector2(width * 0.18, height * 0.17))

	if active_job_id != "":
		_draw_work_effect(Vector2(width * 0.68, height * 0.48))
	if active_job_id in ["school_heating", "villa_energy", "production_hall", "clinic_energy_center"]:
		_draw_major_project(width, height)

	for particle in _particles:
		draw_circle(particle.position, particle.radius, particle.color)


func _draw_major_project(width: float, height: float) -> void:
	var pulse := 0.55 + sin(_time * 5.0) * 0.15
	draw_style_box(_flat_box(Color("10231c"), 4, GOLD, 2), Rect2(width * 0.32, height * 0.28, width * 0.24, height * 0.19))
	draw_line(Vector2(width * 0.35, height * 0.33), Vector2(width * 0.52, height * 0.33), BLUE, 2.0)
	draw_line(Vector2(width * 0.35, height * 0.38), Vector2(width * 0.48, height * 0.38), BLUE, 2.0)
	draw_circle(Vector2(width * 0.54, height * 0.3), 4.0 + pulse * 2.0, GOLD)
	draw_string(ThemeDB.fallback_font, Vector2(width * 0.34, height * 0.44), "GROSSPROJEKT", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, GOLD)


func _draw_progression_details(width: float, height: float, bench_y: float) -> void:
	# Each purchased tool level fills the shadow board visibly.
	if tool_level > 0:
		draw_style_box(_flat_box(Color("10271f"), 4, Color("4a8068"), 1), Rect2(width * 0.055, height * 0.42, width * 0.36, height * 0.13))
		var shown_tools := mini(tool_level + 1, 6)
		for index in range(shown_tools):
			var x := width * 0.085 + float(index) * width * 0.047
			draw_line(Vector2(x, height * 0.45), Vector2(x + 3, height * 0.52), GREEN_LIGHT if index % 2 == 0 else GOLD, 3.0, true)

	# Digital office upgrade adds a glowing dispatch screen.
	if office_level > 0:
		var monitor := Rect2(width * 0.29, bench_y - height * 0.17, width * 0.105, height * 0.12)
		draw_style_box(_flat_box(Color("071712"), 3, GREEN, 1), monitor)
		for line in range(mini(office_level + 1, 4)):
			draw_line(monitor.position + Vector2(5, 6 + line * 5), monitor.position + Vector2(monitor.size.x - 5, 6 + line * 5), GREEN, 1.0)

	# Team members become visible as colored helmets on the rack.
	for index in range(mini(team_size, 5)):
		var helmet_center := Vector2(width * 0.43 + float(index) * 13.0, height * 0.31)
		draw_arc(helmet_center, 5.0, PI, TAU, 10, [GOLD, GREEN, BLUE][index % 3], 4.0, true)
		draw_line(helmet_center + Vector2(-6, 0), helmet_center + Vector2(6, 0), INK, 2.0)

	# Higher locations add a contract board and premium signage.
	if location_id != "neighborhood":
		draw_style_box(_flat_box(Color("d6e7df"), 2, INK, 1), Rect2(width * 0.77, height * 0.1, width * 0.17, height * 0.19))
		draw_string(ThemeDB.fallback_font, Vector2(width * 0.79, height * 0.17), "AUFTRÄGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, WALL)
		for index in range(mini(contract_count, 4)):
			draw_circle(Vector2(width * 0.79 + index * 6.0, height * 0.24), 2.0, GOLD)
	if business_level >= 9:
		draw_string(ThemeDB.fallback_font, Vector2(width * 0.36, height * 0.1), "MEISTERBETRIEB", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, GOLD)


func _draw_worker(origin: Vector2) -> void:
	var working := active_job_id != ""
	var bob := sin(_time * (9.0 if working else 2.2)) * (2.2 if working else 0.8)
	if _celebration_time > 0.0:
		bob -= absf(sin(_time * 12.0)) * 7.0
	var body_origin := origin + Vector2(0, bob)

	# Legs and boots.
	draw_line(body_origin + Vector2(-7, 20), body_origin + Vector2(-9, 42), OVERALL, 7.0, true)
	draw_line(body_origin + Vector2(7, 20), body_origin + Vector2(10, 42), OVERALL, 7.0, true)
	draw_line(body_origin + Vector2(-12, 43), body_origin + Vector2(-4, 43), INK, 6.0, true)
	draw_line(body_origin + Vector2(7, 43), body_origin + Vector2(15, 43), INK, 6.0, true)

	# Body, head and helmet.
	draw_style_box(_flat_box(OVERALL, 7), Rect2(body_origin + Vector2(-15, -11), Vector2(30, 36)))
	draw_circle(body_origin + Vector2(0, -25), 12.0, SKIN)
	draw_arc(body_origin + Vector2(0, -27), 13.0, PI, TAU, 18, GOLD, 7.0, true)
	draw_rect(Rect2(body_origin + Vector2(-15, -28), Vector2(30, 5)), GOLD, true)
	draw_circle(body_origin + Vector2(-4, -25), 1.3, INK)
	draw_circle(body_origin + Vector2(4, -25), 1.3, INK)
	draw_arc(body_origin + Vector2(0, -20), 4.0, 0.15, PI - 0.15, 8, INK, 1.4, true)

	# Arms and active tool motion.
	var swing := sin(_time * 12.0) if working else sin(_time * 2.0) * 0.12
	if _celebration_time > 0.0:
		swing = -1.0
	var left_hand := body_origin + Vector2(-22, 5 + swing * 7.0)
	var right_hand := body_origin + Vector2(23, 3 - swing * 9.0)
	draw_line(body_origin + Vector2(-12, -2), left_hand, SKIN, 6.0, true)
	draw_line(body_origin + Vector2(12, -2), right_hand, SKIN, 6.0, true)
	if working:
		draw_line(right_hand, right_hand + Vector2(7, -15), Color("cad8d2"), 4.0, true)
		draw_line(right_hand + Vector2(2, -16), right_hand + Vector2(13, -13), GOLD, 5.0, true)


func _draw_van(center: Vector2, van_size: Vector2) -> void:
	var rect := Rect2(center - van_size * Vector2(0.5, 1.0), van_size)
	draw_style_box(_flat_box(Color("eaf5ef"), 7), rect)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.56, 5), Vector2(rect.size.x * 0.34, rect.size.y * 0.35)), Color("a9d9d4"), true)
	var stripe_color := GOLD if van_level >= 3 else GREEN
	draw_rect(Rect2(rect.position + Vector2(8, rect.size.y * 0.42), Vector2(rect.size.x * 0.44, 5)), stripe_color, true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.36), "SHK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, WALL)
	if van_level >= 1:
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.1, -4), Vector2(rect.size.x * 0.58, 4)), Color("9bb8ac"), true)
	if van_level >= 4:
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.72), "24H", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, stripe_color)
	draw_circle(rect.position + Vector2(rect.size.x * 0.22, rect.size.y), 7.0, INK)
	draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y), 7.0, INK)
	draw_circle(rect.position + Vector2(rect.size.x * 0.22, rect.size.y), 3.0, Color("7f938b"))
	draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y), 3.0, Color("7f938b"))


func _draw_work_effect(center: Vector2) -> void:
	var pulse := 0.5 + sin(_time * 14.0) * 0.5
	for ray in range(5):
		var angle := float(ray) / 5.0 * TAU + _time * 0.8
		var inner := center + Vector2.from_angle(angle) * (7.0 + pulse * 2.0)
		var outer := center + Vector2.from_angle(angle) * (12.0 + pulse * 4.0)
		draw_line(inner, outer, GOLD, 2.0, true)
	if active_job_id == "tap" or active_job_id == "drain":
		var drop_y := fmod(_time * 34.0, 18.0)
		draw_circle(center + Vector2(15, drop_y), 2.2, BLUE)


func _flat_box(color: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
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
