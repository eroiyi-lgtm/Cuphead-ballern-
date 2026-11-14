extends BossPattern
## Federstoß: Schatten in einer von 3 Bahnen (1,0 s), dann schlägt die Feder in diese Bahn.
## Ausweichen: Bahn wechseln. Ziel ist immer Petes Bahn.

var _shadow: Polygon2D
var _quill: Polygon2D
var _hitbox: Hitbox
var _holder: Node2D
var _lane := Rect2()
var _t := 0.0
var _hit := false


func _ready() -> void:
	_holder = Node2D.new()
	_holder.top_level = true
	_holder.z_index = 3
	add_child(_holder)
	_shadow = Polygon2D.new()
	_shadow.color = Color(Palette.INK, 0.35)
	_shadow.visible = false
	_holder.add_child(_shadow)
	_quill = Polygon2D.new()
	_quill.color = Color.WHITE
	_quill.visible = false
	_holder.add_child(_quill)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1, 1)
	_hitbox = Hitbox.create(_holder, Layers.PETE_HURTBOX, shape, Vector2.ZERO, 1)
	_hitbox.enabled = false


func telegraph(_windup: float) -> void:
	var left := arena().position.x
	var w := (play_right() - left) / 3.0
	var lane := clampi(int((pete_x() - left) / w), 0, 2)
	_lane = Rect2(left + lane * w + 15.0, arena().position.y, w - 30.0, arena().size.y)
	_shadow.polygon = _rect_pts(_lane)
	_shadow.visible = true
	_quill.visible = false


func activate() -> void:
	_t = 0.0
	_hit = false
	_quill.visible = true
	_quill.polygon = _quill_pts(-arena().size.y)


func tick(delta: float) -> void:
	_t += delta * speed()
	var drop: float = param("drop_time", 0.1)
	if not _hit:
		_quill.polygon = _quill_pts(lerpf(-arena().size.y, 0.0, clampf(_t / drop, 0.0, 1.0)))
		if _t >= drop:
			_hit = true
			var shape := _hitbox.shape_node.shape as RectangleShape2D
			shape.size = _lane.size
			_hitbox.shape_node.position = _lane.get_center()
			_hitbox.enabled = true
			Game.shake(16.0, 0.3)
			AudioDirector.play_sfx(&"thunk")
	elif _t >= drop + float(param("hit_window", 0.35)):
		_hitbox.enabled = false


func deactivate() -> void:
	cancel()


func cancel() -> void:
	_hitbox.enabled = false
	_shadow.visible = false
	_quill.visible = false


func _quill_pts(offset_y: float) -> PackedVector2Array:
	var cx := _lane.get_center().x
	var bottom := _lane.end.y + offset_y
	var half := _lane.size.x * 0.32
	return PackedVector2Array([Vector2(cx, bottom), Vector2(cx + half, bottom - 260.0), Vector2(cx + half * 0.6, bottom - _lane.size.y - 200.0), Vector2(cx - half * 0.6, bottom - _lane.size.y - 200.0), Vector2(cx - half, bottom - 260.0)])


static func _rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
