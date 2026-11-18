class_name ParallaxDesk
## Parallax-Ebenen (Ebene 3 = Spielebene im Level selbst). Ferne Ebenen sind Zonen pro Abschnitt
## (ZoneLayer), damit Bücherberg, Lineal-Brücke, Uhrwerk, Tintenfass und Arena eigene Kulissen haben.
## Hintergründe ohne harte Outlines und entsättigt, damit Figuren und Geschosse vorne lesbar bleiben.
## Screen Shake wirkt über scroll_scale automatisch stärker auf nahe Ebenen (2.5D-Tiefe).


const SEG_B := 3900.0
const SEG_C := 6300.0
const SEG_D := 8800.0
const ARENA := 11500.0


static func build_background(level: Node2D) -> void:
	_wall_layer(level)
	_far_layer(level)        # A: Bücherregal + Globus
	_far_b(level)            # B: Briefständer, Sanduhr, Kerze
	_far_c(level)            # C: Uhrwerk-Wand
	_far_d(level)            # D: Tintenregal
	_far_arena(level)        # Arena: Bühne mit Samtvorhang
	_mid_layer(level)


static func build_foreground(level: Node2D) -> void:
	_near_layer(level)
	_vignette_layer(level)


static func _zone(level: Node2D, layer_name: String, factor: float, repeat_w: float, z: int, from_x: float, to_x: float) -> ZoneLayer:
	var p := ZoneLayer.new()
	p.name = layer_name
	p.scroll_scale = Vector2(factor, 1.0)
	p.repeat_size = Vector2(repeat_w, 0)
	p.repeat_times = 4 if repeat_w > 0.0 else 1
	p.z_index = z
	p.zone_from = from_x
	p.zone_to = to_x
	level.add_child(p)
	return p


static func _layer(level: Node2D, layer_name: String, factor: float, repeat_w: float, z: int) -> Parallax2D:
	var p := Parallax2D.new()
	p.name = layer_name
	p.scroll_scale = Vector2(factor, 1.0)
	p.repeat_size = Vector2(repeat_w, 0)
	p.repeat_times = 4
	p.z_index = z
	level.add_child(p)
	return p


## Ebene 0 – Himmel/Wand (0,05): Tapete, Fenster, Sonne zwinkert, Vorhang weht
static func _wall_layer(level: Node2D) -> void:
	var p := _layer(level, "L0_Wall", 0.05, 2400.0, -50)
	p.add_child(_rect(Rect2(0, -300, 2400, 1500), Color("cdb894")))
	for i in 24:
		p.add_child(_rect(Rect2(i * 100 + 30, -300, 18, 1500), Color("c4ad87")))
		p.add_child(_circle(Vector2(i * 100 + 80, 120 + (i % 3) * 260), 10, Color("bfa47c")))
	var window := _sprite(preload("res://art/bg/window.svg"), Vector2(1180, 330), 1.0)
	p.add_child(window)
	var curtain := _poly([Vector2(0, 0), Vector2(150, 0), Vector2(100, 500), Vector2(0, 500)], Color("a4664a"))
	curtain.position = Vector2(860, 80)
	p.add_child(curtain)
	var sway := curtain.create_tween().set_loops()
	sway.tween_property(curtain, "skew", 0.06, 1.6).set_trans(Tween.TRANS_SINE)
	sway.tween_property(curtain, "skew", -0.04, 1.6).set_trans(Tween.TRANS_SINE)
	_wash(p)


## Ebene 1 – Fern (0,2): Bücherregal, Globus dreht
static func _far_layer(level: Node2D) -> void:
	var p := _zone(level, "L1_Far_A", 0.2, 2000.0, -40, -INF, SEG_B)
	p.add_child(_sprite(preload("res://art/bg/bookshelf.svg"), Vector2(390, 580), 1.0))
	var globe := _sprite(preload("res://art/bg/globe.svg"), Vector2(1300, 640), 1.0)
	p.add_child(globe)
	globe.create_tween().set_loops().tween_property(globe, "rotation", TAU, 14.0).from(0.0)
	p.add_child(_rect(Rect2(1285, 760, 30, 150), Color("8c6a4c")))
	p.add_child(_rect(Rect2(1230, 900, 140, 18), Color("8c6a4c")))
	_wash(p)


## Fern-Zone B "Lineal-Brücke": Schreibtisch-Kram im Gegenlicht
static func _far_b(level: Node2D) -> void:
	var p := _zone(level, "L1_Far_B", 0.2, 1800.0, -40, SEG_B, SEG_C)
	p.add_child(_sprite(preload("res://art/bg/letter_rack.svg"), Vector2(420, 760), 1.8))
	p.add_child(_sprite(preload("res://art/bg/hourglass.svg"), Vector2(1050, 700), 1.6))
	p.add_child(_sprite(preload("res://art/bg/candle.svg"), Vector2(1450, 690), 1.5))
	p.add_child(_rect(Rect2(0, 900, 1800, 40), Color("6e5236")))
	_wash(p)


