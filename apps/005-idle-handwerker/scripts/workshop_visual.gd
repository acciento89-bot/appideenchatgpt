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
var _particles: Array[Dictionary] = []
var _celebration_time := 0.0


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


func celebrate() -> void:
	_celebration_time = 1.2
	for index in range(26):
		var angle := lerpf(-PI * 0.92, -PI * 0.08, float(index) / 25.0)
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

	# Workshop shell.
	draw_rect(Rect2(0, 0, width, height), WALL, true)
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

	_draw_worker(Vector2(width * 0.57, height * 0.66))
	_draw_van(Vector2(width * 0.79, height * 0.73), Vector2(width * 0.18, height * 0.17))

	if active_job_id != "":
		_draw_work_effect(Vector2(width * 0.68, height * 0.48))

	for particle in _particles:
		draw_circle(particle.position, particle.radius, particle.color)


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
	draw_rect(Rect2(rect.position + Vector2(8, rect.size.y * 0.42), Vector2(rect.size.x * 0.44, 5)), GREEN, true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.36), "SHK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, WALL)
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

