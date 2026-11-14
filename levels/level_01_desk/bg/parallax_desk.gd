class_name ParallaxDesk
## 6 Parallax-Ebenen (Ebene 3 = Spielebene im Level selbst). Phase 2: Skizzen-Platzhalter.
## Hintergründe ohne harte Outlines und entsättigt, damit Figuren und Geschosse vorne lesbar bleiben.
## Screen Shake wirkt über scroll_scale automatisch stärker auf nahe Ebenen (2.5D-Tiefe).


static func build_background(level: Node2D) -> void:
	_wall_layer(level)
	_far_layer(level)
	_mid_layer(level)


static func build_foreground(level: Node2D) -> void:
	_near_layer(level)
	_vignette_layer(level)


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
	p.add_child(_rect(Rect2(900, 110, 560, 430), Palette.AIR))
	p.add_child(_rect(Rect2(1170, 110, 16, 430), Color("b49a72")))
	var sun := Node2D.new()
	sun.position = Vector2(1080, 260)
	p.add_child(sun)
	sun.add_child(_circle(Vector2.ZERO, 70, Color("e8c66a")))
	var eye := _circle(Vector2(22, -12), 9, Color("8a6d3b"))
	sun.add_child(eye)
	sun.add_child(_circle(Vector2(-22, -12), 9, Color("8a6d3b")))
	var blink := eye.create_tween().set_loops()
	blink.tween_interval(2.6)
	blink.tween_property(eye, "scale:y", 0.1, 0.08)
	blink.tween_property(eye, "scale:y", 1.0, 0.08)
	var curtain := _poly([Vector2(0, 0), Vector2(140, 0), Vector2(90, 470), Vector2(0, 470)], Color("a4664a"))
	curtain.position = Vector2(860, 90)
	p.add_child(curtain)
	var sway := curtain.create_tween().set_loops()
	sway.tween_property(curtain, "skew", 0.06, 1.6).set_trans(Tween.TRANS_SINE)
	sway.tween_property(curtain, "skew", -0.04, 1.6).set_trans(Tween.TRANS_SINE)


## Ebene 1 – Fern (0,2): Bücherregal, Globus dreht
static func _far_layer(level: Node2D) -> void:
	var p := _layer(level, "L1_Far", 0.2, 2000.0, -40)
	p.add_child(_rect(Rect2(80, 260, 620, 640), Color("8c6a4c")))
	for row in 3:
		for i in 14:
			var h := 120.0 + (i * 37 % 50)
			p.add_child(_rect(Rect2(100 + i * 42, 450 + row * 200 - h, 34, h), Color("a07d5c").lerp(Color("6f8c86"), (i % 3) / 3.0)))
	var globe := Node2D.new()
	globe.position = Vector2(1300, 640)
	p.add_child(globe)
	globe.add_child(_circle(Vector2.ZERO, 110, Color("9fb3a6")))
	globe.add_child(_rect(Rect2(-6, -110, 12, 220), Color("b89c6e")))
	globe.add_child(_rect(Rect2(-110, -6, 220, 12), Color("b89c6e")))
	globe.create_tween().set_loops().tween_property(globe, "rotation", TAU, 12.0).from(0.0)
	p.add_child(_rect(Rect2(1280, 750, 40, 160), Color("8c6a4c")))


## Ebene 2 – Mitte (0,45): Lampe pendelt, Wecker tickt, Briefmarken
static func _mid_layer(level: Node2D) -> void:
	var p := _layer(level, "L2_Mid", 0.45, 1800.0, -30)
	var lamp := Node2D.new()
	lamp.position = Vector2(500, -20)
	p.add_child(lamp)
	lamp.add_child(_rect(Rect2(-4, 0, 8, 300), Color("6b5a44")))
	lamp.add_child(_poly([Vector2(-110, 380), Vector2(110, 380), Vector2(50, 290), Vector2(-50, 290)], Color("7d8c6a")))
	var swing := lamp.create_tween().set_loops()
	swing.tween_property(lamp, "rotation", 0.1, 1.8).set_trans(Tween.TRANS_SINE)
	swing.tween_property(lamp, "rotation", -0.1, 1.8).set_trans(Tween.TRANS_SINE)
	p.add_child(_circle(Vector2(1300, 690), 130, Color("c9b28a")))
	var hand := _rect(Rect2(-4, -100, 8, 100), Color("5a4a3a"))
	hand.position = Vector2(1300, 690)
	p.add_child(hand)
	var tick := hand.create_tween().set_loops()
	tick.tween_interval(0.5)
	tick.tween_property(hand, "rotation", TAU / 60.0, 0.05).as_relative()
	for i in 3:
		p.add_child(_rect(Rect2(900 + i * 90, 380 + i * 30, 70, 90), Color("b8a27e")))


## Ebene 4 – Nah-Vordergrund (1,3): Radiergummi-Krümel, Büroklammern
static func _near_layer(level: Node2D) -> void:
	var p := _layer(level, "L4_Near", 1.3, 1600.0, 20)
	for i in 6:
		p.add_child(_circle(Vector2(120 + i * 270, 1060 - (i % 2) * 16), 22 + (i % 3) * 8, Color("a8807a")))
	p.add_child(_rect(Rect2(700, 1040, 160, 14), Color("8f969c")))


## Ebene 5 – Vignetten-Vordergrund (1,6): unscharfe Bleistiftspitzen am Rand
static func _vignette_layer(level: Node2D) -> void:
	var p := _layer(level, "L5_Vignette", 1.6, 3000.0, 30)
	var tip := _poly([Vector2(0, 1080), Vector2(160, 1080), Vector2(60, 820)], Color(Palette.INK, 0.35))
	tip.position = Vector2(400, 0)
	p.add_child(tip)
	var tip2 := _poly([Vector2(0, 1080), Vector2(200, 1080), Vector2(120, 760)], Color(Palette.WALNUT, 0.35))
	tip2.position = Vector2(2100, 0)
	p.add_child(tip2)


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
