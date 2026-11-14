extends CanvasLayer
## Touch-Steuerung: Floating-Joystick links, Feuer rechts unten, Sprung links über Feuer.
## Jeder Finger wird per event.index einer Zone zugeordnet (Multitouch: Laufen + Springen + Feuern).
## Schreibt nur in InputRouter. Lock-Aim (Modus "swipe"): Feuer halten und auf dem Sprung-Button
## nach unten wischen. Damit ein normaler Sprung beim Feuern nicht verzögert, entscheidet die Geste
## innerhalb von LOCK_DECIDE_FRAMES; ohne Wisch zählt es als Sprung (Jump Buffer fängt das ab).

const STICK_RADIUS := 110.0
const DEADZONE := 0.18
const FIRE_RADIUS := 90.0       ## Ø 180 px
const JUMP_RADIUS := 65.0       ## Ø 130 px
const HIT_SCALE := 1.2          ## Berührfläche 20 % größer als die Grafik
const ALPHA := 0.26
const LOCK_SWIPE_PX := 36.0
const LOCK_DECIDE_FRAMES := 4

enum Zone { STICK, FIRE, JUMP, JUMP_PENDING, LOCK }

var enabled := true
var force_visible := false

var _fingers := {}   # index -> {zone, start, pos, frames}
var _stick_origin := Vector2.ZERO
var _stick_knob := Vector2.ZERO
var _stick_active := false
var _fire_center := Vector2.ZERO
var _jump_center := Vector2.ZERO
var _view := Vector2(1920, 1080)
var _top_taps: Array[float] = []
var _canvas: Control


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	get_viewport().size_changed.connect(_layout)
	_layout()
	Events.player_died.connect(_release_all)
	Events.level_restarted.connect(_release_all)


func set_force_visible(v: bool) -> void:
	force_visible = v
	visible = v or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func _layout() -> void:
	_view = get_viewport().get_visible_rect().size
	var margin_r := 0.0
	var margin_b := 0.0
	var safe := DisplayServer.get_display_safe_area()
	var win := Vector2(DisplayServer.window_get_size())
	if win.x > 0 and safe.size.x > 0:
		var s := _view / win
		margin_r = maxf(win.x - float(safe.end.x), 0.0) * s.x
		margin_b = maxf(win.y - float(safe.end.y), 0.0) * s.y
	_fire_center = Vector2(_view.x - margin_r - 70.0 - FIRE_RADIUS, _view.y - margin_b - 60.0 - FIRE_RADIUS)
	_jump_center = _fire_center + Vector2(-FIRE_RADIUS - JUMP_RADIUS - 40.0, -FIRE_RADIUS - 10.0)
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_on_down(t.index, t.position)
		else:
			_on_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_on_drag(d.index, d.position)


func _physics_process(_delta: float) -> void:
	for idx in _fingers.keys():
		var f: Dictionary = _fingers[idx]
		if f.zone == Zone.JUMP_PENDING:
			f.frames += 1
			if f.frames >= LOCK_DECIDE_FRAMES:
				f.zone = Zone.JUMP
				_jump_down()


func _on_down(idx: int, p: Vector2) -> void:
	_check_pause_gesture(p)
	if not enabled or get_tree().paused:
		return
	var zone := -1
	if p.distance_to(_fire_center) <= FIRE_RADIUS * HIT_SCALE:
		zone = Zone.FIRE
	elif p.distance_to(_jump_center) <= JUMP_RADIUS * HIT_SCALE:
		zone = Zone.JUMP_PENDING if (_count(Zone.FIRE) > 0 and SaveData.lock_mode == "swipe") else Zone.JUMP
	elif p.x < _view.x * 0.5 and not _stick_active:
		zone = Zone.STICK
		_stick_active = true
		_stick_origin = p
		_stick_knob = p
	if zone == -1:
		return
	_fingers[idx] = {"zone": zone, "start": p, "pos": p, "frames": 0}
	if zone == Zone.JUMP:
		_jump_down()
	_sync()


