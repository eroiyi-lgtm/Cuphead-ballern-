class_name Pete
extends CharacterBody2D
## Spielerfigur. Liest ausschließlich InputRouter; alle Zahlen kommen aus den .tres-Ressourcen.

const TUNING: PlayerTuning = preload("res://data/player/pete_tuning.tres")
const WEAPON: WeaponTuning = preload("res://data/player/ink_pistol.tres")
const CHEST := Vector2(0, -62)

var hp := 3
var alive := true
var controls_enabled := false
var facing := 1
var aim_dir := Vector2.RIGHT
var locked := false
var spawn_point := Vector2.ZERO

var visual: Node2D
var hurtbox: Hurtbox

var _body_visual: Node2D
var _muzzle: Polygon2D
var _coyote := 0
var _buffer := 0
var _jumping := false
var _was_on_floor := true
var _invuln := 0.0
var _fire_cd := 0.0
var _pending_shot := -1
var _flash_t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	floor_snap_length = 8.0
	var body := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = TUNING.body_size
	body.shape = rect
	body.position = Vector2(0, -TUNING.body_size.y / 2.0)
	add_child(body)

	visual = get_node_or_null(^"Visual")
	if visual == null:
		visual = PeteVisual.build()
		add_child(visual)
	_body_visual = visual.get_node_or_null(^"Body")
	if _body_visual == null:
		_body_visual = visual
	_muzzle = PeteVisual.muzzle_star()
	add_child(_muzzle)

	var hs := RectangleShape2D.new()
	hs.size = TUNING.hurtbox_size
	hurtbox = Hurtbox.create(self, Layers.PETE_HURTBOX, hs, TUNING.hurtbox_center, _on_hurt)

	spawn_point = global_position
	hp = TUNING.max_hp
	Game.player = self
	Events.level_restarted.connect(reset)


func reset() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	hp = TUNING.max_hp
	alive = true
	controls_enabled = true
	facing = 1
	aim_dir = Vector2.RIGHT
	locked = false
	_invuln = 0.0
	_buffer = 0
	_coyote = 0
	_jumping = false
	_fire_cd = 0.0
	_pending_shot = -1
	_flash_t = 0.0
	visual.visible = true
	visual.modulate = Color.WHITE
	visual.scale = Vector2.ONE
	_body_visual.scale = Vector2.ONE
	_muzzle.visible = false
	Events.player_hp_changed.emit(hp)


func _physics_process(delta: float) -> void:
	if not alive:
		velocity.x = 0.0
		velocity.y = minf(velocity.y + TUNING.gravity_down * delta, TUNING.max_fall_speed)
		move_and_slide()
		return

	var move := Vector2.ZERO
	var jump_pressed := false
	var jump_held := false
	var fire_held := false
	var lock_held := false
	if controls_enabled:
		move = InputRouter.move
		jump_pressed = InputRouter.jump_pressed
		jump_held = InputRouter.jump_held
		fire_held = InputRouter.fire_held
		lock_held = InputRouter.lock_held

	var on_floor := is_on_floor()
	_buffer = TUNING.jump_buffer_frames if jump_pressed else maxi(_buffer - 1, 0)
	_coyote = TUNING.coyote_frames if on_floor else maxi(_coyote - 1, 0)
	locked = lock_held and on_floor

	# Laufen: digital, ohne Rampe
	var dir_x := 0.0
	if absf(move.x) >= TUNING.aim_deadzone:
		dir_x = signf(move.x)
	velocity.x = 0.0 if locked else dir_x * TUNING.run_speed
	if dir_x != 0.0 and not locked:
		facing = int(dir_x)

	# Springen mit Coyote Time und Jump Buffer
	if _buffer > 0 and _coyote > 0:
		velocity.y = TUNING.jump_velocity
		_buffer = 0
		_coyote = 0
		_jumping = true
		locked = false
		AudioDirector.play_sfx(&"jump")
		_haptic()
		_squash(Vector2(0.8, 1.2))
	if _jumping and not jump_held and velocity.y < TUNING.jump_cut_velocity:
		velocity.y = TUNING.jump_cut_velocity
		_jumping = false
	if velocity.y >= 0.0:
		_jumping = false

	var g := TUNING.gravity_up if velocity.y < 0.0 else TUNING.gravity_down
	velocity.y = minf(velocity.y + g * delta, TUNING.max_fall_speed)
	move_and_slide()

	var now_on_floor := is_on_floor()
	if now_on_floor and not _was_on_floor:
		AudioDirector.play_sfx(&"land")
		_squash(Vector2(1.25, 0.75))
	_was_on_floor = now_on_floor

	aim_dir = compute_aim(move, now_on_floor, locked)
	if locked and aim_dir.x != 0.0:
		facing = int(signf(aim_dir.x))
	visual.scale.x = facing

	_update_weapon(delta, fire_held)
	_update_invuln(delta)
	if Game.level and global_position.y > Game.level.kill_y:
		_fall_out()


