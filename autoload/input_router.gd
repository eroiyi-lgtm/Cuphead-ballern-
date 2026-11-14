extends Node
## Vereint Touch, Gamepad und Tastatur zu einem Zustand. Pete liest nur hier, nie Touch-Events direkt.

var move := Vector2.ZERO
var jump_pressed := false
var jump_held := false
var fire_held := false
var lock_held := false

# Von TouchControls geschrieben
var touch_move := Vector2.ZERO
var touch_jump_held := false
var touch_fire_held := false
var touch_lock_held := false
var _touch_jump_latch := false

# Für automatisierte Tests (debug/smoke_test.gd)
var override_enabled := false
var override_move := Vector2.ZERO
var override_jump_held := false
var override_fire_held := false
var override_lock_held := false
var _override_prev_jump := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -100  # vor allen Spielobjekten auswerten
	_register_actions()


## Ein Tap kann kürzer als ein Physik-Tick sein: der Sprung wird gemerkt, bis er gelesen wurde.
func press_touch_jump() -> void:
	_touch_jump_latch = true


func clear_touch() -> void:
	touch_move = Vector2.ZERO
	touch_jump_held = false
	touch_fire_held = false
	touch_lock_held = false
	_touch_jump_latch = false


func _physics_process(_delta: float) -> void:
	if override_enabled:
		move = override_move
		jump_pressed = override_jump_held and not _override_prev_jump
		_override_prev_jump = override_jump_held
		jump_held = override_jump_held
		fire_held = override_fire_held
		lock_held = override_lock_held
		return

	var pad := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)
	move = touch_move if touch_move.length_squared() > pad.length_squared() else pad
	jump_pressed = Input.is_action_just_pressed("jump") or _touch_jump_latch
	_touch_jump_latch = false
	jump_held = Input.is_action_pressed("jump") or touch_jump_held
	fire_held = Input.is_action_pressed("fire") or touch_fire_held
	lock_held = Input.is_action_pressed("lock") or touch_lock_held
	if SaveData.lock_mode == "fire_hold" and touch_fire_held:
		lock_held = true


func _register_actions() -> void:
	_add("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add("jump", [KEY_SPACE, KEY_K], [JOY_BUTTON_A], [])
	_add("fire", [KEY_J, KEY_X], [JOY_BUTTON_X], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_add("lock", [KEY_L, KEY_SHIFT], [JOY_BUTTON_RIGHT_SHOULDER], [])
	_add("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])


func _add(action: StringName, keys: Array, buttons: Array, axes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	if not InputMap.action_get_events(action).is_empty():
		return  # vom Spieler oder im Projekt belegt
	for k: int in keys:
		var ek := InputEventKey.new()
		ek.physical_keycode = k
		InputMap.action_add_event(action, ek)
	for b: int in buttons:
		var eb := InputEventJoypadButton.new()
		eb.button_index = b
		InputMap.action_add_event(action, eb)
	for ax: Array in axes:
		var em := InputEventJoypadMotion.new()
		em.axis = ax[0]
		em.axis_value = ax[1]
		InputMap.action_add_event(action, em)
