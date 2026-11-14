class_name BossArena
extends Node2D
## Arena-Zustand je Boss-Phase (gehört dem Level, gesteuert über Events.boss_phase_changed).
## Phase 1: flacher Boden. Phase 2: Tinte flutet die rechte Bodenhälfte, 3 schwebende Bücher
## werden Plattformen. Phase 3: Flut und Bücher weg, Reginalds Feder steckt im Tisch.

const BOOK_SIZE := Vector2(220, 26)

var left := 0.0
var play_right := 0.0
var floor_y := 900.0
var phase := 0

var _books: Array[AnimatableBody2D] = []
var _book_base: Array[Vector2] = []
var _flood: Polygon2D
var _flood_hitbox: Hitbox
var _quill_decor: Polygon2D
var _t := 0.0


func setup(arena_left: float, right: float, floor_height: float) -> BossArena:
	left = arena_left
	play_right = right
	floor_y = floor_height
	return self


func _ready() -> void:
	var mid := left + (play_right - left) * 0.5
	var flood_rect := Rect2(mid, floor_y - 34.0, play_right - mid, 34.0)
	_flood = Polygon2D.new()
	_flood.polygon = PackedVector2Array([flood_rect.position, Vector2(flood_rect.end.x, flood_rect.position.y), flood_rect.end, Vector2(flood_rect.position.x, flood_rect.end.y)])
	_flood.color = Palette.DANGER
	_flood.z_index = 1
	add_child(_flood)
	var shape := RectangleShape2D.new()
	shape.size = flood_rect.size
	_flood_hitbox = Hitbox.create(self, Layers.PETE_HURTBOX, shape, flood_rect.get_center(), 1)

	var span := play_right - left
	for p: Vector2 in [Vector2(left + span * 0.18, floor_y - 150.0), Vector2(left + span * 0.5, floor_y - 160.0), Vector2(left + span * 0.82, floor_y - 150.0)]:
		var book := AnimatableBody2D.new()
		book.collision_layer = Layers.WORLD
		book.collision_mask = 0
		book.sync_to_physics = true
		book.position = p
		var cs := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = BOOK_SIZE
		cs.shape = s
		cs.one_way_collision = true
		book.add_child(cs)
		var vis := Polygon2D.new()
		var h := BOOK_SIZE * 0.5
		vis.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
		vis.color = Color("7b2d26") if _books.size() % 2 == 0 else Color("2e4a7a")
		book.add_child(vis)
		var page := Polygon2D.new()
		page.polygon = PackedVector2Array([Vector2(-h.x + 8, -h.y + 4), Vector2(h.x - 8, -h.y + 4), Vector2(h.x - 8, -h.y + 9), Vector2(-h.x + 8, -h.y + 9)])
		page.color = Palette.PAPER
		book.add_child(page)
		add_child(book)
		_books.append(book)
		_book_base.append(p)

	_quill_decor = Polygon2D.new()
	_quill_decor.polygon = PackedVector2Array([Vector2(0, 0), Vector2(26, -520), Vector2(60, -540), Vector2(40, 0)])
	_quill_decor.color = Color.WHITE
	_quill_decor.position = Vector2(play_right - 40.0, floor_y)
	_quill_decor.z_index = -1
	add_child(_quill_decor)
	set_phase(0)


func reset() -> void:
	set_phase(0)


func set_phase(index: int) -> void:
	phase = index
	_t = 0.0
	var phase2 := index == 1
	_flood.visible = phase2
	_flood_hitbox.enabled = phase2
	for i in _books.size():
		var b := _books[i]
		b.visible = phase2
		b.position = _book_base[i]
		b.get_child(0).set_deferred("disabled", not phase2)
	_quill_decor.visible = index == 2


func _physics_process(delta: float) -> void:
	if phase != 1:
		return
	_t += delta
	for i in _books.size():
		_books[i].position = _book_base[i] + Vector2(0, sin(_t * 2.0 + i * 1.7) * 8.0)
