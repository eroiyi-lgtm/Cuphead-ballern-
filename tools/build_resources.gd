extends SceneTree
## Legt die .tres-Daten und das Audio-Bus-Layout mit den Startwerten aus dem Plan an.
## Vorhandene Dateien bleiben unangetastet (Tuning am Gerät geht nicht verloren); --force überschreibt.
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_resources.gd [-- --force]

var force := false


func _init() -> void:
	force = "--force" in OS.get_cmdline_user_args()
	_save(load("res://data/classes/player_tuning.gd").new(), "res://data/player/pete_tuning.tres")
	_save(load("res://data/classes/weapon_tuning.gd").new(), "res://data/player/ink_pistol.tres")
	_save(load("res://data/classes/ink_blob_tuning.gd").new(), "res://data/enemies/ink_blob.tres")
	_save(load("res://data/classes/pencil_tuning.gd").new(), "res://data/enemies/pencil_sprite.tres")
	_build_boss()
	_build_buses()
	quit()


func _save(res: Resource, path: String) -> void:
	if FileAccess.file_exists(path) and not force:
		print("unverändert: ", path)
		return
	var err := ResourceSaver.save(res, path)
	print("geschrieben: ", path, " (", error_string(err), ")")


func _attack(id: String, display: String, windup: float, active: float, recovery: float,
		anim: String, sfx: String, params: Dictionary) -> Resource:
	var path := "res://data/boss_inkwell/%s.tres" % id
	var a: Resource = load("res://data/classes/boss_attack.gd").new()
	a.id = StringName(id)
	a.display_name = display
	a.windup_time = windup
	a.active_time = active
	a.recovery_time = recovery
	a.telegraph_anim = StringName(anim)
	a.telegraph_sfx = StringName(sfx)
	a.pattern = load("res://actors/bosses/inkwell/patterns/%s.gd" % id)
	a.params = params
	_save(a, path)
	return load(path)


func _build_boss() -> void:
	var spit := _attack("ink_spit", "Tintenspucke", 0.6, 1.4, 0.6, "telegraph_ink_spit", "boss_gurgle",
		{"offsets": [-180.0, 0.0, 180.0], "stagger": 0.12, "flight_time": 1.0, "gravity": 1400.0})
	var quill := _attack("quill_decree", "Federkiel-Erlass", 0.8, 1.2, 0.6, "telegraph_quill", "boss_scratch",
		{"count": 4, "column_width": 200.0, "shadow_width": 120.0, "fall_speed": 950.0})
	var seal := _attack("seal_stamp", "Siegelstempel", 0.7, 1.6, 0.7, "telegraph_seal", "boss_gong",
		{"drop_time": 0.12, "hit_window": 0.2, "wave_speed": 650.0, "wave_radius": 30.0})

	var phase1: Resource = load("res://data/classes/boss_phase.gd").new()
	phase1.display_name = "Die Audienz"
	phase1.hp = 1100
	var attacks: Array[BossAttack] = [spit, quill, seal]
	phase1.attacks = attacks

	var boss: Resource = load("res://data/classes/boss_data.gd").new()
	boss.display_name = "Sir Reginald Inkwell"
	# Phase 2 "Die Papierflieger-Debatte" (1000 HP) und Phase 3 "Der letzte Federstrich" (900 HP)
	# werden hier ergänzt, sobald ihre Muster gebaut sind.
	var phases: Array[BossPhase] = [phase1]
	boss.phases = phases
	_save(boss, "res://data/boss_inkwell/sir_reginald.tres")


## Master mit Grammophon-Kette (Hochpass, Tiefpass, Mono-Anteil, Kompressor), dazu Music, SFX, Voice.
func _build_buses() -> void:
	var path := "res://audio/bus_layout.tres"
	if FileAccess.file_exists(path) and not force:
		print("unverändert: ", path)
		return
	while AudioServer.bus_count > 1:
		AudioServer.remove_bus(AudioServer.bus_count - 1)
	for i in AudioServer.get_bus_effect_count(0):
		AudioServer.remove_bus_effect(0, 0)
	var hp := AudioEffectHighPassFilter.new()
	hp.cutoff_hz = 220.0
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 4800.0
	var mono := AudioEffectStereoEnhance.new()
	mono.pan_pullout = 0.25
	var comp := AudioEffectCompressor.new()
	comp.threshold = -12.0
	comp.ratio = 3.0
	for fx in [hp, lp, mono, comp]:
		AudioServer.add_bus_effect(0, fx)
	for bus_name in ["Music", "SFX", "Voice"]:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, &"Master")
	var err := ResourceSaver.save(AudioServer.generate_bus_layout(), path)
	print("geschrieben: ", path, " (", error_string(err), ")")
