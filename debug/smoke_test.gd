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
	InputRouter.override_fire_held = true
	await _frames(120)
	InputRouter.override_fire_held = false
	var shots: int = Game.pool.player_shots_spawned - shots0
	_check(shots >= 16 and shots <= 18, "Dauerfeuer 8,5 Schuss/s (%d Schuss in 2 s)" % shots)

	# --- Ink-Blob -----------------------------------------------------------
	var blobs_before := _alive_enemies(level)
	_check(blobs_before == 4, "Segment A: 4 Ink-Blobs (%d)" % blobs_before)
	pete.global_position = Vector2(560, Level01.FLOOR_Y)
	pete.facing = 1
	InputRouter.override_fire_held = true
	var killed := await _wait_until(func() -> bool: return _alive_enemies(level) < blobs_before, 300)
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
	_check(Game.last_restart_ms < 500.0, "Neustart in %.2f ms (Ziel ≤ 500 ms)" % Game.last_restart_ms)
	await _frames(2)
	_check(pete.alive and pete.hp == 3 and pete.controls_enabled, "Pete nach Neustart voll da und steuerbar")
	_check(pete.global_position.distance_to(Level01.SPAWN) < 2.0, "Pete am Startpunkt")
	_check(_alive_enemies(level) == 4, "Gegner nach Neustart wieder da")
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
	await _frames(60)
	_check(AudioDirector.state == &"boss1", "Musik wechselt auf Takt zu Boss Phase 1")

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
	Game.god_mode = false
	pete.global_position = Vector2(5600, Level01.FLOOR_Y)
	var hit := await _wait_until(func() -> bool: return pete.hp < 3, 60 * 15)
	Game.god_mode = true
	_check(hit, "Boss-Attacken treffen einen stehenden Pete")

	# Pete trifft den Boss
	var dmg0 := brain.total_damage
	pete.global_position = Vector2(5600, Level01.FLOOR_Y)
	pete.facing = 1
	InputRouter.override_fire_held = true
	await _frames(60 * 5)
	InputRouter.override_fire_held = false
	var dealt := brain.total_damage - dmg0
	_check(dealt >= 100, "Pete trifft Reginald (%d Schaden in 5 s, max 170)" % dealt)

	# Sieg
	var wins0 := SaveData.wins
	brain.take_damage(brain.phase_hp)
	await _frames(5)
	_check(brain.state == BossBrain.State.DEAD and _completed, "Phase 1 besiegt → Level geschafft")
	_check(SaveData.wins == wins0 + 1, "Sieg gespeichert")

	Game.restart_level()
	await _frames(2)
	_check(brain.state == BossBrain.State.IDLE and not level.in_arena, "Neustart setzt Boss und Arena zurück")

	print("\n%s: %d Fehler" % ["GRÜN" if failures == 0 else "ROT", failures])
	get_tree().quit(failures)


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


func _alive_enemies(level: Level01) -> int:
	var n := 0
	for e in level.enemies.get_children():
		if e is EnemyBase and not e.dead:
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
	await _wait_until(func() -> bool: return pete.velocity.y > 0.0 and floor_y - pete.global_position.y < 70.0, 120)
	InputRouter.override_jump_held = true  # gedrückt, solange Pete noch in der Luft ist
	await _frames(14)
	InputRouter.override_jump_held = false
	var airborne_again := pete.global_position.y < floor_y - 40.0
	await _wait_until(func() -> bool: return pete.is_on_floor(), 120)
	return airborne_again
