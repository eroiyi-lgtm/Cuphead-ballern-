class_name PeteVisual
## Mündungsfeuer der Tintenpistole (Stern-Blitz). Die Figur selbst ist PeteRig.


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
