class_name GameState
extends Node

signal changed
signal job_started(job: Dictionary)
signal job_completed(job: Dictionary, reward: float)
signal level_up(new_level: int)
signal notice(message: String)

const SAVE_PATH := "user://idle_handwerker_save.json"
const OFFLINE_CAP_SECONDS := 8.0 * 60.0 * 60.0

var money := 120.0
var lifetime_earnings := 0.0
var level := 1
var xp := 0
var completed_jobs := 0
var upgrades := {"tools": 0, "van": 0, "office": 0}
var employees := {"azubi": 0, "monteur": 0, "meisterin": 0}
var active_job_id := ""
var active_job_remaining := 0.0
var active_job_total := 0.0
var offline_reward := 0.0
var last_saved_unix := 0
var _autosave_elapsed := 0.0


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	var passive := passive_income_per_second()
	if passive > 0.0:
		money += passive * delta
		lifetime_earnings += passive * delta

	if active_job_id != "":
		active_job_remaining = maxf(0.0, active_job_remaining - delta)
		if active_job_remaining <= 0.0:
			complete_active_job()

	_autosave_elapsed += delta
	if _autosave_elapsed >= 5.0:
		_autosave_elapsed = 0.0
		save_game()
	changed.emit()


func get_job(job_id: String) -> Dictionary:
	for job in GameData.JOBS:
		if job.id == job_id:
			return job
	return {}


func start_job(job_id: String) -> bool:
	if active_job_id != "":
		notice.emit("Ein Auftrag läuft bereits.")
		return false
	var job := get_job(job_id)
	if job.is_empty():
		return false
	if level < int(job.level):
		notice.emit("Ab Betriebsstufe %d verfügbar." % int(job.level))
		return false
	active_job_id = job_id
	active_job_total = maxf(1.0, float(job.duration) * job_duration_multiplier())
	active_job_remaining = active_job_total
	job_started.emit(job)
	changed.emit()
	save_game()
	return true


func complete_active_job() -> void:
	var job := get_job(active_job_id)
	if job.is_empty():
		active_job_id = ""
		return
	var reward := float(job.reward) * job_reward_multiplier()
	money += reward
	lifetime_earnings += reward
	completed_jobs += 1
	add_xp(int(job.xp))
	active_job_id = ""
	active_job_remaining = 0.0
	active_job_total = 0.0
	job_completed.emit(job, reward)
	changed.emit()
	save_game()


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= GameData.xp_for_level(level):
		xp -= GameData.xp_for_level(level)
		level += 1
		level_up.emit(level)


func buy_upgrade(upgrade_id: String) -> bool:
	for upgrade in GameData.UPGRADES:
		if upgrade.id != upgrade_id:
			continue
		var current := int(upgrades.get(upgrade_id, 0))
		var cost := GameData.upgrade_cost(upgrade, current)
		if money < cost:
			notice.emit("Dafür fehlen noch %s." % GameData.format_money(cost - money))
			return false
		money -= cost
		upgrades[upgrade_id] = current + 1
		notice.emit("%s auf Stufe %d verbessert!" % [upgrade.title, current + 1])
		changed.emit()
		save_game()
		return true
	return false


func hire_employee(employee_id: String) -> bool:
	for employee in GameData.EMPLOYEES:
		if employee.id != employee_id:
			continue
		var owned := int(employees.get(employee_id, 0))
		var cost := GameData.employee_cost(employee, owned)
		if money < cost:
			notice.emit("Dafür fehlen noch %s." % GameData.format_money(cost - money))
			return false
		money -= cost
		employees[employee_id] = owned + 1
		notice.emit("%s verstärkt jetzt dein Team!" % employee.title)
		changed.emit()
		save_game()
		return true
	return false


func job_reward_multiplier() -> float:
	return 1.0 + float(upgrades.tools) * 0.2


func job_duration_multiplier() -> float:
	return maxf(0.42, 1.0 - float(upgrades.van) * 0.12)


func passive_income_per_second() -> float:
	var base := 0.0
	for employee in GameData.EMPLOYEES:
		base += float(employee.income) * int(employees.get(employee.id, 0))
	return base * (1.0 + float(upgrades.office) * 0.25)


func active_job_progress() -> float:
	if active_job_id == "" or active_job_total <= 0.0:
		return 0.0
	return clampf(1.0 - active_job_remaining / active_job_total, 0.0, 1.0)


func claim_offline_reward() -> float:
	var reward := offline_reward
	offline_reward = 0.0
	changed.emit()
	return reward


func save_game() -> void:
	last_saved_unix = int(Time.get_unix_time_from_system())
	var payload := {
		"version": 1,
		"money": money,
		"lifetime_earnings": lifetime_earnings,
		"level": level,
		"xp": xp,
		"completed_jobs": completed_jobs,
		"upgrades": upgrades,
		"employees": employees,
		"active_job_id": active_job_id,
		"active_job_remaining": active_job_remaining,
		"active_job_total": active_job_total,
		"last_saved_unix": last_saved_unix,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		last_saved_unix = int(Time.get_unix_time_from_system())
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	money = maxf(0.0, float(parsed.get("money", money)))
	lifetime_earnings = maxf(0.0, float(parsed.get("lifetime_earnings", 0.0)))
	level = maxi(1, int(parsed.get("level", 1)))
	xp = maxi(0, int(parsed.get("xp", 0)))
	completed_jobs = maxi(0, int(parsed.get("completed_jobs", 0)))
	upgrades.merge(parsed.get("upgrades", {}), true)
	employees.merge(parsed.get("employees", {}), true)
	active_job_id = str(parsed.get("active_job_id", ""))
	active_job_remaining = maxf(0.0, float(parsed.get("active_job_remaining", 0.0)))
	active_job_total = maxf(0.0, float(parsed.get("active_job_total", 0.0)))
	last_saved_unix = int(parsed.get("last_saved_unix", Time.get_unix_time_from_system()))
	var elapsed := clampf(float(Time.get_unix_time_from_system() - last_saved_unix), 0.0, OFFLINE_CAP_SECONDS)
	if elapsed > 10.0:
		offline_reward = passive_income_per_second() * elapsed
		money += offline_reward
		lifetime_earnings += offline_reward
		if active_job_id != "":
			active_job_remaining = maxf(0.0, active_job_remaining - elapsed)
			if active_job_remaining <= 0.0:
				complete_active_job()

