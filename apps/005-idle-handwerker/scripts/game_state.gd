class_name GameState
extends Node

signal changed
signal job_started(job: Dictionary)
signal job_completed(job: Dictionary, reward: float)
signal job_event_started(event: Dictionary)
signal contract_signed(contract: Dictionary)
signal review_created(review: Dictionary)
signal level_up(new_level: int)
signal notice(message: String)

const SAVE_PATH := "user://idle_handwerker_save.json"
const OFFLINE_CAP_SECONDS := 8.0 * 60.0 * 60.0
const OFFLINE_EFFICIENCY := 0.5

var money := 120.0
var lifetime_earnings := 0.0
var level := 1
var xp := 0
var completed_jobs := 0
var current_streak := 0
var best_streak := 0
var last_job_completed_unix := 0
var upgrades := {"tools": 0, "van": 0, "office": 0}
var employees := {"azubi": 0, "monteur": 0, "meisterin": 0}
var active_job_id := ""
var active_job_remaining := 0.0
var active_job_total := 0.0
var job_cooldowns: Dictionary = {}
var active_event_id := ""
var offline_reward := 0.0
var offline_elapsed_seconds := 0.0
var last_saved_unix := 0
var current_location_id := "neighborhood"
var tutorial_completed := false
var daily_key := ""
var daily_progress := {"jobs": 0.0, "earnings": 0.0, "upgrades": 0.0, "streak": 0.0, "quality": 0.0}
var daily_claimed := {"jobs": false, "earnings": false, "invest": false, "streak": false, "quality": false}
var achievements_claimed: Dictionary = {}
var reputation := 0
var active_contracts: Dictionary = {}
var visited_locations: Dictionary = {"neighborhood": true}
var customer_rating := 4.0
var quality_samples := 0
var last_job_quality := 0
var completed_major_projects := 0
var recent_reviews: Array = []
var sound_enabled := true
var haptics_enabled := true
var reduced_motion := false
var save_path := SAVE_PATH
var _autosave_elapsed := 0.0


func _ready() -> void:
	load_game()
	_ensure_daily_state()


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
	var cooldown_remaining := job_cooldown_remaining(job_id)
	if cooldown_remaining > 0.0:
		notice.emit("Dieser Auftrag ist in %s wieder verfügbar." % format_cooldown(cooldown_remaining))
		return false
	if level < int(job.level):
		notice.emit("Ab Betriebsstufe %d verfügbar." % int(job.level))
		return false
	if str(job.location) != current_location_id:
		notice.emit("Dieser Auftrag gehört zu einem anderen Standort.")
		return false
	var required_reputation := int(job.get("reputation", 0))
	if reputation < required_reputation:
		notice.emit("Für dieses Großprojekt fehlen noch %d Rufpunkte." % (required_reputation - reputation))
		return false
	active_job_id = job_id
	active_event_id = _roll_job_event()
	active_job_total = maxf(1.0, float(job.duration) * job_duration_multiplier() * active_event_duration_multiplier())
	active_job_remaining = active_job_total
	job_started.emit(job)
	var event := active_event()
	if not event.is_empty():
		job_event_started.emit(event)
	changed.emit()
	save_game()
	return true


func complete_active_job(cooldown_elapsed := 0.0) -> void:
	var job := get_job(active_job_id)
	if job.is_empty():
		active_job_id = ""
		return
	_update_streak()
	last_job_quality = _calculate_job_quality(job)
	var quality_multiplier := 0.75 + float(last_job_quality) / 100.0 * 0.4
	var reward := float(job.reward) * job_reward_multiplier() * streak_reward_multiplier() * location_reward_multiplier() * active_event_reward_multiplier() * quality_multiplier
	money += reward
	lifetime_earnings += reward
	completed_jobs += 1
	var reputation_gain := maxi(2, int(round(float(job.xp) / 8.0 * float(last_job_quality) / 80.0)))
	if active_event_id == "recommendation":
		reputation_gain *= 2
	reputation += reputation_gain
	if bool(job.get("major", false)):
		completed_major_projects += 1
	var remaining_cooldown := maxf(0.0, float(job.get("cooldown", 0.0)) - cooldown_elapsed)
	job_cooldowns[str(job.id)] = int(Time.get_unix_time_from_system() + remaining_cooldown)
	var review := _create_review(job, last_job_quality)
	daily_progress.jobs = float(daily_progress.jobs) + 1.0
	daily_progress.earnings = float(daily_progress.earnings) + reward
	daily_progress.streak = maxf(float(daily_progress.get("streak", 0.0)), float(current_streak))
	daily_progress.quality = maxf(float(daily_progress.get("quality", 0.0)), float(last_job_quality))
	add_xp(int(round(float(job.xp) * active_event_xp_multiplier())))
	active_job_id = ""
	active_event_id = ""
	active_job_remaining = 0.0
	active_job_total = 0.0
	job_completed.emit(job, reward)
	review_created.emit(review)
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
		daily_progress.upgrades = float(daily_progress.upgrades) + 1.0
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
	return 1.0 + float(upgrades.tools) * 0.18


