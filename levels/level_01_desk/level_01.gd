class_name Level01
extends Node2D
## Level 1 "Das Schreibtisch-Duell": ca. 75 s Run & Gun in vier Segmenten ohne Checkpoint, dann
## nahtlos (ohne Ladebildschirm) Kamera-Stopp in der Boss-Arena und 3 Boss-Phasen.
##   A "Bücherberg"          0 –  4000   Buchtürme, 4 Ink-Blobs einzeln
##   B "Lineal-Brücke"    4000 –  6300   Lineal über Tintensee, Pencil-Sprites in 2er-Gruppen
##   C "Uhrwerk"          6300 –  8800   3 Zahnräder (40°/s), 1 Kolben, Blobs aus den Zahnrädern
##   D "Kippendes Tintenfass" 8800 – 11500  Flut alle 2,5 s, Federhalter-Steg, 6 Blobs + 4 Pencils

const FLOOR_Y := 900.0
const SPAWN := Vector2(220, FLOOR_Y)
const SEG_B := 4000.0
const SEG_C := 6300.0
const SEG_D := 8800.0
const GATE_X := 11500.0           ## Briefbeschwerer am Ende von D
const ARENA_LEFT := 11900.0
const ARENA_RIGHT := 13500.0      ## 1600 breit: passt bei ZOOM_ARENA ganz ins Bild
const BOSS_X := ARENA_RIGHT - 260.0
const PLAY_RIGHT := ARENA_RIGHT - 450.0  ## unsichtbare Wand vor dem Tintenfass
const KILL_Y := 1100.0
const RUN_WEIGHT := 0.3
## Bildausschnitt: näher dran als 1:1, Boden im unteren Bilddrittel (klassischer Run-&-Gun-Rahmen)
const ZOOM_RUN := 1.35
const ZOOM_ARENA := 1.2
const FLOOR_SCREEN := 0.86        ## Boden bei 86 % der Bildhöhe           ## Anteil des Run-Teils an der Fortschrittsleiste

## Boden mit Lücken für Tintensee (B) und Zahnrad-Grube (C). [x_von, x_bis]
const FLOOR_PIECES := [[-400.0, 4300.0], [6300.0, 6900.0], [8800.0, ARENA_RIGHT + 1000.0]]
const INK_POOLS := [[4300.0, 6300.0], [6900.0, 8800.0]]
## A: 3 gestaffelte Buchtürme, Stufen 64–128 px. [x_von, x_bis, höhe]
const TOWERS := [
	[1000, 1250, 96], [1250, 1450, 192],
	[2100, 2300, 128], [2300, 2450, 256], [2450, 2650, 128],
	[3200, 3400, 96], [3400, 3600, 192], [3600, 3800, 288],
]
## B: 30-cm-Lineal in drei Stücken, Lücken 160 px
const RULERS := [[4300.0, 4950.0], [5110.0, 5700.0], [5860.0, 6300.0]]
## C: Zahnräder [x, y, radius, grad/s, startwinkel], Kolben x
const GEARS := [[7150.0, 680.0, 190.0, 40.0, 90.0], [7700.0, 680.0, 190.0, -40.0, 45.0], [8250.0, 680.0, 190.0, 40.0, 90.0]]
const PISTON_X := 8640.0
## D: Federhalter-Steg (einseitig begehbar) [x_von, x_bis], Flutbereich
const PEN_WALKWAY := [[9620.0, 10020.0], [10160.0, 10520.0], [10660.0, 10960.0]]
const D_FLOOD := Rect2(9600.0, FLOOR_Y - 40.0, 1400.0, 40.0)
const D_INKWELL := Vector2(9480.0, FLOOR_Y - 230.0)

const BLOB_SPAWNS := [
	Vector2(820, FLOOR_Y), Vector2(1350, FLOOR_Y - 192), Vector2(2950, FLOOR_Y), Vector2(3900, FLOOR_Y - 288),
	Vector2(9250, FLOOR_Y), Vector2(9900, FLOOR_Y), Vector2(10250, FLOOR_Y), Vector2(10550, FLOOR_Y),
	Vector2(10850, FLOOR_Y), Vector2(11200, FLOOR_Y),
]
const PENCIL_SPAWNS := [
	Vector2(4750, 380), Vector2(4890, 380), Vector2(5500, 360), Vector2(5640, 360), Vector2(6150, 400), Vector2(6290, 400),
	Vector2(9800, 360), Vector2(9940, 360), Vector2(10700, 360), Vector2(10840, 360),
]
const BOOK_COLORS := [Color("7b2d26"), Color("2f5233"), Color("2e4a7a"), Color("8a6d3b")]

