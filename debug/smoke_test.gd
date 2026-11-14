extends Node
## Automatischer Durchlauf ohne Bildschirm, prüft die Abnahmewerte von Phase 2:
##   godot --headless --path . --fixed-fps 60 res://debug/smoke_test.tscn
## Exit-Code = Anzahl Fehler (0 = alles grün).

const MAIN := preload("res://main/main.tscn")

var failures := 0
var _telegraphs: Array[Array] = []
var _completed := false


func _ready() -> void:
	Game.fixed_seed = 1930
	add_child(MAIN.instantiate())
	await _frames(110)  # Titelkarte 1,5 s
	var pete: Pete = Game.player
	var level: Level01 = Game.level
	InputRouter.override_enabled = true
	Game.god_mode = true
	_check(Game.running, "Level läuft nach der Titelkarte")
	_check(pete.is_on_floor(), "Pete steht am Start auf dem Boden")
	_check(AudioDirector._music.stream is AudioStreamOggVorbis and AudioDirector._music.playing, "Echte Musik läuft (OGG, Run-Titel)")
	_check(_alive_enemies(level, Level01.SEG_B) == 4, "Segment A: 4 Ink-Blobs (%d)" % _alive_enemies(level, Level01.SEG_B))
	_check(_alive_enemies(level) == 20, "Segmente A–D: 10 Blobs + 10 Pencils (%d)" % _alive_enemies(level))

	# --- Laufen -------------------------------------------------------------
	var x0 := pete.global_position.x
	InputRouter.override_move = Vector2.RIGHT
	await _frames(30)
	InputRouter.override_move = Vector2.ZERO
	var dx := pete.global_position.x - x0
	_check(absf(dx - 260.0) <= 20.0, "Laufen 520 px/s ohne Rampe (%.0f px in 0,5 s)" % dx)

	# --- Springen -----------------------------------------------------------
	var high := await _jump_peak(60)
	_check(high > 185.0 and high < 215.0, "Hochsprung ca. 206 px (%.0f px)" % high)
	var low := await _jump_peak(3)
	_check(low < high * 0.6, "Variable Sprunghöhe: kurzer Tap %.0f px < Hochsprung" % low)
	_check(await _jump_buffer_works(), "Jump Buffer: Sprung kurz vor der Landung wird ausgeführt")

	# --- Zielen -------------------------------------------------------------
	pete.facing = 1
	_check(pete.compute_aim(Vector2(0, -1), true, false) == Vector2.UP, "Zielen nach oben am Boden")
	_check(pete.compute_aim(Vector2(1, -1), true, false).is_equal_approx(Vector2(1, -1).normalized()), "Zielen schräg oben")
	_check(pete.compute_aim(Vector2(0, 1), true, false) == Vector2.RIGHT, "Am Boden ohne Lock kein Zielen nach unten")
	_check(pete.compute_aim(Vector2(0, 1), false, false) == Vector2.DOWN, "In der Luft Zielen nach unten")
	_check(pete.compute_aim(Vector2(-1, 1), true, true).is_equal_approx(Vector2(-1, 1).normalized()), "Lock-Aim: alle 8 Richtungen")

	# --- Feuern -------------------------------------------------------------
	var shots0: int = Game.pool.player_shots_spawned
	pete.facing = -1  # weg von den Blobs, die werden unten einzeln geprüft
	InputRouter.override_fire_held = true
	await _frames(120)
	InputRouter.override_fire_held = false
	var shots: int = Game.pool.player_shots_spawned - shots0
	_check(shots >= 16 and shots <= 18, "Dauerfeuer 8,5 Schuss/s (%d Schuss in 2 s)" % shots)

	# --- Ink-Blob -----------------------------------------------------------
	var blobs_before := _alive_enemies(level, Level01.SEG_B)
	pete.global_position = Vector2(560, Level01.FLOOR_Y)
	pete.facing = 1
	InputRouter.override_fire_held = true
	var killed := await _wait_until(func() -> bool: return _alive_enemies(level, Level01.SEG_B) < blobs_before, 300)
	InputRouter.override_fire_held = false
	_check(killed, "Ink-Blob stirbt nach 3 Treffern")

	# --- Schaden, Unverwundbarkeit, Hit-Stop ---------------------------------
	Game.god_mode = false
	await _frames(2)
	var hp0 := pete.hp
	_check(pete.hurtbox.take_hit(1, self), "Treffer wird angenommen")
	_check(pete.hp == hp0 - 1, "Treffer kostet 1 HP")
	_check(Engine.time_scale < 1.0, "Hit-Stop aktiv")
	_check(not pete.hurtbox.take_hit(1, self) and pete.hp == hp0 - 1, "Unverwundbar direkt nach Treffer")
	await _frames(100)
	_check(Engine.time_scale == 1.0, "Hit-Stop endet")
	_check(pete.hurtbox.take_hit(1, self), "Nach 1,5 s wieder verwundbar")

	# --- Tod und Sofort-Neustart --------------------------------------------
	await _frames(100)
	pete.hurtbox.take_hit(1, self)
	_check(not pete.alive and not Game.running, "Pete stirbt bei 0 HP")
	await _frames(70)
	_check(get_tree().paused and level.get_parent().get_node("HUD").is_death_screen_visible(), "Todesbildschirm mit Fortschritt erscheint")
	Game.restart_level()
	await _frames(2)
	_check(Game.last_restart_ms < 500.0, "Neustart in %.2f ms (Ziel ≤ 500 ms)" % Game.last_restart_ms)
	_check(pete.alive and pete.hp == 3 and pete.controls_enabled, "Pete nach Neustart voll da und steuerbar")
	_check(pete.global_position.distance_to(Level01.SPAWN) < 2.0, "Pete am Startpunkt")
	_check(_alive_enemies(level) == 20, "Gegner nach Neustart wieder da")
	_check(not get_tree().paused and Game.running, "Spiel läuft nach Neustart")
	_check(AudioDirector.state == &"run" and AudioDirector.bar <= 1, "Musik zurück auf Takt 1")

	# --- Boss-Arena ---------------------------------------------------------
	Game.god_mode = true
	var brain := level.boss.brain
	brain.telegraph_started.connect(func(a: BossAttack, w: float) -> void: _telegraphs.append([a.id, w]))
	Events.level_completed.connect(func(_t: float, _d: int, _g: String) -> void: _completed = true)
	level.skip_to_arena()
	var started := await _wait_until(func() -> bool: return brain.is_fighting(), 300)
	_check(started and level.in_arena, "Kamera lockt Arena, Boss startet ohne Ladebildschirm")
	var t0 := Time.get_ticks_msec()
	while AudioDirector.state != &"boss1" and Time.get_ticks_msec() - t0 < 3000:
		await get_tree().physics_frame
	_check(AudioDirector.state == &"boss1", "Musik wechselt auf Takt zu Boss Phase 1")
	_check(AudioDirector._music.stream.resource_path.ends_with("boss1_bourbon_blues.ogg"), "Boss-Titel überblendet")

	await _frames(60 * 40)
	var ids := {}
	var min_windup := 99.0
	var max_run := 0
	var run := 0
	var last: StringName = &""
	for t in _telegraphs:
		ids[t[0]] = true
		min_windup = minf(min_windup, t[1])
		run = run + 1 if t[0] == last else 1
		last = t[0]
		max_run = maxi(max_run, run)
	_check(ids.size() == 3, "Alle 3 Attacken von Phase 1 kommen vor (%s)" % ", ".join(ids.keys()))
	_check(min_windup >= 0.5, "Jede Vorwarnung ≥ 0,5 s (min %.2f s)" % min_windup)
	_check(max_run <= 2, "Kein Muster mehr als 2-mal hintereinander (max %d)" % max_run)

	# Gefahr ist echt: wer stehen bleibt, wird getroffen
	var arena_x := Level01.ARENA_LEFT + 600.0
	Game.god_mode = false
	pete.global_position = Vector2(arena_x, Level01.FLOOR_Y)
	var hit := await _wait_until(func() -> bool: return pete.hp < 3, 60 * 15)
	_heal(pete)
	Game.god_mode = true
	_check(hit, "Boss-Attacken treffen einen stehenden Pete")

	# Pete trifft den Boss
	var dmg0 := brain.total_damage
	pete.global_position = Vector2(arena_x, Level01.FLOOR_Y)
	pete.facing = 1
	InputRouter.override_fire_held = true
	await _frames(60 * 5)
	InputRouter.override_fire_held = false
	var dealt := brain.total_damage - dmg0
	_check(dealt >= 100, "Pete trifft Reginald (%d Schaden in 5 s, max 170)" % dealt)

	# --- Phase 2 "Die Papierflieger-Debatte" -----------------------------------
	brain.take_damage(brain.phase_hp)
	await _frames(2)
	_check(brain.phase_index == 1 and level.arena.phase == 1, "Phase 2: Flut zur Hälfte und schwebende Bücher")
	t0 = Time.get_ticks_msec()
	while AudioDirector.state != &"boss2" and Time.get_ticks_msec() - t0 < 3000:
		await get_tree().physics_frame
	_check(AudioDirector.state == &"boss2", "Musik wechselt zu Boss Phase 2")
	_telegraphs.clear()
	pete.global_position = Vector2(Level01.ARENA_LEFT + 150.0, Level01.FLOOR_Y)
	await _frames(60 * 40)
	_check_phase_attacks(3, "Phase 2")
	var guards := level.count_alive(PencilSprite, Level01.ARENA_LEFT)
	_check(guards >= 1 and guards <= 4, "Bleistift-Garde: 1–4 Pencils in der Arena (%d)" % guards)

	# Flut in der rechten Hälfte schadet, die Tintenwelle trifft am Boden, nicht auf den Büchern
	level._kill_all_enemies()
	Game.pool.clear_all()
	Game.god_mode = false
	pete.global_position = Vector2(Level01.PLAY_RIGHT - 120.0, Level01.FLOOR_Y)
	_check(await _wait_until(func() -> bool: return pete.hp < 3, 30), "Phase 2: Tinte am Boden rechts schadet")
	_heal(pete)
	_check(await _survives_wave_on(pete, true), "Tintenwelle: auf dem Buch sicher")
	_check(not await _survives_wave_on(pete, false), "Tintenwelle: am Boden getroffen")
	_heal(pete)

	# --- Phase 3 "Der letzte Federstrich" ---------------------------------------
	brain.take_damage(brain.phase_hp)
	await _frames(2)
	_check(brain.phase_index == 2 and level.arena.phase == 2, "Phase 3: Bücher und Flut weg")
	_telegraphs.clear()
	pete.global_position = Vector2(Level01.ARENA_LEFT + 150.0, Level01.FLOOR_Y)
	await _frames(60 * 40)
	_check_phase_attacks(2, "Phase 3")
	brain.take_damage(brain.phase_hp - int(brain.data.phases[2].hp * 0.3) + 1)
	_check(brain.raging and brain.speed_mult() > 1.1, "Rage ab 30 % HP: 15 % schneller")
	Game.pool.clear_all()
	Game.god_mode = false
	_heal(pete)
	pete.global_position = Vector2(Level01.ARENA_LEFT + 700.0, Level01.FLOOR_Y)
	brain.forced_attack = &"quill_strike"
	_check(await _wait_until(func() -> bool: return pete.hp < 3, 60 * 12), "Federstoß trifft Petes Bahn")
	Game.god_mode = true
	_heal(pete)

	# Sieg
	var wins0 := SaveData.wins
	brain.take_damage(brain.phase_hp)
	await _frames(5)
	_check(brain.state == BossBrain.State.DEAD and _completed, "Phase 3 besiegt → Level geschafft")
	_check(SaveData.wins == wins0 + 1, "Sieg gespeichert")
	_check(level.count_alive(PencilSprite) == 0, "Minions verschwinden beim Sieg")

	Game.restart_level()
	await _frames(2)
	_check(brain.state == BossBrain.State.IDLE and not level.in_arena and level.arena.phase == 0, "Neustart setzt Boss und Arena zurück")

	# --- Run-Segmente B–D ----------------------------------------------------
	Game.god_mode = false
	pete.global_position = Vector2(5030.0, 820.0)  # in die Lücke der Lineal-Brücke
	await _wait_until(func() -> bool: return pete.hp < 3, 120)
	_check(pete.hp == 2 and absf(pete.global_position.x - (Level01.SEG_B + 150.0)) < 40.0, "Sturz in den Tintensee: 1 HP, Respawn am Brückenanfang")
	_heal(pete)
	pete.global_position = Vector2(7400.0, 1000.0)  # in die Uhrwerk-Grube
	await _wait_until(func() -> bool: return pete.hp < 3, 120)
	_check(pete.hp == 2 and pete.global_position.x < Level01.SEG_C + 600.0, "Sturz ins Uhrwerk: Respawn vor den Zahnrädern")
	_heal(pete)
	level._kill_all_enemies()
	pete.global_position = Vector2(10090.0, Level01.FLOOR_Y)
	_check(await _wait_until(func() -> bool: return pete.hp < 3, 60 * 4), "Kippendes Tintenfass: Flut am Boden schadet")
	_heal(pete)
	pete.global_position = Vector2(9800.0, Level01.FLOOR_Y - 170.0)
	await _frames(10)
	_heal(pete)  # Überlappungen sind nach dem Teleport einen Tick alt
	var got_hit := await _wait_until(func() -> bool: return pete.hp < 3, 60 * 4)
	_check(not got_hit and pete.is_on_floor() and pete.global_position.y < Level01.FLOOR_Y - 100.0, "Federhalter-Steg: sicher über der Flut")
	Game.god_mode = true

	# --- Durchlauf-Bot: Start bis Arena --------------------------------------
	Game.restart_level()
	await _frames(2)
	var result := await _bot_run(240)
	_check(result[0], "Bot läuft Segment A–D bis in die Arena (%.0f s, %d Stürze)" % [result[1], result[2]])

	Game.restart_level()
	await _frames(2)
	_check(Game.running and pete.hp == 3, "Neustart nach Bot-Lauf")

	print("\n%s: %d Fehler" % ["GRÜN" if failures == 0 else "ROT", failures])
	get_tree().quit(failures)


