extends SceneTree
func _init() -> void:
	var path := "user://dispatch-contract-%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 9, "money": 1234.0, "processed_transactions": {"retain-only-synthetic": true}, "last_saved_unix": int(Time.get_unix_time_from_system())}))
	file.close()
	var original := FileAccess.get_file_as_bytes(path)
	var game = GameState.new()
	game.save_path = path
	game.load_game()
	var rejected: bool = not game.save_game()
	var retained := FileAccess.get_file_as_bytes(path) == original
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not rejected or not retained:
		printerr("FAIL: version9 missing required board must reject load/save and retain exact bytes")
		quit(1)
	else:
		print("ALL IDLE REQUIRED-BOARD ARCHIVE CHECKS PASSED")
		quit(0)