func streak_reward_multiplier() -> float:
	return 1.0 + float(mini(current_streak, 5)) * 0.03


func location_reward_multiplier() -> float:
	for location in GameData.LOCATIONS:
		if location.id == current_location_id:
			return float(location.multiplier)
	return 1.0


func active_event() -> Dictionary:
	for event in GameData.JOB_EVENTS:
		if event.id == active_event_id:
			return event
	return {}


func active_event_reward_multiplier() -> float:
	var event := active_event()
	return float(event.get("reward_multiplier", 1.0))


func active_event_duration_multiplier() -> float:
	var event := active_event()
	return float(event.get("duration_multiplier", 1.0))


func active_event_xp_multiplier() -> float:
	var event := active_event()
	return float(event.get("xp_multiplier", 1.0))


func _roll_job_event() -> String:
	if randf() > 0.38:
		return ""
	return str(GameData.JOB_EVENTS[randi() % GameData.JOB_EVENTS.size()].id)


func select_location(location_id: String) -> bool:
	for location in GameData.LOCATIONS:
		if location.id != location_id:
			continue
		if level < int(location.level):
			notice.emit("Standort ab Betriebsstufe %d verfügbar." % int(location.level))
			return false
		if active_job_id != "":
			notice.emit("Standortwechsel erst nach dem laufenden Auftrag.")
			return false
		var opening_new_location := requires_location_restart(location_id)
		if opening_new_location:
			_reset_operating_progress()
		current_location_id = location_id
		visited_locations[location_id] = true
		notice.emit("Neuer Betriebsstart: %s" % location.title if opening_new_location else "Neuer Standort: %s" % location.title)
		changed.emit()
		save_game()
		return true
	return false


func requires_location_restart(location_id: String) -> bool:
	return location_id != current_location_id and not bool(visited_locations.get(location_id, false))


func _reset_operating_progress() -> void:
	money = 0.0
	upgrades = {"tools": 0, "van": 0, "office": 0}
	employees = {"azubi": 0, "monteur": 0, "meisterin": 0}
	active_contracts.clear()
	job_cooldowns.clear()
	current_streak = 0
	offline_reward = 0.0
	offline_elapsed_seconds = 0.0


func current_location() -> Dictionary:
	for location in GameData.LOCATIONS:
		if location.id == current_location_id:
			return location
	return GameData.LOCATIONS[0]


func daily_mission_progress(mission: Dictionary) -> float:
	return minf(float(daily_progress.get(mission.metric, 0.0)), float(mission.target))


func claim_daily_mission(mission_id: String) -> bool:
	_ensure_daily_state()
	for mission in GameData.DAILY_MISSIONS:
		if mission.id != mission_id:
			continue
		if bool(daily_claimed.get(mission_id, false)):
			return false
		if daily_mission_progress(mission) < float(mission.target):
			notice.emit("Dieses Tagesziel ist noch nicht geschafft.")
			return false
		daily_claimed[mission_id] = true
		money += float(mission.reward)
		lifetime_earnings += float(mission.reward)
		notice.emit("Tagesziel: +%s" % GameData.format_money(float(mission.reward)))
		changed.emit()
		save_game()
		return true
	return false