func _check_phase_attacks(expected: int, label: String) -> void:
	var ids := {}
	var min_windup := 99.0
	var max_run := 0
	var run := 0
	var last: StringName = &""
	for t in _telegraphs:
		ids[t[0]] = true
		min_windup = minf(min_windup, t[1])
		run = run + 1 if t[0] == last else 1
		last = t[0]
		max_run = maxi(max_run, run)
	_check(ids.size() == expected, "%s: alle %d Attacken kommen vor (%s)" % [label, expected, ", ".join(ids.keys())])
	_check(min_windup >= 0.5 and max_run <= 2, "%s: Vorwarnung ≥ 0,5 s (min %.2f), max. 2 Wiederholungen (%d)" % [label, min_windup, max_run])


func _heal(pete: Pete) -> void:
	pete.hp = 3
	pete._invuln = 0.0
	Events.player_hp_changed.emit(3)


func _survives_wave_on(pete: Pete, on_book: bool) -> bool:
	var brain: BossBrain = Game.level.boss.brain
	await _wait_until(func() -> bool: return brain.state == BossBrain.State.RECOVERY or brain.state == BossBrain.State.TELEGRAPH, 600)
	await _wait_until(func() -> bool: return brain.state == BossBrain.State.RECOVERY, 600)
	Game.god_mode = true
	pete.hp = 3
	pete._invuln = 0.0
	Game.pool.clear_all()
	if on_book:
		var x := Level01.ARENA_LEFT + (Level01.PLAY_RIGHT - Level01.ARENA_LEFT) * 0.18
		pete.global_position = Vector2(x, Level01.FLOOR_Y - 200.0)
	else:
		pete.global_position = Vector2(Level01.ARENA_LEFT + 450.0, Level01.FLOOR_Y)
	brain.forced_attack = &"ink_wave"
	await _wait_until(func() -> bool: return brain.current != null and brain.current.id == &"ink_wave" and brain.state == BossBrain.State.ACTIVE, 600)
	Game.level._kill_all_enemies()  # nur die Welle prüfen, keine Pencils der Garde
	Game.pool.clear_all()
	var orig: Callable = pete.hurtbox.receiver
	pete.hurtbox.receiver = func(d: int, src: Node) -> bool:
		if src:
			print("    Treffer durch ", src.get_path())
		return orig.call(d, src)
	Game.god_mode = false
	await _wait_until(func() -> bool: return brain.state == BossBrain.State.RECOVERY or pete.hp < 3, 300)
	var survived := pete.hp == 3
	pete.hurtbox.receiver = orig
	Game.god_mode = true
	pete.hp = 3
	pete._invuln = 0.0
	return survived


