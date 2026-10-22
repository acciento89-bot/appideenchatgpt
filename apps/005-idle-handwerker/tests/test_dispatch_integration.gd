extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value)); file.close()
func _init() -> void:
	var path := "user://dispatch-integration-%d.json" % OS.get_process_id()
	var legacy := {"version": 8, "money": 1234.0, "employees": {"azubi": 1, "monteur": 1, "meisterin": 1}, "level": 10, "no_ads": true, "bonus_tokens": 27, "processed_transactions": {"historical-transaction": true}, "last_saved_unix": int(Time.get_unix_time_from_system())}
	write_json(path, legacy)
	var game = GameState.new()
	game.save_path = path
	game.load_game()
	check(game.money == 1234.0 and game.dispatch_board.tasks.is_empty(), "old v8 save initializes empty board and preserves balance")
	check(game.no_ads and game.bonus_tokens == 27 and game.has_processed_purchase("historical-transaction"), "migration retains existing entitlement/token/transaction fields")
	var passive: float = game.passive_income_per_second()
	var xp_before: int = game.xp
	check(game.dispatch_assign("armaturen", "azubi", "normal"), "integrated assignment persisted")
	check(game.passive_income_per_second() == passive and game.active_job_id == "", "board leaves passive and manual job untouched")
	check(game.dispatch_available("azubi") == 0, "assigned staff unit unavailable")
	var id: String = game.dispatch_board.tasks[0].id
	game.dispatch_board.advance(120.0)
	check(game.dispatch_collect(id), "explicit integrated collection succeeds")
	check(is_equal_approx(game.money, 1262.0) and game.xp == xp_before and game.completed_jobs == 0, "bonus only changes money and lifetime earnings; not original job counters")
	check(not game.dispatch_collect(id) and is_equal_approx(game.money, 1262.0), "repeated collection cannot pay twice")
	var reloaded = GameState.new()
	reloaded.save_path = path; reloaded.load_game()
	check(is_equal_approx(reloaded.money, 1262.0) and reloaded.dispatch_board.tasks.is_empty(), "relaunch preserves reward and removes claimed task together")
	check(reloaded.dispatch_board.history.size() == 1, "relaunch preserves completion receipt")
	check(game.dispatch_assign("armaturen", "azubi", "normal"), "second task assigned")
	check(not game.select_location("downtown"), "location reset cannot abandon running team task")
	game.level = 30; game.lifetime_earnings = 1.0e7
	check(not game.can_prestige(), "prestige blocked until outstanding team tasks collected")
	game.dispatch_board.advance(120.0)
	var failed_id: String = game.dispatch_board.tasks[0].id
	var before_money: float = game.money
	var before_board: Dictionary = game.dispatch_board.to_payload()
	var before_bytes := FileAccess.get_file_as_bytes(path)
	# An existing directory cannot be replaced by an archive file; no filesystem permissions hack needed.
	var blocked := "user://dispatch-blocked-%d" % OS.get_process_id()
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked))
	game.save_path = blocked
	check(not game.dispatch_collect(failed_id), "failed durable save reports no collection")
	check(game.money == before_money and game.dispatch_board.to_payload() == before_board, "failed collection rolls back both balance and board")
	check(FileAccess.get_file_as_bytes(path) == before_bytes, "failed alternate destination preserves original save bytes")
	check(not game.dispatch_specialize("azubi", "heizung"), "failed preference save rejected")
	check(game.dispatch_board.to_payload() == before_board, "failed preference save rolls back")
	game.save_path = path
	check(game.dispatch_collect(failed_id), "task still collectible after storage recovered")
	var corrupt_bytes := "{broken-save".to_utf8_buffer()
	var file := FileAccess.open(path, FileAccess.WRITE); file.store_buffer(corrupt_bytes); file.close()
	var corrupt = GameState.new(); corrupt.save_path = path; corrupt.load_game()
	check(not corrupt.save_game() and FileAccess.get_file_as_bytes(path) == corrupt_bytes, "corrupt existing save cannot be silently overwritten")
	var future := legacy.duplicate(true); future.version = 999
	write_json(path, future)
	var future_bytes := FileAccess.get_file_as_bytes(path)
	var newer = GameState.new(); newer.save_path = path; newer.load_game()
	check(not newer.save_game() and FileAccess.get_file_as_bytes(path) == future_bytes, "future save is preserved")
	var invalid := legacy.duplicate(true); invalid.dispatch_board = {"schema_version": 2}
	write_json(path, invalid)
	var invalid_bytes := FileAccess.get_file_as_bytes(path)
	var badboard = GameState.new(); badboard.save_path = path; badboard.load_game()
	check(not badboard.save_game() and FileAccess.get_file_as_bytes(path) == invalid_bytes, "invalid present board blocks entire save without losing purchases/balance")
	for state in [game, reloaded, corrupt, newer, badboard]: state.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked))
	if failures == 0: print("ALL IDLE DISPATCH INTEGRATION TESTS PASSED: %d checks" % checks)
	quit(1 if failures else 0)
