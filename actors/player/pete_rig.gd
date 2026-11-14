class_name PeteRig
extends Node2D
## Pen-Pal Pete als Rubber-Hose-Rig: Kopf, Rumpf, Handschuhe und Schuhe sind Zeichnungen (art/pete/),
## Arme und Beine Tusche-Schläuche ohne Ellbogen. Bewegung läuft "on twos" (12 Posen pro Sekunde)
## wie bei handgezeichneten Cartoons. Ursprung: Füße unten Mitte, Blickrichtung rechts.

const HEAD := preload("res://art/pete/head.svg")
const TORSO := preload("res://art/pete/torso.svg")
const GLOVE := preload("res://art/pete/glove.svg")
const GLOVE_POINT := preload("res://art/pete/glove_point.svg")
const SHOE := preload("res://art/pete/shoe.svg")
const LIMB_WIDTH := 5.5
const HIP_F := Vector2(7, -36)
const HIP_B := Vector2(-7, -36)
const SHOULDER_F := Vector2(9, -68)
const SHOULDER_B := Vector2(-9, -68)

var body: Node2D
var _leg_f: Line2D
var _leg_b: Line2D
var _arm_f: Line2D
var _arm_b: Line2D
var _shoe_f: Sprite2D
var _shoe_b: Sprite2D
var _glove_b: Sprite2D
var _glove_f: Sprite2D
var _glove_gun: Sprite2D
var _torso: Sprite2D
var _head: Sprite2D
var _t := 0.0


func _init() -> void:
	name = "Visual"
	body = Node2D.new()
	body.name = "Body"
	body.use_parent_material = true
	add_child(body)
	_arm_b = _line()
	_glove_b = _sprite(GLOVE, Vector2.ZERO)
	_leg_b = _line()
	_leg_f = _line()
	_shoe_b = _sprite(SHOE, Vector2(14, 5))
	_torso = _sprite(TORSO, Vector2.ZERO)
	_torso.position = Vector2(0, -55)
	_shoe_f = _sprite(SHOE, Vector2(14, 5))
	_head = _sprite(HEAD, Vector2(0, -51))
	_arm_f = _line()
	_glove_f = _sprite(GLOVE, Vector2.ZERO)
	_glove_gun = _sprite(GLOVE_POINT, Vector2(18, -1))
	_shoe_b.modulate = Color(0.8, 0.8, 0.8)
	_glove_b.modulate = Color(0.88, 0.88, 0.88)
	animate(0.0, true, Vector2.ZERO, Vector2.RIGHT, false, false)


## Wird von Pete jeden Physik-Tick aufgerufen. aim_local ist schon in Blickrichtung gespiegelt.
func animate(delta: float, on_floor: bool, vel: Vector2, aim_local: Vector2, shooting: bool, locked: bool) -> void:
	_t += delta
	var tq := floorf(_t * 12.0) / 12.0
	var p := tq * TAU * 3.0
	var running := on_floor and absf(vel.x) > 10.0
	var foot_f: Vector2
	var foot_b: Vector2
	var bob := 0.0
	if running:
		foot_f = Vector2(7.0 + 17.0 * sin(p), -maxf(0.0, 11.0 * cos(p)))
		foot_b = Vector2(-7.0 + 17.0 * sin(p + PI), -maxf(0.0, 11.0 * cos(p + PI)))
		bob = -absf(sin(p)) * 3.0
	elif on_floor:
		foot_f = Vector2(10, 0)
		foot_b = Vector2(-10, 0)
		bob = sin(tq * TAU * 1.2) * 1.2
	elif vel.y < 0.0:
		foot_f = Vector2(14, -16)
		foot_b = Vector2(-6, -8)
	else:
		foot_f = Vector2(12, -6)
		foot_b = Vector2(-12, -12)
	var up := Vector2(0, bob)

	_limb(_leg_f, HIP_F + up, foot_f, 6.0, tq, 1.0)
	_limb(_leg_b, HIP_B + up, foot_b, 6.0, tq, 2.0)
	_shoe_f.position = foot_f
	_shoe_b.position = foot_b
	var tilt := 0.0 if on_floor else (-0.25 if vel.y < 0.0 else 0.2)
	_shoe_f.rotation = tilt
	_shoe_b.rotation = tilt
	_torso.position = Vector2(0, -55) + up
	_head.position = Vector2(0, -71) + up
	_head.rotation = -0.14 if aim_local.y < -0.5 else (0.1 if aim_local.y > 0.5 else 0.0)

	var gun := shooting or locked
	var hand_f: Vector2
	var hand_b: Vector2
	if gun:
		hand_f = SHOULDER_F + up + aim_local * 26.0
	elif running:
		hand_f = SHOULDER_F + up + Vector2(sin(p + PI) * 13.0, 22.0)
	elif not on_floor:
		hand_f = SHOULDER_F + up + Vector2(12, -16)
	else:
		hand_f = SHOULDER_F + up + Vector2(9, 24)
	if running:
		hand_b = SHOULDER_B + up + Vector2(sin(p) * 13.0, 22.0)
	elif not on_floor:
		hand_b = SHOULDER_B + up + Vector2(-14, -14)
	else:
		hand_b = SHOULDER_B + up + Vector2(-9, 24)
	_limb(_arm_f, SHOULDER_F + up, hand_f, -7.0, tq, 3.0)
	_limb(_arm_b, SHOULDER_B + up, hand_b, 7.0, tq, 4.0)
	_glove_b.position = hand_b
	_glove_f.position = hand_f
	_glove_gun.position = hand_f
	_glove_gun.rotation = aim_local.angle()
	_glove_f.visible = not gun
	_glove_gun.visible = gun


## Schlauch-Glied als Bogen; die Mitte zittert pro Zeichnung ein wenig (Boiling).
func _limb(line: Line2D, a: Vector2, b: Vector2, bend: float, tq: float, seed: float) -> void:
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var jitter := (fposmod(sin(tq * 91.7 + seed * 12.3) * 437.58, 1.0) - 0.5) * 1.6
	var ctrl := mid + perp * (bend + jitter)
	var pts := PackedVector2Array()
	for i in 7:
		var t := i / 6.0
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	line.points = pts


func _line() -> Line2D:
	var l := Line2D.new()
	l.width = LIMB_WIDTH
	l.default_color = Palette.INK
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.antialiased = true
	l.use_parent_material = true
	body.add_child(l)
	return l


func _sprite(tex: Texture2D, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(0.5, 0.5)
	s.offset = offset
	s.use_parent_material = true
	body.add_child(s)
	return s
