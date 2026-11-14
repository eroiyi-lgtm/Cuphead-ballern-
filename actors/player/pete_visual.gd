class_name PeteVisual
## Graybox-Figur für Pen-Pal Pete, bis die handgezeichneten Frames kommen.
## Ursprung: Füße unten Mitte (Vertrag A2 → A1). Hose Tinten-Blau, Rot nur am Stirnband.


static func build() -> Node2D:
	var visual := Node2D.new()
	visual.name = "Visual"
	var body := Node2D.new()
	body.name = "Body"
	visual.add_child(body)
	# Schuhe
	body.add_child(_ellipse(Vector2(-13, -7), Vector2(15, 8), Palette.WALNUT.darkened(0.4)))
	body.add_child(_ellipse(Vector2(14, -7), Vector2(15, 8), Palette.WALNUT.darkened(0.4)))
	# Beine (Rubber-Hose)
	body.add_child(_rect(Rect2(-14, -32, 7, 26), Palette.INK))
	body.add_child(_rect(Rect2(7, -32, 7, 26), Palette.INK))
	# Hose
	body.add_child(_rect(Rect2(-20, -52, 40, 24), Palette.INK_BLUE))
	# Oberkörper
	body.add_child(_rect(Rect2(-15, -74, 30, 24), Palette.INK))
	# Handschuhe
	body.add_child(_ellipse(Vector2(-22, -58), Vector2(8, 8), Color.WHITE))
	body.add_child(_ellipse(Vector2(24, -64), Vector2(8, 8), Color.WHITE))
	# Kopf mit Federhalter-Spitze als Nase
	body.add_child(_ellipse(Vector2(0, -96), Vector2(23, 23), Palette.PAPER))
	body.add_child(_poly([Vector2(16, -100), Vector2(42, -94), Vector2(16, -88)], Palette.BOSS_GOLD))
	# Helm
	var helmet := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		helmet.append(Vector2(cos(a) * 25, -100 + sin(a) * 25))
	body.add_child(_poly(helmet, Color("9ba0a6")))
	# Stirnband + Bandenden
	body.add_child(_rect(Rect2(-24, -104, 48, 8), Palette.HERO))
	body.add_child(_poly([Vector2(-24, -104), Vector2(-44, -112), Vector2(-40, -96), Vector2(-24, -96)], Palette.HERO))
	# Augen (Pie-Cut)
	body.add_child(_ellipse(Vector2(8, -92), Vector2(4, 6), Palette.INK))
	return visual


static func muzzle_star() -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var r := 22.0 if i % 2 == 0 else 9.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	var star := _poly(pts, Palette.DANGER_CORE)
	star.name = "MuzzleFlash"
	star.visible = false
	return star


static func _rect(r: Rect2, c: Color) -> Polygon2D:
	return _poly([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)], c)


static func _ellipse(center: Vector2, radii: Vector2, c: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return _poly(pts, c)


static func _poly(pts, c: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = c
	p.use_parent_material = true
	return p
