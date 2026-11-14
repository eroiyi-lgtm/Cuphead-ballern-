extends BossPattern
## Papierflieger-Staffel: 5 Flieger, 1,2 s zielsuchend, dann geradeaus.
## Ausweichen: Flieger hinter sich herziehen und seitlich wegspringen.

var _queue: Array[float] = []
var _t := 0.0


func activate() -> void:
	_t = 0.0
	_queue.clear()
	for i in int(param("count", 5)):
		_queue.append(i * float(param("stagger", 0.18)))


func tick(delta: float) -> void:
	_t += delta * speed()
	while not _queue.is_empty() and _queue[0] <= _t:
		_queue.pop_front()
		_launch()


func cancel() -> void:
	_queue.clear()


func _launch() -> void:
	var from: Vector2 = boss.mouth_position()
	var spread := Game.rng.randf_range(-0.5, 0.2)
	var v := Vector2.LEFT.rotated(spread) * float(param("speed", 520.0)) * speed()
	Game.pool.spawn_enemy(from, v, {
		"radius": 18.0, "shape": "plane", "life": 5.0,
		"homing_time": float(param("homing_time", 1.2)), "homing_turn": float(param("homing_turn", 2.4)),
		"color": Palette.PAPER.darkened(0.15), "core": Palette.DANGER,
	})