## Einfacher Bot: rechts laufen, feuern, springen bei Wand oder fehlendem Boden voraus.
func _bot_run(max_s: float) -> Array:
	var pete: Pete = Game.player
	var level: Level01 = Game.level
	Game.god_mode = true
	InputRouter.override_move = Vector2.RIGHT
	InputRouter.override_fire_held = true
	var space := pete.get_world_2d().direct_space_state
	var frames := 0
	var falls := 0
	var hold := 0
	var last_y := pete.global_position.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	while frames < max_s * 60.0 and not level.in_arena:
		var p := pete.global_position
		if hold > 0:
			hold -= 1
		elif pete.is_on_floor():
			var ahead := PhysicsRayQueryParameters2D.create(p + Vector2(70, -10), p + Vector2(70, 60), Layers.WORLD)
			var gap := space.intersect_ray(ahead).is_empty()
			if pete.is_on_wall() or gap or rng.randf() < 0.02:
				hold = rng.randi_range(10, 22)
		InputRouter.override_jump_held = hold > 0
		await get_tree().physics_frame
		frames += 1
		if pete.global_position.y < last_y - 150.0 and p.y > 950.0:
			falls += 1
		last_y = pete.global_position.y
	InputRouter.override_move = Vector2.ZERO
	InputRouter.override_fire_held = false
	InputRouter.override_jump_held = false
	return [level.in_arena, frames / 60.0, falls]


