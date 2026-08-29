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
	var game := GameState.new()
	game.current_streak = 5
	if not is_equal_approx(game.streak_reward_multiplier(), 1.15):
		failures += 1
		printerr("FAIL: streak reward cap")
	game.current_streak = 12
	if not is_equal_approx(game.streak_reward_multiplier(), 1.15):
		failures += 1
		printerr("FAIL: streak reward must stay capped")
	game.free()
	if failures == 0:
		print("All economy tests passed.")
	quit(failures)
