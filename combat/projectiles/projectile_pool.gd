class_name ProjectilePool
extends Node2D
## 48 Spieler-Pellets und 160 Gegner-Geschosse, vorab instanziert. Kein queue_free() im Kampf.
## Ist ein Pool erschöpft, wird das älteste Geschoss wiederverwendet.

const PLAYER_COUNT := 48
const ENEMY_COUNT := 160
const SPLAT_COUNT := 24

var player_shots_spawned := 0

var _player: Array[Projectile] = []
var _enemy: Array[Projectile] = []
var _splats: Array[Polygon2D] = []
var _cursor := {"p": 0, "e": 0, "s": 0}


func _ready() -> void:
	name = "Projectiles"
	z_index = 5
	Game.pool = self
	for i in PLAYER_COUNT:
		_player.append(_make())
	for i in ENEMY_COUNT:
		_enemy.append(_make())
	for i in SPLAT_COUNT:
		var s := Polygon2D.new()
		s.visible = false
		var pts := PackedVector2Array()
		for k in 16:
			var a := TAU * k / 16.0
			var r := 1.0 if k % 2 == 0 else 0.55
			pts.append(Vector2(cos(a), sin(a)) * r)
		s.polygon = pts
		add_child(s)
		_splats.append(s)
	Events.level_restarted.connect(clear_all)


func spawn_player_pellet(pos: Vector2, vel: Vector2, damage: int) -> Projectile:
	var p := _next(_player, "p")
	p.fire(pos, vel, damage, Layers.ENEMY_HURTBOX, {
		"radius": 12.0, "shape": "pellet", "life": 1.4,
		"color": Palette.INK, "core": Palette.INK_BLUE,
	})
	player_shots_spawned += 1
	return p


func spawn_enemy(pos: Vector2, vel: Vector2, opts: Dictionary) -> Projectile:
	var p := _next(_enemy, "e")
	p.fire(pos, vel, opts.get("damage", 1), Layers.PETE_HURTBOX, opts)
	return p


func spawn_splat(pos: Vector2, color: Color, size: float) -> void:
	var idx: int = _cursor["s"]
	_cursor["s"] = (idx + 1) % _splats.size()
	var s := _splats[idx]
	s.position = pos
	s.color = color
	s.rotation = randf() * TAU
	s.scale = Vector2.ONE * size * 0.6
	s.modulate.a = 1.0
	s.visible = true
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2.ONE * size * 2.0, 0.18)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.25)
	tw.tween_callback(s.hide)


func clear_all() -> void:
	for p in _player:
		p.deactivate()
	for p in _enemy:
		p.deactivate()
	for s in _splats:
		s.visible = false


func active_count(enemy := true) -> int:
	var n := 0
	for p in (_enemy if enemy else _player):
		if p.active:
			n += 1
	return n


func _make() -> Projectile:
	var p := Projectile.new()
	add_child(p)
	return p


func _next(arr: Array[Projectile], key: String) -> Projectile:
	var start: int = _cursor[key]
	for i in arr.size():
		var idx := (start + i) % arr.size()
		if not arr[idx].active:
			_cursor[key] = (idx + 1) % arr.size()
			return arr[idx]
	_cursor[key] = (start + 1) % arr.size()
	return arr[start]
