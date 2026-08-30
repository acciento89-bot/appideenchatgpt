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
	if GameData.JOBS.size() < 14:
		failures += 1
		printerr("FAIL: phase 6 needs fourteen jobs")
	if GameData.LOCATIONS.size() != 4:
		failures += 1
		printerr("FAIL: expected four progression locations")
	if GameData.JOB_EVENTS.size() < 3:
		failures += 1
		printerr("FAIL: expected varied bonus events")
	if GameData.CONTRACTS.size() != 4 or GameData.REPUTATION_RANKS.size() < 5:
		failures += 1
		printerr("FAIL: contract and reputation progression data")
	var game := GameState.new()
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
	if not game.select_location("industrial_park"):
		failures += 1
		printerr("FAIL: unlocked location should be selectable")
	if not is_equal_approx(game.location_reward_multiplier(), 1.55):
		failures += 1
		printerr("FAIL: industrial location reward multiplier")
	game.daily_key = Time.get_date_string_from_system()
	game.daily_progress.jobs = 3.0
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
	game.free()
	if failures == 0:
		print("All economy tests passed.")
	quit(failures)