const PETE_SCENE := preload("res://actors/player/pete.tscn")
const BLOB_SCENE := preload("res://actors/enemies/ink_blob.tscn")
const PENCIL_SCENE := preload("res://actors/enemies/pencil_sprite.tscn")
const BOSS_SCENE := preload("res://actors/bosses/inkwell/sir_reginald.tscn")

var kill_y := KILL_Y
var pete: Pete
var boss: SirReginald
var arena: BossArena
var camera: Camera2D
var enemies: Node2D
var pool: ProjectilePool
var in_arena := false
var gate_open := false

var _props: Array[Node] = []
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
	_build_props()
	arena = BossArena.new().setup(ARENA_LEFT, PLAY_RIGHT, FLOOR_Y)
	arena.name = "BossArena"
	add_child(arena)
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
	Events.boss_phase_changed.connect(arena.set_phase)
	Events.boss_defeated.connect(_kill_all_enemies)


func _physics_process(_delta: float) -> void:
	if not in_arena:
		camera.position = Vector2(maxf(pete.global_position.x + 140.0, _half_width(ZOOM_RUN)), _center_y(ZOOM_RUN))
		if not gate_open and pete.global_position.x > GATE_X - 320.0:
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
		enemies.remove_child(e)
		e.queue_free()
	_spawn_enemies()
	for p in _props:
		p.reset()
	arena.reset()
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


func spawn_blob(pos: Vector2, launch := Vector2.ZERO) -> InkBlob:
	var blob: InkBlob = BLOB_SCENE.instantiate()
	blob.position = pos
	enemies.add_child(blob)
	if launch != Vector2.ZERO:
		blob.launch(launch)
	return blob


func spawn_pencil(pos: Vector2) -> PencilSprite:
	var pencil: PencilSprite = PENCIL_SCENE.instantiate()
	pencil.position = pos
	enemies.add_child(pencil)
	return pencil


func count_alive(type: Variant, min_x := -INF) -> int:
	var n := 0
	for e in enemies.get_children():
		if is_instance_of(e, type) and not e.dead and e.global_position.x >= min_x:
			n += 1
	return n


## Debug: direkt vor die Arena springen.
func skip_to_arena() -> void:
	pete.global_position = Vector2(ARENA_LEFT + 200.0, FLOOR_Y)
	pete.velocity = Vector2.ZERO
	if not gate_open:
		open_gate()


