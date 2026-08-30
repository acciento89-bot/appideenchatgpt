extends SceneTree


func _init() -> void:
	var failures := 0
	if GameData.upgrade_cost(GameData.UPGRADES[0], 0) != 180.0:
		failures += 1
		printerr("FAIL: first tool upgrade cost")
	if GameData.upgrade_cost(GameData.UPGRADES[0], 1) <= 180.0:
		failures += 1
		printerr("FAIL: upgrade cost must grow")
	if GameData.employee_cost(GameData.EMPLOYEES[0], 1) <= 350.0:
		failures += 1
		printerr("FAIL: employee cost must grow")
	if GameData.xp_for_level(2) <= GameData.xp_for_level(1):
		failures += 1
		printerr("FAIL: XP requirement must grow")
	if GameData.format_money(1234.5, true) != "1.234,50 €":
		failures += 1
		printerr("FAIL: German money formatting")
	if GameData.JOBS.size() < 23:
		failures += 1
		printerr("FAIL: long-form progression needs at least 23 jobs")
	if GameData.DAILY_MISSIONS.size() < 7 or GameData.ACHIEVEMENTS.size() < 33:
		failures += 1
		printerr("FAIL: extended daily and long-term goal progression")
	if GameData.LOCATIONS.size() < 8:
		failures += 1
		printerr("FAIL: expected eight progression locations")
	if GameData.JOB_EVENTS.size() < 3:
		failures += 1
		printerr("FAIL: expected varied bonus events")
	if GameData.CONTRACTS.size() != 4 or GameData.REPUTATION_RANKS.size() < 5:
		failures += 1
		printerr("FAIL: contract and reputation progression data")
	var expected_employee_titles := ["Azubi", "Monteur", "Meisterin"]
	for index in GameData.EMPLOYEES.size():
		if str(GameData.EMPLOYEES[index].title) != expected_employee_titles[index]:
			failures += 1
			printerr("FAIL: employee roles must not use repeated personal names")
	for employee in GameData.EMPLOYEES:
		var payback_seconds := float(employee.base_cost) / float(employee.income)
		if payback_seconds < 3600.0:
			failures += 1
			printerr("FAIL: employee '%s' pays for itself in under one hour" % employee.id)
	for job in GameData.JOBS:
		if float(job.get("cooldown", 0.0)) <= float(job.duration):
			failures += 1
			printerr("FAIL: job '%s' needs a meaningful replay cooldown" % job.id)
	if not is_equal_approx(GameState.OFFLINE_EFFICIENCY, 0.35):
		failures += 1
		printerr("FAIL: offline income must use the balanced efficiency factor")
	if GameState.BASE_REWARD_SCALE >= 0.75:
		failures += 1
		printerr("FAIL: active rewards must use the slower Build 8 economy")
	var game := GameState.new()
	game.save_path = "user://idle_handwerker_test_save.json"
	if str(game.team_rank().code) != "T1" or game.team_quality_bonus() != 0:
		failures += 1
		printerr("FAIL: empty company team rank")
	game.employees.azubi = 3
	if str(game.team_rank().code) != "T3" or game.team_quality_bonus() != 2:
		failures += 1
		printerr("FAIL: team rank and quality progression")
	if int(game.next_team_rank().minimum) != 6:
		failures += 1
		printerr("FAIL: next team milestone")
	game.employees.azubi = 0
	game.job_cooldowns.tap = int(Time.get_unix_time_from_system()) + 60
	if game.start_job("tap") or game.job_cooldown_remaining("tap") <= 0.0:
		failures += 1
		printerr("FAIL: cooling down jobs must not be repeatable")
	game.job_cooldowns.tap = int(Time.get_unix_time_from_system()) - 1
	if not game.start_job("tap"):
		failures += 1
		printerr("FAIL: elapsed job cooldown should unlock the job")
	game.complete_active_job()
	if game.job_cooldown_remaining("tap") <= 0.0:
		failures += 1
		printerr("FAIL: completing a job must start its replay cooldown")
	game.job_cooldowns.clear()
	if not game.start_job("tap"):
		failures += 1
		printerr("FAIL: job should restart after cooldown test cleanup")
	game.complete_active_job(120.0)
	if game.job_cooldown_remaining("tap") > 0.0:
		failures += 1
		printerr("FAIL: offline time after completion must consume the replay cooldown")
	game.job_cooldowns.clear()
	game.current_streak = 5
	if not is_equal_approx(game.streak_reward_multiplier(), 1.15):
		failures += 1
		printerr("FAIL: streak reward cap")
	game.current_streak = 12
	if not is_equal_approx(game.streak_reward_multiplier(), 1.15):
		failures += 1
		printerr("FAIL: streak reward must stay capped")
	game.level = 1
	if game.select_location("industrial_park"):
		failures += 1
		printerr("FAIL: locked location must not be selectable")
	game.level = 12
	game.money = 999.0
	game.upgrades.tools = 2
	game.employees.azubi = 2
	game.active_contracts.property_service = true
	if not game.select_location("industrial_park"):
		failures += 1
		printerr("FAIL: unlocked location should be selectable")
	if game.money != 0.0 or int(game.upgrades.tools) != 0 or int(game.employees.azubi) != 0 or not game.active_contracts.is_empty():
		failures += 1
		printerr("FAIL: first opening of a new location must reset operating progress")
	if game.level != 12 or not bool(game.visited_locations.get("industrial_park", false)):
		failures += 1
		printerr("FAIL: location restart must preserve career progress and remember the opening")
	game.money = 321.0
	if not game.select_location("neighborhood") or not is_equal_approx(game.money, 321.0):
		failures += 1
		printerr("FAIL: revisiting an opened location must not reset progress")
	game.current_location_id = "industrial_park"
	if not is_equal_approx(game.location_reward_multiplier(), 1.55):
		failures += 1
		printerr("FAIL: industrial location reward multiplier")
	game.level = GameState.PRESTIGE_LEVEL
	game.lifetime_earnings = GameState.PRESTIGE_VALUE
	game.money = GameState.PRESTIGE_VALUE
	if not game.can_prestige() or not game.perform_prestige():
		failures += 1
		printerr("FAIL: eligible company must earn a Meisterbrief")
	if game.mastery_points < 1 or game.prestige_count != 1 or game.level != 1:
		failures += 1
		printerr("FAIL: prestige reset and permanent mastery progression")
	if not game.apply_purchase("de.kamilunavo.idlehandwerker.tokens.small", "tx-test-1"):
		failures += 1
		printerr("FAIL: consumable purchase credit")
	var tokens_after_purchase := game.bonus_tokens
	if game.apply_purchase("de.kamilunavo.idlehandwerker.tokens.small", "tx-test-1") or game.bonus_tokens != tokens_after_purchase:
		failures += 1
		printerr("FAIL: duplicate StoreKit transaction protection")
	game.daily_key = Time.get_date_string_from_system()
	game.daily_progress.jobs = 5.0
	var money_before := game.money
	if not game.claim_daily_mission("jobs") or game.money <= money_before:
		failures += 1
		printerr("FAIL: completed daily mission reward")
	game.active_event_id = "premium_material"
	if not is_equal_approx(game.active_event_reward_multiplier(), 1.55):
		failures += 1
		printerr("FAIL: premium material event reward")
	if game.active_event_duration_multiplier() <= 1.0:
		failures += 1
		printerr("FAIL: premium material event duration tradeoff")
	if game.company_value() < game.money:
		failures += 1
		printerr("FAIL: company value should include liquid funds")
	game.level = 3
	game.reputation = 34
	if game.sign_contract("property_service"):
		failures += 1
		printerr("FAIL: contract must respect reputation gate")
	game.reputation = 35
	if not game.sign_contract("property_service"):
		failures += 1
		printerr("FAIL: eligible contract should be signed")
	if game.contract_income_per_second() <= 0.0:
		failures += 1
		printerr("FAIL: active contract passive income")
	game.reputation = 160
	if str(game.reputation_rank().code) != "R3":
		failures += 1
		printerr("FAIL: reputation rank progression")
	var major_job := game.get_job("school_heating")
	game.level = 8
	game.current_location_id = "downtown"
	game.reputation = 219
	if game.start_job("school_heating"):
		failures += 1
		printerr("FAIL: major project reputation gate")
	game.reputation = 220
	if not game.start_job("school_heating"):
		failures += 1
		printerr("FAIL: eligible major project should start")
	var quality := game._calculate_job_quality(major_job)
	if quality < 50 or quality > 100:
		failures += 1
		printerr("FAIL: quality must stay within bounds")
	var review := game._create_review(major_job, 95)
	if int(review.stars) != 5 or game.recent_reviews.is_empty():
		failures += 1
		printerr("FAIL: excellent work should create five-star review")
	game.set_preference("sound", false)
	game.set_preference("haptics", false)
	game.set_preference("reduced_motion", true)
	if game.sound_enabled or game.haptics_enabled or not game.reduced_motion:
		failures += 1
		printerr("FAIL: accessibility preferences should persist in state")
	var before_offline_claim := game.money
	game.offline_reward = 125.0
	game.offline_elapsed_seconds = 3600.0
	if not is_equal_approx(game.claim_offline_reward(), 125.0) or not is_equal_approx(game.money, before_offline_claim + 125.0):
		failures += 1
		printerr("FAIL: offline earnings must be credited only when claimed")
	if game.offline_reward != 0.0 or game.offline_elapsed_seconds != 0.0:
		failures += 1
		printerr("FAIL: claimed offline earnings must clear pending state")
	game.money = 4321.0
	game.save_game()
	game.money = 0.0
	game.load_game()
	if not is_equal_approx(game.money, 4321.0):
		failures += 1
		printerr("FAIL: explicit lifecycle save must restore progress")
	if not game.delete_save() or FileAccess.file_exists(game.save_path):
		failures += 1
		printerr("FAIL: confirmed reset must delete the local save")
	game.free()
	if failures == 0:
		print("All economy tests passed.")
	quit(failures)
