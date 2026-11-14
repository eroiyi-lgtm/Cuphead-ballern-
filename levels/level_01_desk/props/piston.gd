class_name Piston
extends AnimatableBody2D
## Kolben (Segment C): Plattform fährt zwischen base_y und base_y - travel auf und ab.

var base_y := 900.0
var travel := 140.0
var period := 2.0
var _t := 0.0
var _rod: Polygon2D


func setup(x: float, floor_y: float, h: float, p: float) -> Piston:
	position = Vector2(x, floor_y)
	base_y = floor_y
	travel = h
	period = p
	return self


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	sync_to_physics = true
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(160, 30)
	cs.shape = shape
	cs.position = Vector2(0, 15)
	add_child(cs)
	_rod = Polygon2D.new()
	_rod.polygon = PackedVector2Array([Vector2(-18, 30), Vector2(18, 30), Vector2(18, 400), Vector2(-18, 400)])
	_rod.color = Color("8f969c")
	add_child(_rod)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([Vector2(-80, 0), Vector2(80, 0), Vector2(80, 30), Vector2(-80, 30)])
	head.color = Palette.BOSS_GOLD.darkened(0.15)
	add_child(head)


func reset() -> void:
	_t = 0.0
	position.y = base_y


func _physics_process(delta: float) -> void:
	_t += delta
	position.y = base_y - travel * (0.5 - 0.5 * cos(_t * TAU / period))
