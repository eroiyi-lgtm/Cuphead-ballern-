extends Node
## Level-Zustand, Sofort-Neustart ohne Szenenwechsel, Zeitmessung, Hit-Stop, Screen Shake.

var level = null          ## Level01
var player = null         ## Pete
var pool = null           ## ProjectilePool
var camera: Camera2D = null

var running := false
var run_time := 0.0
var attempt_deaths := 0   ## Tode seit dem letzten Sieg
var last_restart_ms := 0.0
var god_mode := false     ## Debug: Pete nimmt keinen Schaden
var fixed_seed := 0       ## Debug: 0 = zufällig, sonst reproduzierbare Boss-Muster
var current_seed := 0
var rng := RandomNumberGenerator.new()

var _hit_stop_token := 0
var _shake_strength := 0.0
var _shake_time := 0.0
var _shake_duration := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.player_died.connect(_on_player_died)
	Events.boss_defeated.connect(_on_boss_defeated)
	_reseed()


func _physics_process(delta: float) -> void:
	if running and not get_tree().paused:
		run_time += delta


func _process(delta: float) -> void:
	if camera == null:
		return
	if _shake_time > 0.0:
		_shake_time -= delta
		var k := clampf(_shake_time / _shake_duration, 0.0, 1.0) * _shake_strength * SaveData.screen_wobble
		camera.offset = Vector2(randf_range(-k, k), randf_range(-k, k))
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


## Erster Start nach der Titelkarte.
func start_level() -> void:
	running = true
	run_time = 0.0
	if player:
		player.controls_enabled = true
	Events.level_started.emit()


## Setzt nur Zustände zurück, lädt nichts neu. Ziel ≤ 0,5 s bis zur Kontrolle.
func restart_level() -> void:
	# Pausieren passiert im Prozess-Schritt; im Physik-Schritt zu entpausieren erzeugt in Godot 4.3
	# Fehler in der Prozessliste. Deshalb Neustart immer außerhalb des Physik-Schritts.
	if Engine.is_in_physics_frame():
		await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	_hit_stop_token += 1
	Engine.time_scale = 1.0
	get_tree().paused = false
	_shake_time = 0.0
	_reseed()
	Events.level_restarted.emit()
	run_time = 0.0
	running = true
	last_restart_ms = (Time.get_ticks_usec() - t0) / 1000.0


func hit_stop(frames := 3) -> void:
	_hit_stop_token += 1
	var token := _hit_stop_token
	Engine.time_scale = 0.05
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout
	if token == _hit_stop_token:
		Engine.time_scale = 1.0


func shake(strength: float, duration: float) -> void:
	if strength >= _shake_strength * clampf(_shake_time / maxf(_shake_duration, 0.001), 0.0, 1.0):
		_shake_strength = strength
		_shake_duration = duration
		_shake_time = duration


func toggle_pause() -> void:
	if not running:
		return
	get_tree().paused = not get_tree().paused
	Events.pause_changed.emit(get_tree().paused)


## Note A+ bis D aus Zeit und verbliebenen HP. Schwellen werden nach Playtests nachgezogen.
func compute_grade(time_s: float, hp_left: int) -> String:
	var score := 0
	if time_s <= 210.0:
		score += 2
	elif time_s <= 270.0:
		score += 1
	score += clampi(hp_left - 1, 0, 2)
	return SaveData.GRADES[clampi(score, 0, 4)]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func _reseed() -> void:
	current_seed = fixed_seed if fixed_seed != 0 else randi()
	rng.seed = current_seed


func _on_player_died() -> void:
	running = false
	attempt_deaths += 1
	SaveData.record_death()


func _on_boss_defeated() -> void:
	if not running:
		return
	running = false
	var hp_left: int = player.hp if player else 0
	var grade := compute_grade(run_time, hp_left)
	SaveData.record_win(run_time, grade)
	Events.level_completed.emit(run_time, attempt_deaths, grade)
	attempt_deaths = 0
