class_name PencilSprite
extends EnemyBase
## Pencil-Sprite: schwebt oben, zielt 0,6 s (Spitze glimmt rot, Spitzer-Geräusch),
## stößt im 45°-Winkel herab, steckt 1 s im Holz fest, steigt wieder auf.
## Die Schwebeposition liegt immer auf der 45°-Linie zu Pete: der Sturz ist vorhersehbar.

const T: PencilTuning = preload("res://data/enemies/pencil_sprite.tres")

enum S { HOVER, AIM, DIVE, STUCK, RISE }

var _state := S.HOVER
var _t := 0.0
var _home_y := 0.0
var _home_x := 0.0
const LEASH := 700.0  ## Revier um den Spawnpunkt, kein Verfolgen durchs ganze Level
var _dir := Vector2.DOWN
var _tip: Polygon2D
var _bob := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 10.0
	cs.shape = c
	cs.position = Vector2(0, 44)
	add_child(cs)

	visual = get_node_or_null(^"Visual")
	if visual == null:
		visual = Node2D.new()
		visual.name = "Visual"
		for side in [-1.0, 1.0]:
			var wing := EnemyBase.sprite(preload("res://art/enemies/wing.svg"), Vector2(14, 0))
			wing.position = Vector2(side * 10.0, -14.0)
			wing.scale.x *= side
			visual.add_child(wing)
			var flap := wing.create_tween().set_loops()
			flap.tween_property(wing, "rotation", -0.5 * side, 0.08)
			flap.tween_property(wing, "rotation", 0.3 * side, 0.08)
		visual.add_child(EnemyBase.sprite(preload("res://art/enemies/pencil.svg"), Vector2.ZERO))
		_tip = EnemyBase.poly([Vector2(-4, 36), Vector2(4, 36), Vector2(0, 48)], Palette.INK)
		visual.add_child(_tip)
		add_child(visual)
	hp = T.hp
	var hurt := RectangleShape2D.new()
	hurt.size = Vector2(34, 96)
	var touch := RectangleShape2D.new()
	touch.size = Vector2(22, 84)
	_setup_combat(hurt, Vector2(0, 0), touch, Vector2(0, 4), T.contact_damage)
	_home_y = global_position.y
	_home_x = global_position.x
	_t = T.hover_time


func _physics_process(delta: float) -> void:
	_tick_common()
	if dead or not awake or Game.player == null:
		return
	var pete_pos: Vector2 = Game.player.global_position + Vector2(0, -40)
	match _state:
		S.HOVER:
			var side := signf(global_position.x - pete_pos.x)
			if side == 0.0:
				side = 1.0
			var target_x := pete_pos.x + side * maxf(pete_pos.y - _home_y, 120.0)
			if Game.camera:  # im Bild bleiben, sonst kommt der Sturz aus dem Off
				var cx := Game.camera.get_screen_center_position().x
				target_x = clampf(target_x, cx - 860.0, cx + 860.0)
			target_x = clampf(target_x, _home_x - LEASH, _home_x + LEASH)
			_bob += delta
			global_position.x = move_toward(global_position.x, target_x, T.hover_speed * delta)
			global_position.y = _home_y + sin(_bob * 5.0) * 8.0
			rotation = lerp_angle(rotation, 0.0, 0.2)
			_t -= delta
			if _t <= 0.0:
				_state = S.AIM
				_t = T.aim_time
				_dir = Vector2(signf(pete_pos.x - global_position.x), 1.0).normalized()
				AudioDirector.play_sfx(&"pencil_sharpen")
		S.AIM:
			_t -= delta
			rotation = lerp_angle(rotation, _dir.angle() - PI / 2.0, 0.25)
			_tip.color = Palette.INK.lerp(Palette.HERO, 0.5 + 0.5 * sin(_t * 40.0))
			if _t <= 0.0:
				_state = S.DIVE
				_tip.color = Palette.HERO
		S.DIVE:
			rotation = _dir.angle() - PI / 2.0
			var col := move_and_collide(_dir * T.dive_speed * delta)
			if col:
				_state = S.STUCK
				_t = T.stuck_time
				AudioDirector.play_sfx(&"thunk")
				Game.shake(4.0, 0.12)
			elif Game.level and global_position.y > Game.level.kill_y:
				die()
		S.STUCK:
			_t -= delta
			if _t <= 0.0:
				_state = S.RISE
				_tip.color = Palette.INK
		S.RISE:
			global_position.y -= T.rise_speed * delta
			rotation = lerp_angle(rotation, 0.0, 0.1)
			if global_position.y <= _home_y:
				global_position.y = _home_y
				_state = S.HOVER
				_t = T.hover_time
