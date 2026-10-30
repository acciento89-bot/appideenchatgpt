extends SceneTree
# Exercise the actual engine mixer beyond three loop boundaries. The sentinel
# exists only in a diagnostic copy; production PCM must never read that frame.
const Score = preload("res://scripts/workshop_music.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _init() -> void: call_deferred("run")
func mix_frames(stream: AudioStreamWAV, count: int, start: float = 0.0) -> PackedVector2Array:
	var playback := stream.instantiate_playback()
	playback.start(start)
	var result := PackedVector2Array()
	var chunks := [1, 17, 511, 2048, 4095]
	var chunk := 0
	var ratio := AudioServer.get_mix_rate() / float(Score.SAMPLE_RATE)
	var previous := start
	var wraps := 0
	while result.size() < count:
		var requested := mini(chunks[chunk % chunks.size()], count - result.size())
		var frames := playback.mix_audio(ratio, requested)
		if frames.size() != requested:
			check(false, "real loop playback cannot end or return a short mix")
			break
		result.append_array(frames)
		var position := playback.get_playback_position()
		if position < previous: wraps += 1
		previous = position
		chunk += 1
	check(playback.is_playing(), "loop remains active after real mixing")
	playback.stop()
	check(not playback.is_playing(), "explicit stop ends the playback instance")
	playback.start()
	var restarted := playback.mix_audio(ratio, 128)
	if start == 0.0 and result.size() >= 128:
		check(restarted == result.slice(0, 128), "explicit restart reproduces the initial PCM rather than stale loop data")
	playback.stop()
	print("WORKSHOP REAL MIX frames=", result.size(), ", wraps=", wraps, ", chunkCalls=", chunk, ", start=", start)
	return result
func run() -> void:
	var pcm: PackedByteArray = Score.generate_pcm()
	var stream: AudioStreamWAV = Score.create_loop()
	check(pcm.size() == 882000 and stream.data == pcm, "actual stream retains all original 441000 mono16 frames without extra padding")
	check(stream.loop_begin == 0 and stream.loop_end >= 0 and stream.loop_end < pcm.size() / 2,
		"inclusive loop endpoint names a valid original sample")
	var count := 441000 * 3 + 1037
	var actual := mix_frames(stream, count)
	var guarded: AudioStreamWAV = stream.duplicate()
	var sentinel := pcm.duplicate()
	sentinel.append(255); sentinel.append(127) # Int16 max immediately after original PCM.
	guarded.data = sentinel
	var with_sentinel := mix_frames(guarded, count)
	check(actual.size() == count and with_sentinel.size() == count, "real mixer spans more than three complete original loop durations")
	check(actual == with_sentinel, "real mixer never consumes the diagnostic sample after original PCM")
	var peak := 0.0
	var jump := 0.0
	var finite := true
	var previous := 0.0
	for frame in actual:
		finite = finite and is_finite(frame.x) and is_finite(frame.y) and frame.x == frame.y
		peak = maxf(peak, absf(frame.x))
		jump = maxf(jump, absf(frame.x - previous))
		previous = frame.x
	check(finite and peak > .02 and peak < .6, "all mixed stereo frames remain finite, mono-equal and audibly nonzero with headroom")
	check(jump < 3000.0 / 32767.0, "real repeated loop has no abrupt sample jump")
	# The mixer wraps at the inclusive final index. The original20s PCM is
	# unchanged; steady-state period is440999frames (one silent frame shorter).
	var periodic := actual.size() >= count
	if actual.size() >= count:
		for index in range(441100, 881900):
			if actual[index] != actual[index + 440999]:
				periodic = false
				break
	check(periodic, "real second and third loops repeat with the valid 440999-frame period")
	var near_end := mix_frames(guarded, 22050, 19.999)
	var seek_safe := near_end.size() == 22050
	for frame in near_end:
		seek_safe = seek_safe and is_finite(frame.x) and absf(frame.x) < .6
	check(seek_safe, "starting just before the seam wraps safely without reading the sentinel")
	var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(pcm)
	print("WORKSHOP REAL PCM bytes=", pcm.size(), ", host_sha256=", hash.finish().hex_encode(), ", dataSeconds=", stream.get_length(), ", expectedSteadyPeriodFrames=440999, periodicMatch=", periodic, ", expectedPeriodSeconds=", 440999.0 / 22050.0)
	print("WORKSHOP LOOP MIXER checks=", checks, ", failures=", failures, ", peak=", peak, ", maxStep=", jump)
	if failures == 0: print("WORKSHOP LOOP MIXER PASS")
	quit(1 if failures else 0)
