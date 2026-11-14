extends Node
## Musik, Takt-Uhr, Übergänge auf Takt, SFX-Pool, Ducking, Grammophon-Stärke.
## Phase 2: Musik und SFX sind synthetisierte Platzhalter. Die echten Stems (OGG) ersetzen nur
## _music_loops/_sfx_streams; die Schnittstelle (request_state, play_sfx, beat) bleibt.

signal beat(beat_in_bar: int, bar: int)
signal bar_started(bar: int)

const MIX_RATE := 22050
const BEATS_PER_BAR := 4
const MUSIC_STATES := {
	&"run": 168.0,
	&"boss1": 184.0,
	&"boss2": 196.0,
	&"boss3": 208.0,
}
## name: [freq_start, freq_end, dauer_s, welle, lautstärke_db, max_gleichzeitig]
const SFX := {
	&"shot": [950.0, 420.0, 0.05, "square", -16.0, 4],
	&"jump": [260.0, 720.0, 0.13, "sine", -10.0, 2],
	&"land": [160.0, 70.0, 0.07, "noise", -18.0, 2],
	&"pete_hit": [700.0, 140.0, 0.28, "square", -6.0, 1],
	&"enemy_hit": [380.0, 260.0, 0.04, "noise", -22.0, 4],
	&"pop": [520.0, 1200.0, 0.09, "sine", -12.0, 3],
	&"boss_tink": [2300.0, 2300.0, 0.09, "sine", -14.0, 1],
	&"boss_gong": [98.0, 82.0, 1.0, "gong", -3.0, 2],
	&"boss_gurgle": [180.0, 90.0, 0.6, "gurgle", -8.0, 1],
	&"boss_scratch": [3200.0, 2600.0, 0.8, "noise", -14.0, 1],
	&"boss_laugh": [420.0, 260.0, 0.7, "laugh", -6.0, 1],
	&"blob_squeak": [900.0, 1500.0, 0.14, "sine", -14.0, 2],
	&"pencil_sharpen": [1700.0, 2500.0, 0.45, "noise", -16.0, 2],
	&"thunk": [140.0, 60.0, 0.12, "sine", -10.0, 2],
	&"phase_change": [600.0, 120.0, 0.9, "noise", -6.0, 1],
	&"paper_rustle": [2400.0, 1800.0, 0.6, "noise", -14.0, 1],
	&"whistle": [1900.0, 2300.0, 0.45, "sine", -10.0, 1],
	&"bubble": [140.0, 320.0, 0.9, "gurgle", -8.0, 1],
	&"death": [700.0, 90.0, 0.9, "saw", -6.0, 1],
	&"victory": [392.0, 784.0, 1.2, "fanfare", -6.0, 1],
}

var state: StringName = &""
var bpm := 168.0
var bar := 0
var danger := 0

var _music: AudioStreamPlayer
var _danger_layer: AudioStreamPlayer
var _crackle: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams := {}
var _music_loops := {}   # state -> [main, danger]
var _pending: StringName = &""
var _t0_us := 0
var _last_beat := -1
var _rr := 0
var _duck_tween: Tween
var _death_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_music = _make_player(&"Music")
	_danger_layer = _make_player(&"Music")
	_crackle = _make_player(&"Master")
	for i in 12:
		_sfx_players.append(_make_player(&"SFX"))
	for key: StringName in SFX:
		_sfx_streams[key] = _synth_sfx(SFX[key])
	for s: StringName in MUSIC_STATES:
		_music_loops[s] = [_synth_bar(MUSIC_STATES[s], false), _synth_bar(MUSIC_STATES[s], true)]
	_crackle.stream = _synth_crackle()
	_crackle.play()
	apply_gramophone(SaveData.gramophone_level)
	Events.danger_level_changed.connect(func(level: int) -> void: danger = level)
	Events.boss_phase_changed.connect(_on_boss_phase_changed)
	Events.player_died.connect(_on_player_died)
	Events.level_completed.connect(func(_t: float, _d: int, _g: String) -> void: _stop_music_with(&"victory"))
	_apply_state(&"run")


