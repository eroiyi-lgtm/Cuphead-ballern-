class_name ZoneLayer
extends Parallax2D
## Kulissen-Ebene, die nur in ihrem Abschnitt sichtbar ist und an den Rändern weich überblendet.
## So hat jedes Segment eigene Hintergrund-Motive, obwohl ferne Ebenen sich kaum bewegen.

const FADE := 500.0

var zone_from := -INF
var zone_to := INF


func _process(_delta: float) -> void:
	if Game.camera == null:
		return
	var x := Game.camera.get_screen_center_position().x
	var a := clampf((x - zone_from) / FADE + 0.5, 0.0, 1.0) * clampf((zone_to - x) / FADE + 0.5, 0.0, 1.0)
	modulate.a = a
	visible = a > 0.01
