extends BossPattern
## Tintenspucke: 3 Tropfen in Bögen, Einschläge im Abstand von 180 px um Petes Position.
## Sicherer Platz: zwischen zwei Einschlägen stehen.

var _queue: Array[Dictionary] = []
var _t := 0.0


func activate() -> void:
	_queue.clear()
	_t = 0.0
	var offsets: Array = param("offsets", [-180.0, 0.0, 180.0])
	var stagger: float = param("stagger", 0.12)
	var px := pete_x()
	for i in offsets.size():
		var x := clampf(px + float(offsets[i]), arena().position.x + 40.0, play_right() - 40.0)
		_queue.append({"at": i * stagger, "x": x})


func tick(delta: float) -> void:
	_t += delta * speed()
	while not _queue.is_empty() and float(_queue[0]["at"]) <= _t:
		_spit(float(_queue.pop_front()["x"]))


func cancel() -> void:
	_queue.clear()


func _spit(target_x: float) -> void:
	var from: Vector2 = boss.mouth_position()
	var g: float = param("gravity", 1400.0)
	var flight: float = float(param("flight_time", 1.0)) / speed()
	var target_y := arena().end.y - 18.0
	var v := Vector2((target_x - from.x) / flight, (target_y - from.y - 0.5 * g * flight * flight) / flight)
	Game.pool.spawn_enemy(from, v, {
		"radius": 22.0, "gravity": g, "collide_world": true, "life": 3.0, "shape": "drop",
	})
