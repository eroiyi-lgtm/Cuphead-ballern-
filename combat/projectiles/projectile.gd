class_name Projectile
extends Area2D
## Gepooltes Geschoss. Inaktiv = PROCESS_MODE_DISABLED: aus dem Physik-Raum entfernt, kostet nichts.

var velocity := Vector2.ZERO
var fall_gravity := 0.0
var damage := 1
var life := 0.0
var collide_world := false
var orient := false
var active := false
var splat_color := Palette.INK
var radius := 10.0
var homing_time := 0.0   ## Sekunden, in denen das Geschoss Pete nachsteuert
var homing_turn := 0.0   ## max. Drehung in rad/s

var _shape := CircleShape2D.new()
var _outer := Polygon2D.new()
var _core := Polygon2D.new()


func _init() -> void:
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	cs.shape = _shape
	add_child(cs)
	add_child(_outer)
	add_child(_core)
	add_to_group(&"debug_shapes")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


## opts: radius, gravity, life, collide_world, shape ("pellet"|"drop"|"feather"|"wave"|"plane"),
## color, core, homing_time, homing_turn
func fire(pos: Vector2, vel: Vector2, dmg: int, target_mask: int, opts: Dictionary) -> void:
	position = pos
	velocity = vel
	damage = dmg
	fall_gravity = opts.get("gravity", 0.0)
	life = opts.get("life", 2.5)
	collide_world = opts.get("collide_world", false)
	radius = opts.get("radius", 10.0)
	_shape.radius = radius
	homing_time = opts.get("homing_time", 0.0)
	homing_turn = opts.get("homing_turn", 0.0)
	collision_layer = 0
	collision_mask = target_mask | (Layers.WORLD if collide_world else 0)
	var shape: String = opts.get("shape", "drop")
	orient = shape == "pellet" or shape == "feather" or shape == "drop" or shape == "plane"
	var color: Color = opts.get("color", Palette.DANGER)
	splat_color = color
	_outer.color = color
	_core.color = opts.get("core", Palette.DANGER_CORE)
	_outer.polygon = _outline(shape, radius)
	_core.polygon = _outline(shape, radius * 0.45)
	rotation = velocity.angle() if orient else 0.0
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(delta: float) -> void:
	if not active:
		return
	velocity.y += fall_gravity * delta
	if homing_time > 0.0 and Game.player:
		homing_time -= delta
		var to_pete: Vector2 = Game.player.global_position + Vector2(0, -50) - global_position
		var diff := wrapf(to_pete.angle() - velocity.angle(), -PI, PI)
		velocity = velocity.rotated(clampf(diff, -homing_turn * delta, homing_turn * delta))
	position += velocity * delta
	if orient:
		rotation = velocity.angle()
	life -= delta
	if life <= 0.0:
		deactivate()
		return
	for area in get_overlapping_areas():
		if area is Hurtbox and (area as Hurtbox).take_hit(damage, self):
			_impact()
			return
	if collide_world and has_overlapping_bodies():
		_impact()
		return
	var cam := Game.camera
	if cam:
		var c := cam.get_screen_center_position()
		if absf(position.x - c.x) > 1800.0 or position.y > c.y + 900.0 or position.y < c.y - 1400.0:
			deactivate()


func _impact() -> void:
	if Game.pool:
		Game.pool.spawn_splat(global_position, splat_color, radius)
	deactivate()


static func _outline(shape: String, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"pellet":  # Tintentropfen, Spitze in Flugrichtung
			for i in 12:
				var a := TAU * i / 12.0
				var stretch := 1.8 if cos(a) > 0.0 else 1.0
				pts.append(Vector2(cos(a) * r * stretch, sin(a) * r * 0.8))
		"feather":  # langer Federkiel
			pts = PackedVector2Array([Vector2(r * 2.2, 0), Vector2(0, r * 0.7), Vector2(-r * 2.2, 0), Vector2(0, -r * 0.7)])
		"plane":  # Papierflieger
			pts = PackedVector2Array([Vector2(r * 1.8, 0), Vector2(-r * 1.2, r * 0.9), Vector2(-r * 0.6, 0), Vector2(-r * 1.2, -r * 0.9)])
		"wave":  # Bodenwelle, halbe Ellipse
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(Vector2(cos(a) * r * 1.4, sin(a) * r * 1.2 + r))
		_:  # Tropfen
			for i in 14:
				var a := TAU * i / 14.0
				var tail := 1.5 if cos(a) < -0.6 else 1.0
				pts.append(Vector2(cos(a) * r * tail, sin(a) * r))
	return pts
