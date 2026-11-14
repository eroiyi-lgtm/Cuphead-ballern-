extends BossPattern
## Federkiel-Erlass: 4 Federn fallen auf Stellen, die schon während des Telegraphs als Schatten
## markiert sind. Eine Feder zielt auf Petes Spalte, direkt daneben bleibt immer eine Spalte frei.

var _shadows: Array[Polygon2D] = []
var _xs: Array[float] = []


func _ready() -> void:
	for i in int(param("count", 4)):
		_shadows.append(make_shadow(float(param("shadow_width", 120.0))))


func telegraph(windup: float) -> void:
	_xs = _pick_columns()
	var floor_y := arena().end.y
	for i in _shadows.size():
		var s := _shadows[i]
		s.visible = i < _xs.size()
		if not s.visible:
			continue
		s.global_position = Vector2(_xs[i], floor_y)
		s.scale = Vector2(0.3, 0.3)
		s.create_tween().tween_property(s, "scale", Vector2.ONE, windup)


func activate() -> void:
	var fall: float = float(param("fall_speed", 950.0)) * speed()
	for x in _xs:
		Game.pool.spawn_enemy(Vector2(x, arena().position.y - 60.0), Vector2(0, fall), {
			"radius": 24.0, "collide_world": true, "life": 3.0, "shape": "feather",
		})


func deactivate() -> void:
	for s in _shadows:
		s.visible = false


func _pick_columns() -> Array[float]:
	var left := arena().position.x + 60.0
	var col_w: float = param("column_width", 200.0)
	var n := int((play_right() - left) / col_w)
	var pete_col := clampi(int((pete_x() - left) / col_w), 0, n - 1)
	var chosen: Array[int] = [pete_col]
	var candidates: Array[int] = []
	for c in n:
		if absi(c - pete_col) >= 2:
			candidates.append(c)
	# reproduzierbar über Game.rng (Pattern-Seed)
	for i in range(candidates.size() - 1, 0, -1):
		var j := Game.rng.randi_range(0, i)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	for c in candidates:
		if chosen.size() >= _shadows.size():
			break
		var ok := true
		for k in chosen:
			if absi(c - k) < 2:
				ok = false
		if ok:
			chosen.append(c)
	var xs: Array[float] = []
	for c in chosen:
		xs.append(left + (c + 0.5) * col_w)
	return xs