func achievement_progress(achievement: Dictionary) -> float:
	match str(achievement.metric):
		"jobs": return minf(float(completed_jobs), float(achievement.target))
		"team": return minf(float(total_employees()), float(achievement.target))
		"lifetime": return minf(lifetime_earnings, float(achievement.target))
		"streak": return minf(float(best_streak), float(achievement.target))
		"contracts": return minf(float(active_contracts.size()), float(achievement.target))
		"reputation": return minf(float(reputation), float(achievement.target))
		"major": return minf(float(completed_major_projects), float(achievement.target))
		"rating": return minf(customer_rating, float(achievement.target))
	return 0.0


func claim_achievement(achievement_id: String) -> bool:
	for achievement in GameData.ACHIEVEMENTS:
		if achievement.id != achievement_id:
			continue
		if bool(achievements_claimed.get(achievement_id, false)):
			return false
		if achievement_progress(achievement) < float(achievement.target):
			notice.emit("Erfolg noch nicht freigeschaltet.")
			return false
		achievements_claimed[achievement_id] = true
		money += float(achievement.reward)
		lifetime_earnings += float(achievement.reward)
		notice.emit("Erfolg freigeschaltet: %s" % achievement.title)
		changed.emit()
		save_game()
		return true
	return false


func total_employees() -> int:
	var total := 0
	for value in employees.values():
		total += int(value)
	return total


func team_rank() -> Dictionary:
	var rank: Dictionary = GameData.TEAM_RANKS[0]
	var team_size := total_employees()
	for candidate in GameData.TEAM_RANKS:
		if team_size >= int(candidate.minimum):
			rank = candidate
	return rank


func next_team_rank() -> Dictionary:
	var team_size := total_employees()
	for candidate in GameData.TEAM_RANKS:
		if team_size < int(candidate.minimum):
			return candidate
	return {}


func team_quality_bonus() -> int:
	return int(team_rank().quality_bonus)


func completed_daily_missions() -> int:
	var total := 0
	for mission in GameData.DAILY_MISSIONS:
		if daily_mission_progress(mission) >= float(mission.target):
			total += 1
	return total


func finish_tutorial() -> void:
	tutorial_completed = true
	save_game()


func set_preference(preference: String, enabled: bool) -> void:
	match preference:
		"sound": sound_enabled = enabled
		"haptics": haptics_enabled = enabled
		"reduced_motion": reduced_motion = enabled
		_: return
	changed.emit()
	save_game()


func _ensure_daily_state() -> void:
	var today := Time.get_date_string_from_system()
	if daily_key == today:
		return
	daily_key = today
	daily_progress = {"jobs": 0.0, "earnings": 0.0, "upgrades": 0.0, "streak": 0.0, "quality": 0.0}
	daily_claimed = {"jobs": false, "earnings": false, "invest": false, "streak": false, "quality": false}


func _update_streak() -> void:
	var now := int(Time.get_unix_time_from_system())
	if last_job_completed_unix > 0 and now - last_job_completed_unix <= 5 * 60:
		current_streak += 1
	else:
		current_streak = 1
	best_streak = maxi(best_streak, current_streak)
	last_job_completed_unix = now


func job_duration_multiplier() -> float:
	return maxf(0.42, 1.0 - float(upgrades.van) * 0.12)


func passive_income_per_second() -> float:
	var base := 0.0
	for employee in GameData.EMPLOYEES:
		base += float(employee.income) * int(employees.get(employee.id, 0))
	return base * (1.0 + float(upgrades.office) * 0.25) + contract_income_per_second()


func employee_income_per_second() -> float:
	var base := 0.0
	for employee in GameData.EMPLOYEES:
		base += float(employee.income) * int(employees.get(employee.id, 0))
	return base * (1.0 + float(upgrades.office) * 0.25)


func contract_income_per_second() -> float:
	var income := 0.0
	for contract in GameData.CONTRACTS:
		if bool(active_contracts.get(contract.id, false)):
			income += float(contract.payout) / float(contract.interval)
	return income