## 8-Wege-Zielen. Am Boden ohne Lock: waagerecht, schräg oben, oben. Nach unten nur in der Luft.
func compute_aim(move: Vector2, on_floor: bool, is_locked: bool) -> Vector2:
	var d := Vector2.ZERO
	if move.length() >= TUNING.aim_deadzone:
		var a := roundf(move.angle() / (PI / 4.0)) * (PI / 4.0)
		d = Vector2(roundf(cos(a)), roundf(sin(a)))
	if on_floor and not is_locked and d.y > 0.0:
		d.y = 0.0
	if d == Vector2.ZERO:
		d = Vector2(facing, 0)
	return d.normalized()


func is_invulnerable() -> bool:
	return _invuln > 0.0


func _update_weapon(delta: float, fire_held: bool) -> void:
	var interval := 1.0 / WEAPON.fire_rate
	if fire_held:
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd += interval
			_flash_t = WEAPON.muzzle_flash_time
			AudioDirector.play_sfx(&"shot")
			if WEAPON.pellet_delay_frames <= 0:
				_spawn_pellet()
			else:
				_pending_shot = WEAPON.pellet_delay_frames
	else:
		_fire_cd = maxf(_fire_cd - delta, 0.0)

	if _pending_shot > 0:
		_pending_shot -= 1
		if _pending_shot == 0:
			_pending_shot = -1
			_spawn_pellet()

	# Mündungsfeuer: 3 Zeichnungen à 1/24 s, rotiert mit der Zielrichtung
	if _flash_t > 0.0:
		_flash_t -= delta
		var frame := clampi(int((WEAPON.muzzle_flash_time - _flash_t) * 24.0), 0, 2)
		_muzzle.visible = true
		_muzzle.position = CHEST + aim_dir * WEAPON.muzzle_distance
		_muzzle.rotation = aim_dir.angle()
		_muzzle.scale = Vector2.ONE * [0.9, 1.3, 0.7][frame]
	else:
		_muzzle.visible = false


func _spawn_pellet() -> void:
	if Game.pool == null:
		return
	var pos := global_position + CHEST + aim_dir * WEAPON.muzzle_distance
	Game.pool.spawn_player_pellet(pos, aim_dir * WEAPON.pellet_speed, WEAPON.damage)


func _update_invuln(delta: float) -> void:
	if _invuln > 0.0:
		_invuln -= delta
		visual.visible = _invuln <= 0.0 or int(_invuln * TUNING.blink_hz * 2.0) % 2 == 0
	else:
		visual.visible = true


func _on_hurt(damage: int, _source: Node) -> bool:
	if not alive or _invuln > 0.0 or Game.god_mode:
		return false  # Geschosse fliegen durch, Kontakt zählt nicht
	_apply_damage(damage)
	return true


func _apply_damage(damage: int) -> void:
	hp = maxi(hp - damage, 0)
	Events.player_hp_changed.emit(hp)
	AudioDirector.play_sfx(&"pete_hit")
	_haptic()
	Game.hit_stop(3)
	if hp == 0:
		_die()
	else:
		_invuln = TUNING.invuln_time


## Sturz in Tinte/Abgrund: 1 HP und Respawn am Abschnittsanfang.
func _fall_out() -> void:
	velocity = Vector2.ZERO
	global_position = Game.level.get_respawn_point(global_position.x)
	if Game.god_mode:
		return
	_apply_damage(1)


func _die() -> void:
	alive = false
	controls_enabled = false
	_invuln = 0.0
	_muzzle.visible = false
	visual.visible = true
	visual.modulate = Color(1, 1, 1, 0.55)
	velocity = Vector2(0, -500)
	Events.player_died.emit()


func _squash(s: Vector2) -> void:
	_body_visual.scale = s
	var tw := create_tween()
	tw.tween_property(_body_visual, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _haptic() -> void:
	if SaveData.haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(15)
