class_name BlobSpawner
extends Node2D
## Ink-Blobs springen aus den Zahnrädern (Segment C): höchstens ein Blob pro Spawner gleichzeitig.

const INTERVAL := 3.5
const RANGE := 900.0

var _t := 1.5
var _blob: Node = null


func reset() -> void:
	_t = 1.5
	_blob = null


func _physics_process(delta: float) -> void:
	if Game.player == null or Game.level == null:
		return
	if absf(Game.player.global_position.x - global_position.x) > RANGE:
		return
	if is_instance_valid(_blob) and not _blob.dead:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = INTERVAL
	var dir := signf(Game.player.global_position.x - global_position.x)
	_blob = Game.level.spawn_blob(global_position, Vector2(dir * 260.0, -760.0))