func _process(_delta: float) -> void:
	if not _music.playing:
		return
	var spb := 60.0 / bpm
	var total := int((Time.get_ticks_usec() - _t0_us) / 1_000_000.0 / spb)
	if total == _last_beat:
		return
	_last_beat = total
	var b := total % BEATS_PER_BAR
	if b == 0:
		if _pending != &"":
			_apply_state(_pending)
			return
		bar += 1
		bar_started.emit(bar)
		_danger_layer.volume_db = 0.0 if danger >= 1 else -80.0
	beat.emit(b, bar)


## Wechsel passiert auf dem nächsten Takt, nie mitten im Takt.
func request_state(new_state: StringName) -> void:
	if not MUSIC_STATES.has(new_state):
		return
	if not _music.playing:
		_apply_state(new_state)
	elif new_state != state:
		_pending = new_state


## Neustart: zurück auf Takt 1 der Run-Musik, ohne Stille.
func reset_music() -> void:
	_pending = &""
	_apply_state(&"run")


func play_sfx(sfx: StringName) -> void:
	if not _sfx_streams.has(sfx):
		return
	var max_voices: int = SFX[sfx][5]
	var count := 0
	var free_player: AudioStreamPlayer = null
	for p in _sfx_players:
		if p.playing:
			if p.get_meta(&"sfx", &"") == sfx:
				count += 1
		elif free_player == null:
			free_player = p
	if count >= max_voices:
		return
	if free_player == null:
		free_player = _sfx_players[_rr]
		_rr = (_rr + 1) % _sfx_players.size()
	free_player.stream = _sfx_streams[sfx]
	free_player.volume_db = SFX[sfx][4]
	free_player.set_meta(&"sfx", sfx)
	free_player.pitch_scale = 1.0 + randf_range(-0.04, 0.04) if sfx == &"shot" else 1.0
	free_player.play()
	if sfx == &"boss_gong" or sfx == &"phase_change":
		duck()


## Boss-Gong und Phasenwechsel senken Music um 4 dB für 400 ms.
func duck(db := -4.0, duration := 0.4) -> void:
	var idx := AudioServer.get_bus_index(&"Music")
	if idx < 0:
		return
	if _duck_tween:
		_duck_tween.kill()
	AudioServer.set_bus_volume_db(idx, db)
	_duck_tween = create_tween()
	_duck_tween.tween_interval(duration)
	_duck_tween.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v), db, 0.0, 0.15)


## 0 = aus, 1 = leicht, 2 = voll (Low-Pass, Knistern, Mono-Anteil).
func apply_gramophone(level: int) -> void:
	level = clampi(level, 0, 2)
	var master := AudioServer.get_bus_index(&"Master")
	for i in AudioServer.get_bus_effect_count(master):
		var fx := AudioServer.get_bus_effect(master, i)
		if fx is AudioEffectLowPassFilter:
			(fx as AudioEffectLowPassFilter).cutoff_hz = [16000.0, 7500.0, 4800.0][level]
		elif fx is AudioEffectHighPassFilter:
			(fx as AudioEffectHighPassFilter).cutoff_hz = [20.0, 120.0, 220.0][level]
		elif fx is AudioEffectStereoEnhance:
			(fx as AudioEffectStereoEnhance).pan_pullout = [1.0, 0.6, 0.25][level]
	_crackle.volume_db = [-80.0, -32.0, -24.0][level]


func _apply_state(new_state: StringName) -> void:
	_pending = &""
	if _death_tween:
		_death_tween.kill()
	state = new_state
	bpm = MUSIC_STATES[new_state]
	var loops: Array = _music_loops[new_state]
	_music.stream = loops[0]
	_danger_layer.stream = loops[1]
	_music.pitch_scale = 1.0
	_music.volume_db = 0.0
	_danger_layer.volume_db = 0.0 if danger >= 1 else -80.0
	_music.play()
	_danger_layer.play()
	_t0_us = Time.get_ticks_usec()
	_last_beat = 0
	bar = 1
	bar_started.emit(bar)
	beat.emit(0, bar)


func _on_boss_phase_changed(phase: int) -> void:
	request_state(StringName("boss%d" % (phase + 1)))