func _on_drag(idx: int, p: Vector2) -> void:
	if not _fingers.has(idx):
		return
	var f: Dictionary = _fingers[idx]
	f.pos = p
	match f.zone:
		Zone.STICK:
			var v := p - _stick_origin
			if v.length() > STICK_RADIUS:  # Joystick wandert mit
				_stick_origin = p - v.normalized() * STICK_RADIUS
				v = p - _stick_origin
			_stick_knob = p
			var n := v / STICK_RADIUS
			InputRouter.touch_move = n if n.length() > DEADZONE else Vector2.ZERO
		Zone.JUMP_PENDING:
			if p.y - f.start.y > LOCK_SWIPE_PX:
				f.zone = Zone.LOCK
	_sync()


func _on_up(idx: int) -> void:
	if not _fingers.has(idx):
		return
	var f: Dictionary = _fingers[idx]
	_fingers.erase(idx)
	if f.zone == Zone.STICK:
		_stick_active = false
		InputRouter.touch_move = Vector2.ZERO
	elif f.zone == Zone.JUMP_PENDING:
		_jump_down()  # kurzer Tap beim Feuern = normaler Sprung
	_sync()


func _jump_down() -> void:
	InputRouter.press_touch_jump()
	if SaveData.haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(15)


func _sync() -> void:
	InputRouter.touch_fire_held = _count(Zone.FIRE) > 0
	InputRouter.touch_jump_held = _count(Zone.JUMP) > 0
	InputRouter.touch_lock_held = _count(Zone.LOCK) > 0
	_canvas.queue_redraw()


func _count(zone: int) -> int:
	var n := 0
	for f: Dictionary in _fingers.values():
		if f.zone == zone:
			n += 1
	return n


func _release_all() -> void:
	_fingers.clear()
	_stick_active = false
	InputRouter.clear_touch()
	_canvas.queue_redraw()


## Pause nur über Zwei-Finger-Tap im oberen Bildschirmbereich.
func _check_pause_gesture(p: Vector2) -> void:
	if p.y > _view.y * 0.2:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var recent: Array[float] = []
	for t in _top_taps:
		if now - t < 0.25:
			recent.append(t)
	_top_taps = recent
	_top_taps.append(now)
	if _top_taps.size() >= 2:
		_top_taps.clear()
		_release_all()
		Game.toggle_pause()


func _draw_controls() -> void:
	var brass := Palette.BOSS_GOLD
	var ink := Palette.INK
	if _stick_active:
		_canvas.draw_circle(_stick_origin, STICK_RADIUS, Color(brass, ALPHA * 0.6))
		_canvas.draw_arc(_stick_origin, STICK_RADIUS, 0, TAU, 48, Color(ink, ALPHA + 0.1), 4.0)
		_canvas.draw_circle(_stick_knob, 44.0, Color(brass, ALPHA + 0.15))
	var fire_down := _count(Zone.FIRE) > 0
	var r_fire := FIRE_RADIUS * (0.92 if fire_down else 1.0)
	_canvas.draw_circle(_fire_center, r_fire, Color(brass, ALPHA + (0.12 if fire_down else 0.0)))
	_canvas.draw_arc(_fire_center, r_fire, 0, TAU, 48, Color(ink, ALPHA + 0.1), 5.0)
	var star := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 - PI / 2.0
		star.append(_fire_center + Vector2(cos(a), sin(a)) * (34.0 if i % 2 == 0 else 14.0))
	_canvas.draw_colored_polygon(star, Color(ink, ALPHA + 0.2))
	var jump_down := _count(Zone.JUMP) > 0 or _count(Zone.LOCK) > 0
	var r_jump := JUMP_RADIUS * (0.92 if jump_down else 1.0)
	_canvas.draw_circle(_jump_center, r_jump, Color(brass, ALPHA + (0.12 if jump_down else 0.0)))
	_canvas.draw_arc(_jump_center, r_jump, 0, TAU, 40, Color(ink, ALPHA + 0.1), 4.0)
	_canvas.draw_colored_polygon(PackedVector2Array([
		_jump_center + Vector2(0, -26), _jump_center + Vector2(24, 12), _jump_center + Vector2(-24, 12)]), Color(ink, ALPHA + 0.2))
	if _count(Zone.LOCK) > 0:
		_canvas.draw_arc(_jump_center, r_jump + 12.0, 0, TAU, 40, Color(Palette.HERO, 0.6), 4.0)