func _check(ok: bool, what: String) -> void:
	print(("  OK   " if ok else "  FAIL ") + what)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _wait_until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


func _alive_enemies(level: Level01, max_x := INF) -> int:
	var n := 0
	for e in level.enemies.get_children():
		if e is EnemyBase and not e.dead and e.global_position.x < max_x:
			n += 1
	return n


func _jump_peak(hold_frames: int) -> float:
	var pete: Pete = Game.player
	await _wait_until(func() -> bool: return pete.is_on_floor(), 120)
	var y0 := pete.global_position.y
	var top := y0
	InputRouter.override_jump_held = true
	for i in 90:
		await get_tree().physics_frame
		if i == hold_frames:
			InputRouter.override_jump_held = false
		top = minf(top, pete.global_position.y)
		if i > 5 and pete.is_on_floor():
			break
	InputRouter.override_jump_held = false
	await _frames(2)
	return y0 - top


func _jump_buffer_works() -> bool:
	var pete: Pete = Game.player
	await _wait_until(func() -> bool: return pete.is_on_floor(), 120)
	var floor_y := pete.global_position.y
	InputRouter.override_jump_held = true
	await _frames(2)
	InputRouter.override_jump_held = false
	# ca. 5 Frames vor der Landung drücken (Puffer: 8 Frames)
	await _wait_until(func() -> bool: return pete.velocity.y > 0.0 and floor_y - pete.global_position.y < 30.0, 120)
	InputRouter.override_jump_held = true  # gedrückt, solange Pete noch in der Luft ist
	await _frames(14)
	InputRouter.override_jump_held = false
	var airborne_again := pete.global_position.y < floor_y - 40.0
	await _wait_until(func() -> bool: return pete.is_on_floor(), 120)
	return airborne_again
