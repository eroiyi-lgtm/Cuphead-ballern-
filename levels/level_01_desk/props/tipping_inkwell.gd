class_name TippingInkwell
extends Node2D
## Kippendes Tintenfass (Segment D): alle 2,5 s kippt es und flutet den Boden darunter.
## Ablauf: Ruhe 1,0 s → Vorwarnung 0,6 s (Kippen + Gurgeln + Tropfen) → Flut 0,9 s.
## Sicherer Platz: der Federhalter-Steg darüber.

const IDLE := 1.0
const WARN := 0.6
const FLOOD := 0.9
const ACTIVE_RANGE := 1500.0

var flood_rect := Rect2()
var _t := 0.0
var _phase := 0
var _well: Node2D
var _flood: Polygon2D
var _hitbox: Hitbox


func setup(well_pos: Vector2, flood: Rect2) -> TippingInkwell:
	flood_rect = flood
	_well_pos = well_pos
	return self


var _well_pos := Vector2.ZERO


func _ready() -> void:
	_well = Node2D.new()
	_well.position = _well_pos
	add_child(_well)
	var glass := Polygon2D.new()
	glass.polygon = PackedVector2Array([Vector2(-60, 0), Vector2(60, 0), Vector2(50, -110), Vector2(-50, -110)])
	glass.color = Palette.INK
	_well.add_child(glass)
	var label := Polygon2D.new()
	label.polygon = PackedVector2Array([Vector2(-52, -40), Vector2(52, -40), Vector2(50, -70), Vector2(-50, -70)])
	label.color = Palette.BOSS_GOLD
	_well.add_child(label)
	_flood = Polygon2D.new()
	_flood.polygon = PackedVector2Array([flood_rect.position, Vector2(flood_rect.end.x, flood_rect.position.y), flood_rect.end, Vector2(flood_rect.position.x, flood_rect.end.y)])
	_flood.color = Color(Palette.DANGER, 0.9)
	_flood.visible = false
	_flood.z_index = 1
	add_child(_flood)
	var shape := RectangleShape2D.new()
	shape.size = flood_rect.size
	_hitbox = Hitbox.create(self, Layers.PETE_HURTBOX, shape, flood_rect.get_center(), 1)
	_hitbox.enabled = false
	reset()


func reset() -> void:
	_t = 0.0
	_phase = 0
	_well.rotation = 0.0
	_flood.visible = false
	_hitbox.enabled = false


func is_flooding() -> bool:
	return _phase == 2


func _physics_process(delta: float) -> void:
	var near := Game.player != null and absf(Game.player.global_position.x - flood_rect.get_center().x) < ACTIVE_RANGE
	if not near and _phase == 0:
		return
	_t += delta
	match _phase:
		0:
			if _t >= IDLE:
				_t = 0.0
				_phase = 1
				AudioDirector.play_sfx(&"boss_gurgle")
				create_tween().tween_property(_well, "rotation", -0.6, WARN).set_trans(Tween.TRANS_BACK)
		1:
			_flood.visible = true
			_flood.modulate.a = 0.25 + 0.2 * sin(_t * 30.0)  # Tropfen-Vorwarnung
			if _t >= WARN:
				_t = 0.0
				_phase = 2
				_flood.modulate.a = 1.0
				_hitbox.enabled = true
		2:
			if _t >= FLOOD:
				_t = 0.0
				_phase = 0
				_flood.visible = false
				_hitbox.enabled = false
				create_tween().tween_property(_well, "rotation", 0.0, 0.3)