## Sturz in Tinte: Respawn am Anfang des Abschnitts (Brückenanfang bzw. vor dem Uhrwerk).
func get_respawn_point(x: float) -> Vector2:
	if in_arena:
		return Vector2(ARENA_LEFT + 200.0, FLOOR_Y)
	if x >= SEG_C and x < SEG_D:
		return Vector2(SEG_C + 450.0, FLOOR_Y)
	if x >= SEG_B and x < SEG_C:
		return Vector2(SEG_B + 150.0, FLOOR_Y)
	return SPAWN


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
	for e in enemies.get_children():  # Run-Gegner bleiben draußen
		if e is EnemyBase and not e.dead:
			e.die()
	_arena_wall.set_deferred("disabled", false)
	var from := camera.get_screen_center_position()
	camera.position_smoothing_enabled = false
	camera.position = from
	_arena_tween = create_tween()
	_arena_tween.tween_property(camera, "position", Vector2((ARENA_LEFT + ARENA_RIGHT) * 0.5, _center_y(ZOOM_ARENA)), 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arena_tween.parallel().tween_property(camera, "zoom", Vector2.ONE * ZOOM_ARENA, 1.2)
	_arena_tween.tween_callback(boss.begin_fight)
	AudioDirector.request_state(&"boss1")
	Events.boss_arena_entered.emit()


func _place_camera_at_start() -> void:
	camera.position_smoothing_enabled = true
	camera.zoom = Vector2.ONE * ZOOM_RUN
	camera.position = Vector2(maxf(SPAWN.x + 140.0, _half_width(ZOOM_RUN)), _center_y(ZOOM_RUN))
	camera.reset_smoothing()


## Kameramitte so, dass der Boden bei FLOOR_SCREEN der sichtbaren Höhe liegt.
func _center_y(zoom: float) -> float:
	var h := get_viewport().get_visible_rect().size.y / zoom
	return FLOOR_Y - h * (FLOOR_SCREEN - 0.5)


func _half_width(zoom: float) -> float:
	return get_viewport().get_visible_rect().size.x / zoom * 0.5


func _spawn_enemies() -> void:
	for p: Vector2 in BLOB_SPAWNS:
		spawn_blob(p)
	for p: Vector2 in PENCIL_SPAWNS:
		spawn_pencil(p)


func _kill_all_enemies() -> void:
	for e in enemies.get_children():
		if e is EnemyBase:
			e.die()


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
	# Tinte unter Brücke und Uhrwerk
	for pool_x: Array in INK_POOLS:
		_deco(Rect2(pool_x[0], FLOOR_Y + 40.0, pool_x[1] - pool_x[0], 500.0), Palette.INK)
		_deco(Rect2(pool_x[0], FLOOR_Y + 40.0, pool_x[1] - pool_x[0], 10.0), Palette.DANGER)
	# Schreibtischplatte
	for piece: Array in FLOOR_PIECES:
		_block(world, Rect2(piece[0], FLOOR_Y, piece[1] - piece[0], 500.0), Palette.WALNUT)
		_deco(Rect2(piece[0], FLOOR_Y, piece[1] - piece[0], 14.0), Palette.WALNUT.darkened(0.35))
		_wood_grain(piece[0], piece[1])
	# A: Buchtürme
	for i in TOWERS.size():
		var t: Array = TOWERS[i]
		var r := Rect2(float(t[0]), FLOOR_Y - float(t[2]), float(t[1]) - float(t[0]), float(t[2]))
		_block(world, r, BOOK_COLORS[i % BOOK_COLORS.size()])
		var y := r.position.y + 22.0
		while y < FLOOR_Y - 10.0:
			_deco(Rect2(r.position.x, y, r.size.x, 6), Palette.BOSS_GOLD.darkened(0.2))
			y += 48.0
	# B: Lineal mit Zentimeter-Strichen
	for ruler: Array in RULERS:
		var r := Rect2(ruler[0], FLOOR_Y, ruler[1] - ruler[0], 28.0)
		_block(world, r, Color("d9c08a"))
		var x: float = ruler[0] + 10.0
		var k := 0
		while x < ruler[1]:
			_deco(Rect2(x, FLOOR_Y, 3.0, 14.0 if k % 5 == 0 else 7.0), Palette.INK)
			x += 22.0
			k += 1
	# D: Federhalter-Steg (einseitig, von unten durchspringbar) + Bücherstapel unter dem Tintenfass
	for w: Array in PEN_WALKWAY:
		var cs := _block(world, Rect2(w[0], FLOOR_Y - 150.0, w[1] - w[0], 18.0), Color("4a4a52"))
		cs.one_way_collision = true
	_deco(Rect2(D_INKWELL.x - 90.0, D_INKWELL.y, 180.0, FLOOR_Y - D_INKWELL.y), Color(BOOK_COLORS[2], 0.8))  # Kulisse, nicht begehbar
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
	_gate_shape = _block(_gate, Rect2(GATE_X, FLOOR_Y - 300, 180, 300), Color(Palette.AIR, 0.85))
	_deco_on(_gate, Rect2(GATE_X + 20, FLOOR_Y - 60, 140, 60), Palette.BOSS_GOLD)


func _build_props() -> void:
	for g: Array in GEARS:
		var gear := Gear.new().setup(g[2], 4, g[3], g[4])
		gear.position = Vector2(g[0], g[1])
		add_child(gear)
		_props.append(gear)
		var spawner := BlobSpawner.new()
		spawner.position = Vector2(g[0], g[1] - 40.0)
		add_child(spawner)
		_props.append(spawner)
	var piston := Piston.new().setup(PISTON_X, FLOOR_Y - 10.0, 150.0, 2.0)
	add_child(piston)
	_props.append(piston)
	var well := TippingInkwell.new().setup(D_INKWELL, D_FLOOD)
	add_child(well)
	_props.append(well)


func _wood_grain(x0: float, x1: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x0) + 7
	for row in 5:
		var l := Line2D.new()
		l.width = 2.5
		l.default_color = Color(Palette.WALNUT.darkened(0.3), 0.6)
		var y := FLOOR_Y + 36.0 + row * 34.0
		var pts := PackedVector2Array()
		var x := x0
		while x <= x1:
			pts.append(Vector2(x, y + sin(x * 0.004 + row) * 6.0 + rng.randf_range(-1.5, 1.5)))
			x += 120.0
		l.points = pts
		add_child(l)


func _close_gate() -> void:
	gate_open = false
	if _gate_tween:
		_gate_tween.kill()
	_gate.position = Vector2.ZERO
	_gate.modulate.a = 1.0
	_gate_shape.set_deferred("disabled", false)


func _block(body: StaticBody2D, r: Rect2, color: Color, outline := true) -> CollisionShape2D:
	var cs := _wall(body, r)
	_deco_on(body, r, color)
	if outline:
		_ink_outline(body, r)
	return cs


## Tusche-Kontur für alles, worauf Pete steht (Hintergründe bleiben ohne Outlines).
func _ink_outline(parent: Node, r: Rect2) -> void:
	var l := Line2D.new()
	l.width = 5.0
	l.default_color = Palette.INK
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.closed = true
	l.antialiased = true
	l.points = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	parent.add_child(l)


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