## Fern-Zone C "Uhrwerk": Messing-Zahnräder hinter dem Holz, langsam drehend
static func _far_c(level: Node2D) -> void:
	var p := _zone(level, "L1_Far_C", 0.2, 1400.0, -40, SEG_C, SEG_D)
	var wall := _sprite(preload("res://art/bg/clockwork_wall.svg"), Vector2(700, 500), 1.0)
	p.add_child(wall)
	var sway := wall.create_tween().set_loops()
	sway.tween_property(wall, "position:y", 494.0, 0.5)
	sway.tween_property(wall, "position:y", 500.0, 0.5)
	_wash(p)


## Fern-Zone D "Kippendes Tintenfass": Regal voller Tintenflaschen, Siegel und Briefe
static func _far_d(level: Node2D) -> void:
	var p := _zone(level, "L1_Far_D", 0.2, 1300.0, -40, SEG_D, ARENA)
	p.add_child(_sprite(preload("res://art/bg/ink_shelf.svg"), Vector2(650, 520), 1.0))
	_wash(p)


## Arena: kleine Bühne mit Samtvorhang und Scheinwerfer – Reginalds Audienz
static func _far_arena(level: Node2D) -> void:
	var p := _zone(level, "L1_Far_Arena", 0.2, 0.0, -45, ARENA, INF)
	p.add_child(_sprite(preload("res://art/bg/stage.svg"), Vector2(11900.0 * 0.2 + 900.0, 470), 0.7))
	_wash(p)


## Ebene 2 – Mitte (0,45): Lampe pendelt, Wecker tickt, Sanduhr, Kerze – lange Folge statt kurzer Wiederholung
static func _mid_layer(level: Node2D) -> void:
	var p := _zone(level, "L2_Mid", 0.45, 3600.0, -30, -INF, ARENA)
	for lx in [500.0, 2300.0]:
		var lamp := Node2D.new()
		lamp.position = Vector2(lx, -20)
		p.add_child(lamp)
		lamp.add_child(_rect(Rect2(-4, 0, 8, 210), Color("6b5a44")))
		lamp.add_child(_sprite(preload("res://art/bg/lamp.svg"), Vector2(0, 280), 1.0))
		var swing := lamp.create_tween().set_loops()
		swing.tween_property(lamp, "rotation", 0.1, 1.8).set_trans(Tween.TRANS_SINE)
		swing.tween_property(lamp, "rotation", -0.1, 1.8).set_trans(Tween.TRANS_SINE)
	var clock := _sprite(preload("res://art/bg/clock.svg"), Vector2(1300, 700), 1.0)
	p.add_child(clock)
	var hand := _rect(Rect2(-5, -100, 10, 100), Color("5a4a3a"))
	hand.position = Vector2(1300, 710)
	p.add_child(hand)
	var tick := hand.create_tween().set_loops()
	tick.tween_interval(0.5)
	tick.tween_property(hand, "rotation", TAU / 60.0, 0.05).as_relative()
	var wobble := clock.create_tween().set_loops()
	wobble.tween_property(clock, "rotation", 0.03, 0.25)
	wobble.tween_property(clock, "rotation", -0.03, 0.25)
	p.add_child(_sprite(preload("res://art/bg/hourglass.svg"), Vector2(3000, 760), 1.0))
	p.add_child(_sprite(preload("res://art/bg/candle.svg"), Vector2(1900, 760), 0.9))
	_wash(p)


## Ebene 4 – Nah-Vordergrund (1,3): Radiergummi-Krümel, Bleistiftspäne, Büroklammer – dunkel und sparsam
static func _near_layer(level: Node2D) -> void:
	var p := _layer(level, "L4_Near", 1.3, 2600.0, 20)
	p.add_child(_sprite(preload("res://art/fg/crumbs.svg"), Vector2(300, 1050), 1.0))
	p.add_child(_sprite(preload("res://art/fg/shavings.svg"), Vector2(1250, 1052), 1.0))
	p.add_child(_sprite(preload("res://art/fg/paperclip.svg"), Vector2(2050, 1060), 0.9))
	p.modulate = Color(0.55, 0.45, 0.4, 1.0)


## Ebene 5 – Vignetten-Vordergrund (1,6): riesige, unscharf-dunkle Bleistiftspitze, selten vorbeiwischend
static func _vignette_layer(level: Node2D) -> void:
	var p := _layer(level, "L5_Vignette", 1.6, 5200.0, 30)
	var tip := _sprite(preload("res://art/enemies/pencil.svg"), Vector2(900, 1080), 3.2)
	tip.rotation = -2.6
	p.add_child(tip)
	p.modulate = Color(0.12, 0.1, 0.1, 0.55)


## Aquarell-Material für eine Hintergrund-Ebene, alle Kinder erben es.
static func _wash(p: Node) -> void:
	var m := ShaderMaterial.new()
	m.shader = preload("res://fx/shaders/paper_wash.gdshader")
	(p as CanvasItem).material = m
	_inherit(p)


static func _inherit(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasItem:
			(c as CanvasItem).use_parent_material = true
		_inherit(c)


static func _sprite(tex: Texture2D, pos: Vector2, s: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.position = pos
	sp.scale = Vector2(s, s)
	return sp


static func _rect(r: Rect2, c: Color) -> Polygon2D:
	return _poly([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)], c)


static func _circle(center: Vector2, radius: float, c: Color) -> Polygon2D:
	var pts := []
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return _poly(pts, c)


static func _poly(pts: Array, c: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = c
	return p
