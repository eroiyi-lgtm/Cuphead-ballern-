class_name Level01
extends Node2D
## Level 1 "Das Schreibtisch-Duell" – Phase-2-Graybox: Run-&-Gun-Segment A "Bücherberg",
## dann nahtlos (ohne Ladebildschirm) Kamera-Stopp in der Boss-Arena, Boss-Phase 1.
## Segmente B–D folgen in Phase 3 zwischen RUN_END_X und der Arena.

const FLOOR_Y := 900.0
const SPAWN := Vector2(220, FLOOR_Y)
const RUN_END_X := 4600.0         ## Briefbeschwerer, öffnet sich bei Annäherung
const ARENA_LEFT := 5000.0
const ARENA_RIGHT := 6920.0
const BOSS_X := ARENA_RIGHT - 260.0
const PLAY_RIGHT := ARENA_RIGHT - 450.0  ## unsichtbare Wand vor dem Tintenfass
const KILL_Y := 1400.0
const RUN_WEIGHT := 0.3           ## Anteil des Run-Teils an der Fortschrittsleiste

## Segment A: 3 gestaffelte Buchtürme, Stufen 64–128 px. [x_von, x_bis, höhe]
const TOWERS := [
	[1000, 1250, 96], [1250, 1450, 192],
	[2100, 2300, 128], [2300, 2450, 256], [2450, 2650, 128],
	[3200, 3400, 96], [3400, 3600, 192], [3600, 3800, 288],
]
## 4 Ink-Blob Sparks einzeln
const BLOB_SPAWNS := [Vector2(820, FLOOR_Y), Vector2(1350, FLOOR_Y - 192), Vector2(2950, FLOOR_Y), Vector2(4250, FLOOR_Y)]
const BOOK_COLORS := [Color("7b2d26"), Color("2f5233"), Color("2e4a7a"), Color("8a6d3b")]

const PETE_SCENE := preload("res://actors/player/pete.tscn")
const BLOB_SCENE := preload("res://actors/enemies/ink_blob.tscn")
const BOSS_SCENE := preload("res://actors/bosses/inkwell/sir_reginald.tscn")

var kill_y := KILL_Y
var pete: Pete
var boss: SirReginald
var camera: Camera2D
var enemies: Node2D
var pool: ProjectilePool
var in_arena := false
var gate_open := false

var _gate: StaticBody2D
var _gate_shape: CollisionShape2D
var _arena_wall: CollisionShape2D
var _arena_tween: Tween
var _gate_tween: Tween
var _danger := 0


func _ready() -> void:
	Game.level = self
	ParallaxDesk.build_background(self)
	_build_world()
	boss = BOSS_SCENE.instantiate()
	boss.position = Vector2(BOSS_X, FLOOR_Y)
	add_child(boss)
	boss.configure(Rect2(ARENA_LEFT, 0, ARENA_RIGHT - ARENA_LEFT, FLOOR_Y), PLAY_RIGHT)
	enemies = Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	pete = PETE_SCENE.instantiate()
	pete.position = SPAWN
	add_child(pete)
	pool = ProjectilePool.new()
	add_child(pool)
	ParallaxDesk.build_foreground(self)

	camera = Camera2D.new()
	camera.name = "Camera"
	camera.limit_left = 0
	camera.limit_right = int(ARENA_RIGHT + 600)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	camera.make_current()
	Game.camera = camera
	_place_camera_at_start()

	_spawn_enemies()
	Events.level_restarted.connect(reset)


func _physics_process(_delta: float) -> void:
	if not in_arena:
		camera.position = Vector2(maxf(pete.global_position.x + 160.0, 960.0), 540.0)
		if not gate_open and pete.global_position.x > RUN_END_X - 320.0:
			open_gate()
		if gate_open and pete.global_position.x > ARENA_LEFT + 140.0:
			_enter_arena()
	_update_danger()


func reset() -> void:
	in_arena = false
	if _arena_tween:
		_arena_tween.kill()
	_arena_wall.set_deferred("disabled", true)
	_close_gate()
	for e in enemies.get_children():
		e.process_mode = Node.PROCESS_MODE_DISABLED
		e.queue_free()
	_spawn_enemies()
	boss.reset()
	_place_camera_at_start()
	_danger = 0
	Events.danger_level_changed.emit(0)
	AudioDirector.reset_music()