func sign_contract(contract_id: String) -> bool:
	for contract in GameData.CONTRACTS:
		if contract.id != contract_id:
			continue
		if bool(active_contracts.get(contract_id, false)):
			return false
		if level < int(contract.level):
			notice.emit("Vertrag ab Betriebsstufe %d verfügbar." % int(contract.level))
			return false
		if reputation < int(contract.reputation):
			notice.emit("Noch %d Reputation bis zum Vertrag." % (int(contract.reputation) - reputation))
			return false
		active_contracts[contract_id] = true
		contract_signed.emit(contract)
		notice.emit("Neuer Stammkunde: %s" % contract.client)
		changed.emit()
		save_game()
		return true
	return false


func reputation_rank() -> Dictionary:
	var rank: Dictionary = GameData.REPUTATION_RANKS[0]
	for candidate in GameData.REPUTATION_RANKS:
		if reputation >= int(candidate.minimum):
			rank = candidate
	return rank


func next_reputation_rank() -> Dictionary:
	for candidate in GameData.REPUTATION_RANKS:
		if reputation < int(candidate.minimum):
			return candidate
	return {}


func _calculate_job_quality(job: Dictionary) -> int:
	var score := 70.0
	score += float(upgrades.tools) * 4.0
	score += float(upgrades.office) * 2.0
	score += float(team_quality_bonus())
	score += float(mini(current_streak, 5)) * 1.5
	score += float(randi_range(-6, 8))
	if active_event_id == "premium_material":
		score += 7.0
	elif active_event_id == "express":
		score -= 4.0
	if bool(job.get("major", false)):
		score -= 5.0
	return int(round(clampf(score, 50.0, 100.0)))


func _create_review(job: Dictionary, quality: int) -> Dictionary:
	var stars := clampi(int(round(float(quality) / 20.0)), 3, 5)
	var group := "excellent" if stars == 5 else ("good" if stars == 4 else "mixed")
	var texts: Array = GameData.REVIEW_TEXTS[group]
	var review := {
		"customer": str(job.customer),
		"job": str(job.title),
		"quality": quality,
		"stars": stars,
		"text": str(texts[randi() % texts.size()]),
	}
	customer_rating = (customer_rating * float(quality_samples) + float(stars)) / float(quality_samples + 1)
	quality_samples += 1
	recent_reviews.push_front(review)
	if recent_reviews.size() > 5:
		recent_reviews.resize(5)
	return review


func company_value() -> float:
	var value := lifetime_earnings + money
	for upgrade in GameData.UPGRADES:
		var owned := int(upgrades.get(upgrade.id, 0))
		for index in range(owned):
			value += GameData.upgrade_cost(upgrade, index)
	for employee in GameData.EMPLOYEES:
		var owned := int(employees.get(employee.id, 0))
		for index in range(owned):
			value += GameData.employee_cost(employee, index)
	return value


func active_job_progress() -> float:
	if active_job_id == "" or active_job_total <= 0.0:
		return 0.0
	return clampf(1.0 - active_job_remaining / active_job_total, 0.0, 1.0)


func job_cooldown_remaining(job_id: String) -> float:
	var available_at := int(job_cooldowns.get(job_id, 0))
	return maxf(0.0, float(available_at - int(Time.get_unix_time_from_system())))


func format_cooldown(seconds: float) -> String:
	var total_seconds := maxi(0, int(ceil(seconds)))
	var hours := int(total_seconds / 3600)
	var minutes := int(total_seconds % 3600 / 60)
	var remaining_seconds := total_seconds % 60
	if hours > 0:
		return "%d Std. %02d Min." % [hours, minutes]
	if minutes > 0:
		return "%d:%02d Min." % [minutes, remaining_seconds]
	return "%d Sek." % remaining_seconds


func claim_offline_reward() -> float:
	var reward := offline_reward
	money += reward
	lifetime_earnings += reward
	offline_reward = 0.0
	offline_elapsed_seconds = 0.0
	changed.emit()
	save_game()
	return reward


