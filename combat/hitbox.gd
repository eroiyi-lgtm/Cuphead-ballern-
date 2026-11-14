class_name Hitbox
extends Area2D
## Kontaktschaden: trifft jede aktive Hurtbox, die es überlappt, jeden Tick erneut.
## Die Unverwundbarkeit des Ziels verhindert Mehrfachtreffer. Pro Animationsframe über
## `enabled` und die Shape-Größe steuerbar (AnimationPlayer-Track auf "enabled").

signal landed(target: Hurtbox)

var damage := 1
var source: Node
var shape_node: CollisionShape2D
var enabled := true:
	set(value):
		enabled = value
		if shape_node:
			shape_node.set_deferred("disabled", not value)


static func create(owner_node: Node2D, target_mask: int, shape: Shape2D, offset: Vector2, dmg: int) -> Hitbox:
	var hb := Hitbox.new()
	hb.name = "Hitbox"
	hb.collision_layer = 0
	hb.collision_mask = target_mask
	hb.monitoring = true
	hb.monitorable = false
	hb.damage = dmg
	hb.source = owner_node
	hb.shape_node = CollisionShape2D.new()
	hb.shape_node.shape = shape
	hb.shape_node.position = offset
	hb.add_child(hb.shape_node)
	hb.add_to_group(&"debug_shapes")
	owner_node.add_child(hb)
	return hb


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	for area in get_overlapping_areas():
		if area is Hurtbox and (area as Hurtbox).take_hit(damage, source):
			landed.emit(area)