func open_gate() -> void:
	gate_open = true
	_gate_shape.set_deferred("disabled", true)
	_gate_tween = _gate.create_tween()
	_gate_tween.tween_property(_gate, "position:x", 260.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_gate_tween.parallel().tween_property(_gate, "modulate:a", 0.35, 0.6)


## Debug: direkt vor die Arena springen.
func skip_to_arena() -> void:
	pete.global_position = Vector2(ARENA_LEFT + 200.0, FLOOR_Y)
	pete.velocity = Vector2.ZERO
	if not gate_open:
		open_gate()


func get_respawn_point(_x: float) -> Vector2:
	return Vector2(ARENA_LEFT + 200.0, FLOOR_Y) if in_arena else SPAWN


## 0..1 für die Fortschrittsleiste im Todesbildschirm.
func get_progress() -> float:
	if not in_arena:
		return clampf(pete.global_position.x / ARENA_LEFT, 0.0, 1.0) * RUN_WEIGHT
	return RUN_WEIGHT + (1.0 - RUN_WEIGHT) * float(boss.brain.total_damage) / boss.brain.total_hp()


func get_progress_markers() -> Array[float]:
	var markers: Array[float] = [RUN_WEIGHT]
	var acc := 0
	var total := boss.brain.total_hp()
	for i in boss.brain.data.phases.size() - 1:
		acc += boss.brain.data.phases[i].hp
		markers.append(RUN_WEIGHT + (1.0 - RUN_WEIGHT) * float(acc) / total)
	return markers


func _enter_arena() -> void:
	in_arena = true
	_arena_wall.set_deferred("disabled", false)
	var from := camera.get_screen_center_position()
	camera.position_smoothing_enabled = false
	camera.position = from
	_arena_tween = create_tween()
	_arena_tween.tween_property(camera, "position", Vector2((ARENA_LEFT + ARENA_RIGHT) * 0.5, 540.0), 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arena_tween.tween_callback(boss.begin_fight)
	AudioDirector.request_state(&"boss1")
	Events.boss_arena_entered.emit()


func _place_camera_at_start() -> void:
	camera.position_smoothing_enabled = true
	camera.position = Vector2(maxf(SPAWN.x + 160.0, 960.0), 540.0)
	camera.reset_smoothing()


func _spawn_enemies() -> void:
	for p: Vector2 in BLOB_SPAWNS:
		var blob: Node2D = BLOB_SCENE.instantiate()
		blob.position = p
		enemies.add_child(blob)


func _update_danger() -> void:
	var active := 0
	for e in enemies.get_children():
		if e is EnemyBase and e.awake and not e.dead:
			active += 1
	var d := (1 if active >= 6 else 0) + (1 if pete.alive and pete.hp == 1 else 0)
	if d != _danger:
		_danger = d
		Events.danger_level_changed.emit(d)


func _build_world() -> void:
	var world := StaticBody2D.new()
	world.name = "Desk"
	world.collision_layer = Layers.WORLD
	world.collision_mask = 0
	add_child(world)
	# Schreibtischplatte über die ganze Länge
	_block(world, Rect2(-400, FLOOR_Y, ARENA_RIGHT + 1400, 500), Palette.WALNUT)
	_deco(Rect2(-400, FLOOR_Y, ARENA_RIGHT + 1400, 14), Palette.WALNUT.darkened(0.35))
	# Buchtürme
	for i in TOWERS.size():
		var t: Array = TOWERS[i]
		var r := Rect2(float(t[0]), FLOOR_Y - float(t[2]), float(t[1]) - float(t[0]), float(t[2]))
		_block(world, r, BOOK_COLORS[i % BOOK_COLORS.size()])
		var y := r.position.y + 22.0
		while y < FLOOR_Y - 10.0:
			_deco(Rect2(r.position.x, y, r.size.x, 6), Palette.BOSS_GOLD.darkened(0.2))
			y += 48.0
	# Weltgrenzen
	_wall(world, Rect2(-200, -600, 200, FLOOR_Y + 600))
	_wall(world, Rect2(ARENA_RIGHT, -600, 200, FLOOR_Y + 600))
	_wall(world, Rect2(PLAY_RIGHT, FLOOR_Y - 300, 20, 300))
	_arena_wall = _wall(world, Rect2(ARENA_LEFT - 20, -600, 20, FLOOR_Y + 600))
	_arena_wall.disabled = true
	# Briefbeschwerer (Glaskuppel), schiebt sich zur Seite
	_gate = StaticBody2D.new()
	_gate.name = "Paperweight"
	_gate.collision_layer = Layers.WORLD
	add_child(_gate)
	_gate_shape = _block(_gate, Rect2(RUN_END_X, FLOOR_Y - 300, 180, 300), Color(Palette.AIR, 0.85))
	_deco_on(_gate, Rect2(RUN_END_X + 20, FLOOR_Y - 60, 140, 60), Palette.BOSS_GOLD)


func _close_gate() -> void:
	gate_open = false
	if _gate_tween:
		_gate_tween.kill()
	_gate.position = Vector2.ZERO
	_gate.modulate.a = 1.0
	_gate_shape.set_deferred("disabled", false)


func _block(body: StaticBody2D, r: Rect2, color: Color) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.get_center()
	body.add_child(cs)
	_deco_on(body, r, color)
	return cs


func _wall(body: StaticBody2D, r: Rect2) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.get_center()
	body.add_child(cs)
	return cs


func _deco(r: Rect2, color: Color) -> void:
	_deco_on(self, r, color)


func _deco_on(parent: Node, r: Rect2, color: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	p.color = color
	parent.add_child(p)