func save_game() -> void:
	last_saved_unix = int(Time.get_unix_time_from_system())
	var payload := {
		"version": 6,
		"money": money,
		"lifetime_earnings": lifetime_earnings,
		"level": level,
		"xp": xp,
		"completed_jobs": completed_jobs,
		"current_streak": current_streak,
		"best_streak": best_streak,
		"last_job_completed_unix": last_job_completed_unix,
		"upgrades": upgrades,
		"employees": employees,
		"active_job_id": active_job_id,
		"active_job_remaining": active_job_remaining,
		"active_job_total": active_job_total,
		"job_cooldowns": job_cooldowns,
		"active_event_id": active_event_id,
		"offline_reward": offline_reward,
		"offline_elapsed_seconds": offline_elapsed_seconds,
		"last_saved_unix": last_saved_unix,
		"current_location_id": current_location_id,
		"tutorial_completed": tutorial_completed,
		"daily_key": daily_key,
		"daily_progress": daily_progress,
		"daily_claimed": daily_claimed,
		"achievements_claimed": achievements_claimed,
		"reputation": reputation,
		"active_contracts": active_contracts,
		"visited_locations": visited_locations,
		"customer_rating": customer_rating,
		"quality_samples": quality_samples,
		"last_job_quality": last_job_quality,
		"completed_major_projects": completed_major_projects,
		"recent_reviews": recent_reviews,
		"sound_enabled": sound_enabled,
		"haptics_enabled": haptics_enabled,
		"reduced_motion": reduced_motion,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))


func delete_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path)) == OK


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		last_saved_unix = int(Time.get_unix_time_from_system())
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
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
	current_streak = maxi(0, int(parsed.get("current_streak", 0)))
	best_streak = maxi(current_streak, int(parsed.get("best_streak", 0)))
	last_job_completed_unix = maxi(0, int(parsed.get("last_job_completed_unix", 0)))
	upgrades.merge(parsed.get("upgrades", {}), true)
	employees.merge(parsed.get("employees", {}), true)
	active_job_id = str(parsed.get("active_job_id", ""))
	active_job_remaining = maxf(0.0, float(parsed.get("active_job_remaining", 0.0)))
	active_job_total = maxf(0.0, float(parsed.get("active_job_total", 0.0)))
	job_cooldowns = parsed.get("job_cooldowns", {})
	active_event_id = str(parsed.get("active_event_id", ""))
	offline_reward = maxf(0.0, float(parsed.get("offline_reward", 0.0)))
	offline_elapsed_seconds = maxf(0.0, float(parsed.get("offline_elapsed_seconds", 0.0)))
	if active_job_id == "":
		active_event_id = ""
	last_saved_unix = int(parsed.get("last_saved_unix", Time.get_unix_time_from_system()))
	current_location_id = str(parsed.get("current_location_id", "neighborhood"))
	tutorial_completed = bool(parsed.get("tutorial_completed", false))
	daily_key = str(parsed.get("daily_key", ""))
	daily_progress.merge(parsed.get("daily_progress", {}), true)
	daily_claimed.merge(parsed.get("daily_claimed", {}), true)
	achievements_claimed = parsed.get("achievements_claimed", {})
	reputation = maxi(0, int(parsed.get("reputation", completed_jobs * 4)))
	active_contracts = parsed.get("active_contracts", {})
	visited_locations = parsed.get("visited_locations", {"neighborhood": true})
	visited_locations[current_location_id] = true
	customer_rating = clampf(float(parsed.get("customer_rating", 4.0)), 1.0, 5.0)
	quality_samples = maxi(0, int(parsed.get("quality_samples", 0)))
	last_job_quality = clampi(int(parsed.get("last_job_quality", 0)), 0, 100)
	completed_major_projects = maxi(0, int(parsed.get("completed_major_projects", 0)))
	recent_reviews = parsed.get("recent_reviews", [])
	sound_enabled = bool(parsed.get("sound_enabled", true))
	haptics_enabled = bool(parsed.get("haptics_enabled", true))
	reduced_motion = bool(parsed.get("reduced_motion", false))
	var elapsed := clampf(float(Time.get_unix_time_from_system() - last_saved_unix), 0.0, OFFLINE_CAP_SECONDS)
	if elapsed > 10.0:
		offline_reward += passive_income_per_second() * elapsed * OFFLINE_EFFICIENCY
		offline_elapsed_seconds = minf(OFFLINE_CAP_SECONDS, offline_elapsed_seconds + elapsed)
		if active_job_id != "":
			var remaining_before_offline := active_job_remaining
			active_job_remaining = maxf(0.0, active_job_remaining - elapsed)
			if active_job_remaining <= 0.0:
				complete_active_job(maxf(0.0, elapsed - remaining_before_offline))
