extends Node

# Procedural Audio Manager for ORBITAL: The Last Engineer
# Generates synthetic WAV streams at runtime to avoid missing external asset dependencies.

var _sfx_players: Array[AudioStreamPlayer] = []
var _ambient_player: AudioStreamPlayer
var _alarm_player: AudioStreamPlayer
var _sound_cache: Dictionary = {}
var master_volume: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_pregenerate_sounds()

func _setup_audio_players() -> void:
	# Pool of SFX players
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)
	
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	add_child(_ambient_player)
	
	_alarm_player = AudioStreamPlayer.new()
	_alarm_player.bus = "Master"
	add_child(_alarm_player)

func set_volume(linear: float) -> void:
	master_volume = clampf(linear, 0.0, 1.0)
	var db := linear_to_db(master_volume) if master_volume > 0.001 else -80.0
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, db)

func get_volume() -> float:
	return master_volume

func play_sfx(sound_name: String, pitch_scale: float = 1.0) -> void:
	if not _sound_cache.has(sound_name):
		return
	var stream: AudioStreamWAV = _sound_cache[sound_name]
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return
	# If all busy, steal the first player
	var fallback: AudioStreamPlayer = _sfx_players[0]
	fallback.stop()
	fallback.stream = stream
	fallback.pitch_scale = pitch_scale
	fallback.play()

func play_ambient(sound_name: String) -> void:
	if not _sound_cache.has(sound_name):
		return
	var stream: AudioStreamWAV = _sound_cache[sound_name]
	if _ambient_player.stream != stream or not _ambient_player.playing:
		_ambient_player.stream = stream
		_ambient_player.play()

func _exit_tree() -> void:
	stop_all()
	for p in _sfx_players:
		if is_instance_valid(p):
			p.stream = null
	if is_instance_valid(_ambient_player):
		_ambient_player.stream = null
	if is_instance_valid(_alarm_player):
		_alarm_player.stream = null
	_sound_cache.clear()

func stop_ambient() -> void:
	if is_instance_valid(_ambient_player):
		if _ambient_player.playing:
			_ambient_player.stop()
		_ambient_player.stream = null

func play_alarm_loop(sound_name: String = "alarm") -> void:
	if not _sound_cache.has(sound_name):
		return
	var stream: AudioStreamWAV = _sound_cache[sound_name]
	if is_instance_valid(_alarm_player) and not _alarm_player.playing:
		_alarm_player.stream = stream
		_alarm_player.play()

func stop_alarm() -> void:
	if is_instance_valid(_alarm_player):
		if _alarm_player.playing:
			_alarm_player.stop()
		_alarm_player.stream = null

func stop_all() -> void:
	stop_ambient()
	stop_alarm()
	for p in _sfx_players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null

func _pregenerate_sounds() -> void:
	_sound_cache["click"] = _generate_click()
	_sound_cache["alarm"] = _generate_alarm(true)
	_sound_cache["alarm_single"] = _generate_alarm(false)
	_sound_cache["repair"] = _generate_chime()
	_sound_cache["pickup"] = _generate_pickup()
	_sound_cache["door"] = _generate_door()
	_sound_cache["denied"] = _generate_denied()
	_sound_cache["generator_hum"] = _generate_hum()
	_sound_cache["victory"] = _generate_fanfare()
	_sound_cache["gas_hiss"] = _generate_hiss()
	_sound_cache["steam_vent"] = _generate_steam()
	_sound_cache["toxic_alarm"] = _generate_toxic_alarm()
	_sound_cache["cough_gasp"] = _generate_cough_gasp()
	_sound_cache["decomp_ring"] = _generate_decomp_ring()
	_sound_cache["scanner_scan"] = _generate_scanner_scan()
	_sound_cache["multitool_weld"] = _generate_multitool_weld()
	_sound_cache["multitool_ratchet"] = _generate_multitool_ratchet()
	_sound_cache["locker_open"] = _generate_locker_open()
	_sound_cache["recharge"] = _generate_recharge()
	_sound_cache["datapad_decrypt"] = _generate_datapad_decrypt()
	_sound_cache["revelation_chime"] = _generate_revelation_chime()
	_sound_cache["creature_sound"] = _generate_creature_sound()
	_sound_cache["creature_roar"] = _generate_creature_roar()
	_sound_cache["crisis_alarm"] = _generate_crisis_alarm()

func play_datapad_decrypt() -> void:
	play_sfx("datapad_decrypt")

func play_revelation_chime() -> void:
	play_sfx("revelation_chime")

func play_creature_sound() -> void:
	play_sfx("creature_sound")

func play_creature_roar() -> void:
	play_sfx("creature_roar")

func play_crisis_alarm() -> void:
	play_sfx("crisis_alarm")

func _generate_click() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.06
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 90.0)
		var val := sin(2.0 * PI * 1800.0 * t) * env * 0.8
		val += (randf() * 2.0 - 1.0) * env * 0.4
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_alarm(is_looping: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.8
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var freq := 880.0 if fmod(t, 0.4) < 0.2 else 660.0
		var tone := sin(2.0 * PI * freq * t)
		var sample := int(tone * 0.6 * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if is_looping else AudioStreamWAV.LOOP_DISABLED
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = data
	return wav

func _generate_chime() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.4
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 8.0)
		var f := 523.25 if t < 0.12 else (659.25 if t < 0.24 else 783.99)
		var val := sin(2.0 * PI * f * t) * env * 0.7
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_pickup() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.2
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 15.0)
		var freq := 880.0 + (t * 2000.0)
		var val := sin(2.0 * PI * freq * t) * env * 0.6
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_door() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.5
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * (t / duration))
		var noise := (randf() * 2.0 - 1.0) * 0.4
		var low_drone := sin(2.0 * PI * 120.0 * t) * 0.4
		var val := (noise + low_drone) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_denied() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.25
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 10.0)
		var val := (1.0 if sin(2.0 * PI * 130.0 * t) > 0.0 else -1.0) * env * 0.5
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_hum() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 1.0
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var f1 := sin(2.0 * PI * 60.0 * t) * 0.4
		var f2 := sin(2.0 * PI * 120.0 * t) * 0.2
		var noise := (randf() * 2.0 - 1.0) * 0.05
		var val := f1 + f2 + noise
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = data
	return wav

