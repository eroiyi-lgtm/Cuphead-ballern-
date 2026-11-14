extends BossPattern
## Tintenwelle: Das Fass blubbert 1,0 s, der Pegel steigt sichtbar, dann läuft die Welle 1,5 s
## über den ganzen Boden. Rettung: auf die schwebenden Bücher.

var _ink: Polygon2D
var _hitbox: Hitbox
var _holder: Node2D
var _height := 0.0


func _ready() -> void:
	_holder = Node2D.new()
	_holder.top_level = true
	_holder.z_index = 2
	add_child(_holder)
	_ink = Polygon2D.new()
	_ink.color = Palette.DANGER
	_ink.visible = false
	_holder.add_child(_ink)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1, 1)
	_hitbox = Hitbox.create(_holder, Layers.PETE_HURTBOX, shape, Vector2.ZERO, 1)
	_hitbox.enabled = false


func telegraph(windup: float) -> void:
	_ink.visible = true
	_set_height(0.0)
	var tw := create_tween()
	tw.tween_method(_set_height, 0.0, float(param("warn_height", 18.0)), windup)


func activate() -> void:
	var h: float = param("wave_height", 70.0)
	var tw := create_tween()
	tw.tween_method(_set_height, _height, h, 0.15)
	var shape := _hitbox.shape_node.shape as RectangleShape2D
	shape.size = Vector2(play_right() - arena().position.x, h)
	_hitbox.shape_node.position = Vector2((arena().position.x + play_right()) * 0.5, arena().end.y - h * 0.5)
	_hitbox.enabled = true
	Game.shake(6.0, 0.4)


func deactivate() -> void:
	_hitbox.enabled = false
	var tw := create_tween()
	tw.tween_method(_set_height, _height, 0.0, 0.3)
	tw.tween_callback(_ink.hide)


func cancel() -> void:
	_hitbox.enabled = false
	_ink.visible = false


func _set_height(h: float) -> void:
	_height = h
	var l := arena().position.x
	var r := play_right() + 400.0
	var y := arena().end.y
	_ink.polygon = PackedVector2Array([Vector2(l, y - h), Vector2(r, y - h), Vector2(r, y + 4), Vector2(l, y + 4)])
