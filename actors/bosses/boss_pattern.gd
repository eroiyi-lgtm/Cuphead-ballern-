class_name BossPattern
extends Node
## Basis für ein Angriffsmuster. Wird einmal pro Boss angelegt und wiederverwendet.
## telegraph() zeigt Vorwarnungen, activate()/tick() erzeugen Gefahr, deactivate() räumt auf.

var attack: BossAttack
var boss: Node2D          ## SirReginald (oder ein anderer Boss mit arena, mouth_position())
var brain: BossBrain


func telegraph(_windup: float) -> void:
	pass


func activate() -> void:
	pass


func tick(_delta: float) -> void:
	pass


func deactivate() -> void:
	pass


## Phase endet mitten im Muster: alles Sichtbare sofort weg.
func cancel() -> void:
	deactivate()


func reset() -> void:
	cancel()


func speed() -> float:
	return brain.speed_mult()


func param(key: String, fallback: Variant) -> Variant:
	return attack.params.get(key, fallback)


func pete_x() -> float:
	return Game.player.global_position.x if Game.player else boss.global_position.x - 600.0


func arena() -> Rect2:
	return boss.arena


## Rechte Grenze der Spielfläche vor dem Boss.
func play_right() -> float:
	return boss.play_right


func make_shadow(width: float) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * width * 0.5, sin(a) * 10.0))
	var s := Polygon2D.new()
	s.polygon = pts
	s.color = Color(Palette.INK, 0.55)
	s.top_level = true
	s.z_index = 2
	s.visible = false
	add_child(s)
	return s
