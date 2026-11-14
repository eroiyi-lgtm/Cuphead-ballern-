class_name Hurtbox
extends Area2D
## Nimmt Schaden an. Der Besitzer entscheidet über receiver: func(damage: int, source: Node) -> bool.
## true = Treffer angenommen (Geschoss wird verbraucht), false = durchlassen (z. B. Unverwundbarkeit).

var receiver: Callable
var active := true


static func create(owner_node: Node2D, layer: int, shape: Shape2D, offset: Vector2, on_hit: Callable) -> Hurtbox:
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = layer
	hb.collision_mask = 0
	hb.monitoring = false
	hb.monitorable = true
	hb.receiver = on_hit
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = offset
	hb.add_child(cs)
	hb.add_to_group(&"debug_shapes")
	owner_node.add_child(hb)
	return hb


func take_hit(damage: int, source: Node) -> bool:
	if not active or not receiver.is_valid():
		return false
	return receiver.call(damage, source)