func _generate_fanfare() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 1.2
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 2.5)
		var chord := sin(2.0 * PI * 523.25 * t) * 0.3 + sin(2.0 * PI * 659.25 * t) * 0.3 + sin(2.0 * PI * 783.99 * t) * 0.3
		var val := chord * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_hiss() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.7
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * (t / duration))
		var noise := (randf() * 2.0 - 1.0) * 0.45
		var high_tone := sin(2.0 * PI * 2400.0 * t) * 0.15
		var val := (noise + high_tone) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_steam() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.55
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 6.5)
		var noise := (randf() * 2.0 - 1.0) * 0.55
		var hiss := sin(2.0 * PI * 1900.0 * t) * 0.2
		var val := (noise + hiss) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_toxic_alarm() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.6
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var freq := 740.0 if fmod(t, 0.3) < 0.15 else 580.0
		var tone := sin(2.0 * PI * freq * t) * 0.65
		var sample := int(clampf(tone, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_cough_gasp() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.45
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * (t / duration)) * exp(-t * 3.0)
		var breath := (randf() * 2.0 - 1.0) * 0.35
		var throat := sin(2.0 * PI * 220.0 * t) * 0.25
		var val := (breath + throat) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_decomp_ring() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.9
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 1.5)
		var ring := sin(2.0 * PI * 3200.0 * t) * 0.4
		var sample := int(clampf(ring * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_scanner_scan() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.35
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var freq := 800.0 + (t / duration) * 1600.0
		var tone := sin(2.0 * PI * freq * t) * 0.4
		var pip := sin(2.0 * PI * 2400.0 * t) * 0.3 if t > (duration - 0.08) else 0.0
		var env := sin(PI * (t / duration))
		var sample := int(clampf((tone + pip) * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_multitool_weld() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.4
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var buzz := sin(2.0 * PI * 180.0 * t) * 0.4
		var crackle := (randf() * 2.0 - 1.0) * 0.4
		var env := 1.0 - (t / duration)
		var sample := int(clampf((buzz + crackle) * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_multitool_ratchet() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.2
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var click_phase := fmod(t, 0.05) / 0.05
		var click_tone := sin(2.0 * PI * 1200.0 * t) * exp(-click_phase * 15.0) * 0.5
		var sample := int(clampf(click_tone, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_locker_open() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.25
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var clunk := sin(2.0 * PI * 160.0 * t) * exp(-t * 18.0) * 0.6
		var metal := sin(2.0 * PI * 950.0 * t) * exp(-t * 25.0) * 0.35
		var sample := int(clampf(clunk + metal, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_recharge() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.5
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var freq := 300.0 + (t / duration) * (t / duration) * 1200.0
		var tone := sin(2.0 * PI * freq * t) * 0.45 * (0.3 + 0.7 * (t / duration))
		var sample := int(clampf(tone, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_datapad_decrypt() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.42
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var step := int((t / duration) * 4.0)
		var freqs := [987.77, 1318.51, 1479.98, 1975.53]
		var freq: float = freqs[clampi(step, 0, 3)]
		var env := exp(-fmod(t, duration / 4.0) * 14.0)
		var val := sin(2.0 * PI * freq * t) * env * 0.55
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_revelation_chime() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.85
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * minf(1.0, t / 0.12)) * exp(-t * 2.8)
		var c1 := sin(2.0 * PI * 440.0 * t) * 0.30
		var c2 := sin(2.0 * PI * 659.25 * t) * 0.28
		var c3 := sin(2.0 * PI * 880.0 * t) * 0.25
		var c4 := sin(2.0 * PI * 1108.73 * t) * 0.17
		var val := (c1 + c2 + c3 + c4) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_creature_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.75
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * (t / duration)) * (0.8 + 0.2 * sin(2.0 * PI * 18.0 * t))
		var f1 := 85.0 + sin(2.0 * PI * 7.0 * t) * 25.0
		var sub := sin(2.0 * PI * f1 * t) * 0.45
		var rasp := (randf() * 2.0 - 1.0) * 0.25 * (1.0 - t / duration)
		var val := (sub + rasp) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_creature_roar() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 1.1
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * minf(1.0, t / 0.15)) * exp(-t * 2.2)
		var freq := 380.0 - (t / duration) * 240.0
		var tone := sin(2.0 * PI * freq * t) * 0.4
		var shriek := sin(2.0 * PI * (freq * 1.6) * t) * 0.25
		var noise := (randf() * 2.0 - 1.0) * 0.35
		var val := (tone + shriek + noise) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_crisis_alarm() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.6
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var step := int(t / 0.15) % 2
		var freq: float = 640.0 if step == 0 else 480.0
		var tone := sin(2.0 * PI * freq * t) * 0.5
		var sample := int(clampf(tone, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav



