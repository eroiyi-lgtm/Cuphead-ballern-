extends BossPattern
## Klecks-Spirale: 2 Arme aus Tropfen drehen mit 90°/s, 1,5 Umdrehungen.
## Ausweichen: in die Lücken laufen, den Rhythmus lesen.

var _t := 0.0
var _emit := 0.0
var _angle := 0.0


func activate() -> void:
	_t = 0.0
	_emit = 0.0
	_angle = Game.rng.randf() * TAU


func tick(delta: float) -> void:
	var s := speed()
	_t += delta
	_angle += deg_to_rad(float(param("deg_per_s", 90.0))) * delta * s
	_emit -= delta * s
	if _emit > 0.0:
		return
	_emit = float(param("interval", 0.16))
	var arms := int(param("arms", 2))
	var origin: Vector2 = boss.spiral_origin()
	for i in arms:
		var dir := Vector2.from_angle(_angle + TAU * i / arms)
		Game.pool.spawn_enemy(origin + dir * 60.0, dir * float(param("drop_speed", 360.0)) * s, {
			"radius": 16.0, "shape": "drop", "life": 4.5,
		})
