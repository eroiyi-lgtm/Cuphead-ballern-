extends BossPattern
## Siegelstempel: Schatten auf Petes x-Position, Stempel schlägt ein, Bodenwelle läuft in beide
## Richtungen. Ausweichen: aus dem Schatten laufen und über die Welle springen.

var _shadow: Polygon2D
var _stamp: Node2D
var _hitbox: Hitbox
var _x := 0.0
var _t := 0.0
var _impacted := false


func _ready() -> void:
	_shadow = make_shadow(170.0)
	_stamp = Node2D.new()
	_stamp.top_level = true
	_stamp.z_index = 3
	_stamp.visible = false
	add_child(_stamp)
	var gold := Polygon2D.new()
	gold.polygon = PackedVector2Array([Vector2(-80, -150), Vector2(80, -150), Vector2(80, 0), Vector2(-80, 0)])
	gold.color = Palette.BOSS_GOLD
	_stamp.add_child(gold)
	var wax := Polygon2D.new()
	wax.polygon = PackedVector2Array([Vector2(-40, -60), Vector2(40, -60), Vector2(40, -20), Vector2(-40, -20)])
	wax.color = Palette.HERO.darkened(0.3)
	_stamp.add_child(wax)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(150, 140)
	_hitbox = Hitbox.create(_stamp, Layers.PETE_HURTBOX, shape, Vector2(0, -70), 1)
	_hitbox.enabled = false


func telegraph(windup: float) -> void:
	_x = clampf(pete_x(), arena().position.x + 100.0, play_right() - 100.0)
	_shadow.global_position = Vector2(_x, arena().end.y)
	_shadow.scale = Vector2(0.4, 0.4)
	_shadow.visible = true
	_shadow.create_tween().tween_property(_shadow, "scale", Vector2.ONE, windup)
	_stamp.global_position = Vector2(_x, arena().position.y - 40.0)
	_stamp.visible = true


func activate() -> void:
	_t = 0.0
	_impacted = false


func tick(delta: float) -> void:
	_t += delta * speed()
	var drop_time: float = param("drop_time", 0.12)
	var floor_y := arena().end.y
	if not _impacted:
		_stamp.global_position.y = lerpf(arena().position.y - 40.0, floor_y, clampf(_t / drop_time, 0.0, 1.0))
		if _t >= drop_time:
			_impact(floor_y)
	elif _t >= drop_time + float(param("hit_window", 0.2)):
		_hitbox.enabled = false


func deactivate() -> void:
	_hitbox.enabled = false
	_shadow.visible = false
	if _stamp.visible:
		var tw := _stamp.create_tween()
		tw.tween_property(_stamp, "global_position:y", arena().position.y - 300.0, 0.35)
		tw.tween_callback(_stamp.hide)


func cancel() -> void:
	_hitbox.enabled = false
	_shadow.visible = false
	_stamp.visible = false


func _impact(floor_y: float) -> void:
	_impacted = true
	_hitbox.enabled = true
	Game.shake(18.0, 0.3)
	AudioDirector.play_sfx(&"boss_gong")
	var speed_px: float = float(param("wave_speed", 650.0)) * speed()
	var r: float = param("wave_radius", 30.0)
	for dir in [-1.0, 1.0]:
		Game.pool.spawn_enemy(Vector2(_x + dir * 90.0, floor_y - r), Vector2(dir * speed_px, 0), {
			"radius": r, "collide_world": false, "life": 3.5, "shape": "wave",
		})
