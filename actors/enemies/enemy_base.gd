class_name EnemyBase
extends CharacterBody2D
## Gemeinsame Basis für Minions: HP, Hurtbox, Kontakt-Hitbox, Treffer-Blitz, Tinten-Tod, Aufwachen.

signal died(enemy: EnemyBase)

const ACTOR_FX := preload("res://fx/shaders/actor_fx.gdshader")
const WAKE_DISTANCE := 1150.0

var hp := 1
var dead := false
var awake := false
var visual: Node2D
var hurtbox: Hurtbox
var contact: Hitbox

var _flash_frames := 0
var _fx: ShaderMaterial


func _setup_combat(hurt_shape: Shape2D, hurt_offset: Vector2, contact_shape: Shape2D, contact_offset: Vector2, contact_damage: int) -> void:
	hurtbox = Hurtbox.create(self, Layers.ENEMY_HURTBOX, hurt_shape, hurt_offset, _on_hurt)
	contact = Hitbox.create(self, Layers.PETE_HURTBOX, contact_shape, contact_offset, contact_damage)
	contact.landed.connect(_on_contact_landed)
	_fx = ShaderMaterial.new()
	_fx.shader = ACTOR_FX
	visual.material = _fx


func _tick_common() -> void:
	if _flash_frames > 0:
		_flash_frames -= 1
		if _flash_frames == 0:
			_fx.set_shader_parameter(&"flash_amount", 0.0)
	if not awake and Game.camera:
		awake = absf(global_position.x - Game.camera.get_screen_center_position().x) < WAKE_DISTANCE


func _on_hurt(damage: int, _source: Node) -> bool:
	if dead:
		return false
	hp -= damage
	_flash_frames = 2
	_fx.set_shader_parameter(&"flash_amount", 1.0)
	AudioDirector.play_sfx(&"enemy_hit")
	if hp <= 0:
		die()
	return true


func _on_contact_landed(_target: Hurtbox) -> void:
	pass


func die() -> void:
	if dead:
		return
	dead = true
	hurtbox.active = false
	contact.enabled = false
	collision_mask = 0
	velocity = Vector2.ZERO
	died.emit(self)
	AudioDirector.play_sfx(&"pop")
	if Game.pool:
		Game.pool.spawn_splat(global_position + Vector2(0, -30), Palette.INK, 30.0)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _fx.set_shader_parameter(&"dissolve", v), 0.0, 1.0, 0.35)
	tw.tween_callback(queue_free)


static func ellipse(center: Vector2, radii: Vector2, c: Color, points := 18) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in points:
		var a := TAU * i / points
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = c
	p.use_parent_material = true
	return p


static func poly(pts: Array, c: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = c
	p.use_parent_material = true
	return p
