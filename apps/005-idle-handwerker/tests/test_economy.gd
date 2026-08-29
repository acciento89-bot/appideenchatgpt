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
	if GameData.JOBS.size() < 10:
		failures += 1
		printerr("FAIL: phase 3 needs at least ten jobs")
	if GameData.LOCATIONS.size() != 4:
		failures += 1
		printerr("FAIL: expected four progression locations")
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
	game.free()
	if failures == 0:
		print("All economy tests passed.")
	quit(failures)