func _on_player_died() -> void:
	play_sfx(&"death")
	_pending = &""
	_death_tween = create_tween()
	_death_tween.tween_property(_music, "pitch_scale", 0.35, 0.7)
	_death_tween.parallel().tween_property(_music, "volume_db", -40.0, 0.7)
	_death_tween.parallel().tween_property(_danger_layer, "volume_db", -80.0, 0.3)


func _stop_music_with(sfx: StringName) -> void:
	_music.stop()
	_danger_layer.stop()
	play_sfx(sfx)


# --- Aufbau -----------------------------------------------------------------

func _ensure_buses() -> void:
	for bus_name: StringName in [&"Music", &"SFX", &"Voice"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


# --- Platzhalter-Synthese -----------------------------------------------------

func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


func _synth_sfx(def: Array) -> AudioStreamWAV:
	var f0: float = def[0]
	var f1: float = def[1]
	var dur: float = def[2]
	var wave: String = def[3]
	var n := int(dur * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(wave) + int(f0)
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		if wave == "laugh":
			f *= 1.0 + 0.25 * signf(sin(t * TAU * 6.0))
		elif wave == "fanfare":
			f = [392.0, 523.25, 659.25, 784.0][mini(int(t * 4.0), 3)]
		phase += f / MIX_RATE
		var s := 0.0
		match wave:
			"sine", "fanfare":
				s = sin(phase * TAU)
			"square", "laugh":
				s = 0.6 if fmod(phase, 1.0) < 0.5 else -0.6
			"saw":
				s = fmod(phase, 1.0) * 2.0 - 1.0
			"noise":
				s = rng.randf_range(-1.0, 1.0) * (0.5 + 0.5 * sin(phase * TAU))
			"gong":
				s = sin(phase * TAU) * 0.7 + sin(phase * TAU * 2.76) * 0.3
			"gurgle":
				s = sin(phase * TAU + sin(t * TAU * 18.0) * 3.0)
		var env := (1.0 - t) * minf(t * 60.0, 1.0)
		if wave == "gong":
			env = exp(-t * 4.0) * minf(t * 200.0, 1.0)
		out[i] = s * env * 0.8
	return _wav(out)


## Ein Takt Platzhalter-Rhythmus. Hauptloop: Bassdrum auf 1 und 3, Snare auf 2 und 4.
## Danger-Layer: Achtel-Hi-Hats, wird auf Takt dazu- oder weggeschaltet.
func _synth_bar(tempo: float, danger_layer: bool) -> AudioStreamWAV:
	var spb := 60.0 / tempo
	var n := int(round(spb * BEATS_PER_BAR * MIX_RATE))
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tempo) + (7 if danger_layer else 0)
	var beat_len := int(spb * MIX_RATE)
	for b in BEATS_PER_BAR * (2 if danger_layer else 1):
		var start := int(b * beat_len / (2.0 if danger_layer else 1.0))
		if danger_layer:
			var hl := int(0.03 * MIX_RATE)
			for i in hl:
				if start + i < n:
					out[start + i] += rng.randf_range(-1.0, 1.0) * 0.25 * (1.0 - float(i) / hl)
		elif b % 2 == 0:
			var kl := int(0.16 * MIX_RATE)
			var ph := 0.0
			for i in kl:
				var t := float(i) / kl
				ph += lerpf(110.0, 45.0, t) / MIX_RATE
				if start + i < n:
					out[start + i] += sin(ph * TAU) * (1.0 - t) * (0.9 if b == 0 else 0.6)
		else:
			var sl := int(0.08 * MIX_RATE)
			for i in sl:
				if start + i < n:
					out[start + i] += rng.randf_range(-1.0, 1.0) * 0.35 * (1.0 - float(i) / sl)
	return _wav(out, true)


func _synth_crackle() -> AudioStreamWAV:
	var n := MIX_RATE * 2
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1930
	for i in n:
		out[i] = rng.randf_range(-0.03, 0.03)
		if rng.randf() < 0.0012:
			out[i] = rng.randf_range(-0.6, 0.6)
	return _wav(out, true)
