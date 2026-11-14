class_name Gear
extends Node2D
## Drehendes Zahnrad (Segment C). Die Zähne sind waagerechte Plattformen, die wie Gondeln
## auf dem Kreis mitlaufen; Pete wird über AnimatableBody2D mitgetragen.

var radius := 190.0
var teeth := 4
var deg_per_s := 40.0
var start_angle := 0.0

var _angle := 0.0
var _platforms: Array[AnimatableBody2D] = []
var _disk: Node2D


func setup(r: float, n: int, speed_deg: float, angle0: float) -> Gear:
	radius = r
	teeth = n
	deg_per_s = speed_deg
	start_angle = angle0
	return self


func _ready() -> void:
	_disk = Node2D.new()
	add_child(_disk)
	_disk.add_child(_circle(radius * 0.8, Palette.WALNUT.darkened(0.25), 32))
	_disk.add_child(_circle(radius * 0.18, Palette.BOSS_GOLD, 16))
	for i in teeth:
		var spoke := Polygon2D.new()
		var a := TAU * i / teeth
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x) * 10.0
		spoke.polygon = PackedVector2Array([n, d * radius * 0.8 + n, d * radius * 0.8 - n, -n])
		spoke.color = Palette.BOSS_GOLD.darkened(0.3)
		_disk.add_child(spoke)
	for i in teeth:
		var body := AnimatableBody2D.new()
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		body.sync_to_physics = true
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(150, 24)
		cs.shape = shape
		body.add_child(cs)
		var vis := Polygon2D.new()
		vis.polygon = PackedVector2Array([Vector2(-75, -12), Vector2(75, -12), Vector2(60, 12), Vector2(-60, 12)])
		vis.color = Palette.BOSS_GOLD
		body.add_child(vis)
		add_child(body)
		_platforms.append(body)
	reset()


func reset() -> void:
	_angle = deg_to_rad(start_angle)
	_place()


func _physics_process(delta: float) -> void:
	_angle += deg_to_rad(deg_per_s) * delta
	_place()


func _place() -> void:
	for i in _platforms.size():
		var a := _angle + TAU * i / _platforms.size()
		_platforms[i].position = Vector2(cos(a), sin(a)) * radius
	if _disk:
		_disk.rotation = _angle


static func _circle(r: float, c: Color, n: int) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	p.polygon = pts
	p.color = c
	return p
