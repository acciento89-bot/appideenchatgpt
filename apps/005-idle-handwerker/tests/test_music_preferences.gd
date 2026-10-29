extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload)); file.close()
func _init() -> void:
	var path := "user://music-preferences-%d.json" % OS.get_process_id()
	var seed = GameState.new(); seed.save_path = path
	seed.money = 1234.0; seed.level = 10; seed.employees = {"azubi": 1, "monteur": 1, "meisterin": 1}
	seed.no_ads = true; seed.starter_pack_claimed = true; seed.bonus_tokens = 27
	seed.processed_transactions = {"historical-purchase": true}
	seed.sound_enabled = false; seed.haptics_enabled = false
	seed.active_job_id = "test-held-job"; seed.active_job_remaining = 30.0; seed.active_job_total = 60.0
	seed.dispatch_board.assign("armaturen", "azubi", "normal", seed.employees, seed.level)
	check(seed.save_game(), "v9 profile fixture uses real atomic serializer")
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	original.erase("music_enabled"); write_json(path, original)
	var game = GameState.new(); game.save_path = path; game.load_game()
	check(game.get("music_enabled") == true, "legacy v9 profile defaults music on independently of Sound off")
	var board_before: Dictionary = JSON.parse_string(JSON.stringify(game.dispatch_board.to_payload()))
	game.set_preference("music", false)
	check(game.get("music_enabled") == false and not game.sound_enabled and not game.haptics_enabled, "music-only preference preserves Sound and Haptik")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(saved.get("music_enabled") == false and saved.version == 9, "new preference persists without save-version migration")
	for key in original:
		if key not in ["last_saved_unix", "dispatch_board"]:
			check(saved[key] == original[key], "music preference preserves existing field " + key)
	check(saved.dispatch_board == board_before, "music toggle cannot advance or rewrite loaded dispatch tasks")
	var reloaded = GameState.new(); reloaded.save_path = path; reloaded.load_game()
	check(reloaded.get("music_enabled") == false and reloaded.no_ads and reloaded.starter_pack_claimed and reloaded.bonus_tokens == 27 and reloaded.has_processed_purchase("historical-purchase"), "music-off cold reload retains entitlements and purchase deduplication")
	reloaded.set_preference("sound", true)
	check(reloaded.get("music_enabled") == false and reloaded.sound_enabled and not reloaded.haptics_enabled, "Sound on never enables music or Haptik")
	reloaded.set_preference("music", true)
	var on = GameState.new(); on.save_path = path; on.load_game()
	check(on.get("music_enabled") == true and on.sound_enabled and not on.haptics_enabled, "music-on also persists independently")
	var old := original.duplicate(true); old.version = 8; old.erase("dispatch_board")
	write_json(path, old)
	var v8 = GameState.new(); v8.save_path = path; v8.load_game()
	check(v8.get("music_enabled") == true and v8.money == 1234.0 and v8.dispatch_board.tasks.is_empty() and v8.no_ads, "old v8 default preserves existing migration and account")
	var future := original.duplicate(true); future.version = 999
	write_json(path, future); var frozen := FileAccess.get_file_as_bytes(path)
	var blocked = GameState.new(); blocked.save_path = path; blocked.load_game(); blocked.set_preference("music", false)
	check(FileAccess.get_file_as_bytes(path) == frozen and not blocked.save_game() and blocked.music_enabled, "music toggle cannot overwrite a future save")
	for state in [seed,game,reloaded,on,v8,blocked]: state.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MUSIC PREFERENCES ", checks, " checks, failures=", failures)
	quit(1 if failures else 0)
