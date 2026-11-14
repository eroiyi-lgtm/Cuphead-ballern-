class_name HitboxOverlay
extends Node2D
## Zeichnet alle Hurtboxen (grün), Hitboxen (rot) und aktiven Geschosse (gelb) in Weltkoordinaten.


func _ready() -> void:
	z_index = 100
	top_level = true


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for node in get_tree().get_nodes_in_group(&"debug_shapes"):
		var area := node as Area2D
		if area == null:
			continue
		if area is Projectile and not (area as Projectile).active:
			continue
		if area is Hurtbox and not (area as Hurtbox).active:
			continue
		var color := Color.YELLOW
		if area is Hurtbox:
			color = Color(0.2, 1.0, 0.3)
		elif area is Hitbox:
			if not (area as Hitbox).enabled:
				continue
			color = Color(1.0, 0.2, 0.2)
		for child in area.get_children():
			var cs := child as CollisionShape2D
			if cs == null or cs.disabled:
				continue
			draw_set_transform_matrix(cs.global_transform)
			if cs.shape is CircleShape2D:
				draw_arc(Vector2.ZERO, (cs.shape as CircleShape2D).radius, 0, TAU, 24, color, 2.0)
			elif cs.shape is RectangleShape2D:
				var s := (cs.shape as RectangleShape2D).size
				draw_rect(Rect2(-s * 0.5, s), color, false, 2.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
