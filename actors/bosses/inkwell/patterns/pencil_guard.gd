extends BossPattern
## Bleistift-Garde: Pfiff, 2 Pencil-Sprites salutieren und greifen an. Höchstens 4 gleichzeitig.
## Risikoentscheidung für den Spieler: erst die Minions oder weiter auf den Boss.

var _guards: Array[Node] = []


func activate() -> void:
	if Game.level == null:
		return
	var alive: Array[Node] = []
	for g in _guards:
		if is_instance_valid(g) and not g.dead:
			alive.append(g)
	_guards = alive
	var max_alive := int(param("max_alive", 4))
	for i in int(param("count", 2)):
		if _guards.size() >= max_alive:
			return
		var x := lerpf(arena().position.x + 300.0, play_right() - 200.0, 0.35 + 0.3 * i)
		_guards.append(Game.level.spawn_pencil(Vector2(x, float(param("hover_y", 300.0)))))


func reset() -> void:
	_guards.clear()
