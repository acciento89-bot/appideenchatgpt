extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var result := find_button(child, prefix)
		if result != null: return result
	return null
func _init() -> void: call_deferred("run")
func run() -> void:
	check(OS.get_user_data_dir().contains("CodexIdleWorkshopMusicSourceTests"), "real-profile isolation active for source UI test")
	if failures:
		quit(1)
		return
	var scene: PackedScene = load("res://main.tscn")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	var game: GameState = app.get("game")
	check(game != null, "main scene script initializes with retained imports")
	if game == null:
		app.queue_free()
		quit(1)
		return
	check(app.get("monetization") != null and app.get("settings_button") != null, "full actual main initialization completed")
	if app.get("monetization") == null or app.get("settings_button") == null:
		app.queue_free()
		quit(1)
		return
	game.set_process(false)
	var path := "user://music-ui-%d.json" % OS.get_process_id()
	game.save_path = path
	game.set_preference("music", true)
	app.call("_show_settings")
	await process_frame
	var button: Button = app.find_child("MusicPreference", true, false)
	var music = app.get("music")
	check(button != null and music != null, "actual settings exposes independent music control/player")
	if button == null or music == null:
		app.queue_free()
		await process_frame
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		quit(1)
		return
	if button != null and music != null:
		var sound_before := game.sound_enabled
		var haptic_before := game.haptics_enabled
		check(button.text == "MUSIK\nAN", "actual music button reflects loaded preference")
		button.pressed.emit()
		await create_timer(0.12).timeout
		check(not game.music_enabled and not music.enabled and button.text == "MUSIK\nAUS", "real music action updates saved state and player")
		check(game.sound_enabled == sound_before and game.haptics_enabled == haptic_before, "music control preserves original Sound and Haptik")
		var sound := find_button(app, "SOUND\n")
		check(sound != null, "original Sound action retained")
		if sound:
			sound.pressed.emit()
			check(game.sound_enabled != sound_before and not game.music_enabled and not music.enabled, "actual Sound action still independent of music")
		button.pressed.emit()
		await create_timer(0.12).timeout
		var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(game.music_enabled and music.enabled and disk.music_enabled and button.text == "MUSIK\nAN", "actual music-on action is durable")
		var music_player: AudioStreamPlayer = music.get("_player")
		music.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		check(music_player.stream_paused, "actual active application music suspends")
		music.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		await create_timer(0.12).timeout
		check(not music_player.stream_paused, "actual active application music resumes")
		game.save_path = "user://missing-music-ui-parent-%d/save.json" % OS.get_process_id()
		button.pressed.emit()
		check(game.music_enabled and music.enabled and button.text == "MUSIK\nAN", "failed preference save rolls music state/player/control back together")
		game.save_path = path
	game.set_preference("music", false)
	var default_profile := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	default_profile.store_buffer(FileAccess.get_file_as_bytes(path)); default_profile.close()
	app.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	var cold := scene.instantiate()
	root.add_child(cold)
	await process_frame
	var cold_game: GameState = cold.get("game")
	cold_game.set_process(false)
	var cold_music = cold.get("music")
	var cold_player: AudioStreamPlayer = cold_music.get("_player")
	check(not cold_game.music_enabled and not cold_music.enabled and not cold_player.playing, "cold actual main loads music-off before creating playback")
	cold.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MUSIC SETTINGS ", checks, " checks, failures=", failures)
	quit(1 if failures else 0)
