extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var path := "res://scripts/workshop_music.gd"
	check(FileAccess.file_exists(path), "original workshop score implementation exists")
	if not FileAccess.file_exists(path):
		quit(1)
		return
	var score = load(path)
	var generated_at := Time.get_ticks_usec()
	var pcm: PackedByteArray = score.generate_pcm()
	var generation_ms := float(Time.get_ticks_usec() - generated_at) / 1000.0
	check(pcm.size() == 22050 * 20 * 2 and pcm.size() < 1024 * 1024, "20 second mono score stays below1MiB")
	check(pcm == score.generate_pcm(), "original procedural score is deterministic")
	var peak := 0
	var jump := 0
	var energy := 0.0
	var previous := 0
	for offset in range(0, pcm.size(), 2):
		var sample := pcm.decode_s16(offset)
		peak = maxi(peak, absi(sample))
		jump = maxi(jump, absi(sample - previous))
		energy += float(sample) * float(sample)
		previous = sample
	check(peak > 1000 and peak < 19660, "real nonclipping score has conservative headroom")
	check(sqrt(energy / float(pcm.size() / 2)) > 200.0, "score contains audible-scale signal rather than silence")
	check(pcm.decode_s16(0) == 0 and pcm.decode_s16(pcm.size() - 2) == 0 and jump < 3000, "loop seam is zero and no hard per-note sample jumps")
	var loop: AudioStreamWAV = score.create_loop()
	check(loop.data == pcm and loop.format == AudioStreamWAV.FORMAT_16_BITS and loop.mix_rate == 22050 and not loop.stereo, "WAV uses exact generated mono PCM")
	check(loop.loop_mode == AudioStreamWAV.LOOP_FORWARD and loop.loop_begin == 0 and loop.loop_end == 22050 * 20 and is_equal_approx(loop.get_length(), 20.0), "actual WAV loops over the complete valid sample interval")
	check(loop == score.create_loop(), "cached loop is reused without repeated synthesis")
	var music = score.new()
	root.add_child(music)
	var player: AudioStreamPlayer = music.get("_player")
	check(player != null and not player.playing, "construction cannot play before loaded preference is applied")
	music.set_enabled(true)
	await create_timer(0.15).timeout
	check(player.playing and not player.stream_paused and player.volume_db < -10.0, "enabled music uses quiet separate real player")
	var position := player.get_playback_position()
	music.set_enabled(true)
	await create_timer(0.04).timeout
	check(player.get_playback_position() >= position, "repeated enable does not restart playback")
	music.set_enabled(false)
	await create_timer(0.12).timeout
	check(player.stream_paused, "music-off fades then pauses player")
	music.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(player.stream_paused, "resume cannot re-enable an off preference")
	music.set_enabled(true)
	await create_timer(0.03).timeout
	music.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(player.stream_paused, "focus loss suspends immediately")
	music.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	music.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(player.stream_paused, "resume while unfocused cannot start music")
	music.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await create_timer(0.12).timeout
	check(player.playing and not player.stream_paused, "foreground restores only enabled music")
	for i in range(12):
		music.set_enabled(false)
		music.set_enabled(true)
	await create_timer(0.12).timeout
	check(music.get_child_count() == 1 and player.playing and not player.stream_paused, "rapid toggles never layer players or leave stale fade callbacks")
	music.set_enabled(false)
	music.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	music.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	music.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(player.stream_paused, "music remains off across complete background cycle")
	root.remove_child(music)
	check(not player.playing, "tree exit stops playback and transition")
	check(player.stream == null and not player.stream_paused, "tree exit releases a previously paused playback resource")
	music.free()
	await create_timer(0.06).timeout # AudioServer releases stopped playback on its mix tick.
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256); hash.update(pcm)
	print("WORKSHOP PCM bytes=", pcm.size(), ", first_generation_ms=", generation_ms, ", host_sha256=", hash.finish().hex_encode())
	print("WORKSHOP MUSIC ", checks, " checks, failures=", failures, ", peak=", peak, ", max_step=", jump)
	quit(1 if failures else 0)
