class_name InkBlob
extends EnemyBase
## Ink-Blob Spark: hüpft in 3er-Serien auf Pete zu, quetscht sich 0,35 s vor jedem Sprung
## (Telegraph + Quietschen), platzt bei Berührung.

const T: InkBlobTuning = preload("res://data/enemies/ink_blob.tres")

enum S { REST, SQUASH, AIR }

var _state := S.REST
var _t := 0.0
var _hops := 0
var _body: Node2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 26.0
	cs.shape = c
	cs.position = Vector2(0, -26)
	add_child(cs)

	visual = get_node_or_null(^"Visual")
	if visual == null:
		visual = Node2D.new()
		visual.name = "Visual"
		_body = Node2D.new()
		visual.add_child(_body)
		_body.add_child(EnemyBase.ellipse(Vector2(0, -30), Vector2(32, 30), Palette.INK))
		_body.add_child(EnemyBase.ellipse(Vector2(-10, -38), Vector2(7, 9), Palette.PAPER))
		_body.add_child(EnemyBase.ellipse(Vector2(10, -38), Vector2(7, 9), Palette.PAPER))
		_body.add_child(EnemyBase.ellipse(Vector2(-9, -36), Vector2(3, 5), Palette.INK))
		_body.add_child(EnemyBase.ellipse(Vector2(11, -36), Vector2(3, 5), Palette.INK))
		_body.add_child(EnemyBase.poly([Vector2(-4, -60), Vector2(4, -74), Vector2(6, -58)], Palette.DANGER))
		add_child(visual)
	else:
		_body = visual
	hp = T.hp
	var hurt := CircleShape2D.new()
	hurt.radius = 30.0
	var touch := CircleShape2D.new()
	touch.radius = 22.0
	_setup_combat(hurt, Vector2(0, -30), touch, Vector2(0, -28), T.contact_damage)
	_t = T.rest_time * 0.5


## Aus einem Zahnrad geschleudert (Segment C).
func launch(v: Vector2) -> void:
	velocity = v
	_state = S.AIR
	awake = true


func _physics_process(delta: float) -> void:
	_tick_common()
	if dead or not awake:
		return
	if Game.level and global_position.y > Game.level.kill_y:
		die()
		return
	velocity.y = minf(velocity.y + T.gravity * delta, 1600.0)
	match _state:
		S.REST:
			velocity.x = 0.0
			_t -= delta
			if _t <= 0.0 and is_on_floor():
				_begin_squash()
		S.SQUASH:
			velocity.x = 0.0
			_t -= delta
			if _t <= 0.0:
				_hop()
	move_and_slide()
	if _state == S.AIR and is_on_floor():
		_land()


func _begin_squash() -> void:
	_state = S.SQUASH
	_t = T.squash_time
	AudioDirector.play_sfx(&"blob_squeak")
	var tw := create_tween()
	tw.tween_property(_body, "scale", Vector2(1.3, 0.62), T.squash_time).set_ease(Tween.EASE_OUT)


func _hop() -> void:
	var dir := 1.0
	if Game.player:
		var px: float = Game.player.global_position.x
		dir = signf(px - global_position.x) if absf(px - global_position.x) > 4.0 else 1.0
	velocity = Vector2(dir * T.hop_speed_x, T.hop_velocity_y)
	_state = S.AIR
	_body.scale = Vector2(0.8, 1.25)
	create_tween().tween_property(_body, "scale", Vector2.ONE, 0.2)


func _land() -> void:
	velocity.x = 0.0
	_hops += 1
	if _hops >= T.hops_per_series:
		_hops = 0
		_state = S.REST
		_t = T.rest_time
		_body.scale = Vector2(1.15, 0.85)
		create_tween().tween_property(_body, "scale", Vector2.ONE, 0.15)
	else:
		_begin_squash()


func _on_contact_landed(_target: Hurtbox) -> void:
	die()  # platzt bei Berührung
