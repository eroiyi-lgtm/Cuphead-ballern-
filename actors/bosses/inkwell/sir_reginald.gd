class_name SirReginald
extends Node2D
## Sir Reginald Inkwell. Graybox-Darstellung, Kampflogik liegt in BossBrain + Attack-Ressourcen
## unter res://data/boss_inkwell/. Ursprung: Fuß des Tintenfasses, Mitte.

const DATA: BossData = preload("res://data/boss_inkwell/sir_reginald.tres")
const ACTOR_FX := preload("res://fx/shaders/actor_fx.gdshader")

var brain: BossBrain
var arena := Rect2()      ## Boss-Arena, Boden = arena.end.y
var play_right := 0.0     ## rechte Grenze der Spielfläche (vor dem Tintenfass)
var hits_taken := 0

var visual: Node2D
var hurtbox: Hurtbox
var contact: Hitbox
var attack_label: Label

var _inkwell: Node2D
var _upper: Node2D
var _head: Node2D
var _hurt_shape: CollisionShape2D
var _pose_tween: Tween
var _quill_arm: Node2D
var _seal_arm: Node2D
var _monocle: Sprite2D
var _arm_lines: Array[Line2D] = []
const MONOCLE_POS := Vector2(27, 11)
const SEAL_REST := Vector2(165, -300)
var _fx: ShaderMaterial
var _flash_frames := 0
var _anim: Tween


func _ready() -> void:
	_build_graybox()
	_fx = ShaderMaterial.new()
	_fx.shader = ACTOR_FX
	visual.material = _fx

	var hs := RectangleShape2D.new()
	hs.size = Vector2(320, 520)
	hurtbox = Hurtbox.create(self, Layers.ENEMY_HURTBOX, hs, Vector2(0, -260), _on_hurt)
	_hurt_shape = hurtbox.get_child(0) as CollisionShape2D
	var cs := RectangleShape2D.new()
	cs.size = Vector2(340, 300)
	contact = Hitbox.create(self, Layers.PETE_HURTBOX, cs, Vector2(0, -150), 1)

	attack_label = Label.new()
	attack_label.position = Vector2(-160, -640)
	attack_label.size = Vector2(320, 40)
	attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_label.add_theme_font_size_override(&"font_size", 30)
	attack_label.add_theme_color_override(&"font_color", Palette.INK)
	attack_label.visible = OS.is_debug_build()
	add_child(attack_label)

	brain = BossBrain.new()
	brain.name = "Brain"
	add_child(brain)
	brain.setup(DATA, self)
	brain.telegraph_started.connect(_on_telegraph)
	brain.attack_started.connect(_on_attack)
	brain.phase_changed.connect(_on_phase_changed)
	brain.rage_started.connect(_on_rage)
	brain.defeated.connect(_on_defeated)


func configure(arena_rect: Rect2, right_edge: float) -> void:
	arena = arena_rect
	play_right = right_edge


func begin_fight() -> void:
	brain.start()
	AudioDirector.play_sfx(&"boss_laugh")
	_play(&"intro", DATA.intro_time)


func reset() -> void:
	brain.reset()
	hits_taken = 0
	if _anim:
		_anim.kill()
	visual.visible = true
	visual.modulate = Color.WHITE
	_head.scale = Vector2.ONE
	_head.rotation = 0.0
	_quill_arm.rotation = 0.0
	_seal_arm.position = SEAL_REST
	_monocle.visible = true
	_monocle.position = MONOCLE_POS
	_apply_pose(0, false)
	_fx.set_shader_parameter(&"dissolve", 0.0)
	_fx.set_shader_parameter(&"flash_amount", 0.0)
	hurtbox.active = true
	contact.enabled = true
	attack_label.text = ""


func mouth_position() -> Vector2:
	return _head.global_position + Vector2(-10, 68) * _upper.scale


## Ursprung der Klecks-Spirale (Phase 3): Mitte des Kopfes.
func spiral_origin() -> Vector2:
	return _head.global_position


func _physics_process(_delta: float) -> void:
	if _flash_frames > 0:
		_flash_frames -= 1
		if _flash_frames == 0:
			_fx.set_shader_parameter(&"flash_amount", 0.0)


func _on_hurt(damage: int, _source: Node) -> bool:
	if not brain.is_fighting():
		return brain.state != BossBrain.State.DEAD  # vor dem Kampf Schüsse schlucken
	brain.take_damage(damage)
	hits_taken += 1
	_flash_frames = 2
	_fx.set_shader_parameter(&"flash_amount", 0.35)
	if hits_taken % 6 == 0:
		AudioDirector.play_sfx(&"boss_tink")  # hörbarer Fortschritt
	return true


func _on_telegraph(attack: BossAttack, windup: float) -> void:
	attack_label.text = attack.display_name
	AudioDirector.play_sfx(attack.telegraph_sfx)
	_play(attack.telegraph_anim, windup)


func _on_attack(attack: BossAttack) -> void:
	_play(StringName(String(attack.telegraph_anim).replace("telegraph_", "attack_")), attack.active_time)


func _on_phase_changed(index: int) -> void:
	AudioDirector.play_sfx(&"phase_change")
	Game.shake(10.0, 0.5)
	_apply_pose(index, true)
	Events.boss_phase_changed.emit(index)


## Phase 1: thront im Tintenfass. Phase 2: steigt aus dem Fass und schwebt.
## Phase 3: rammt die Feder in den Tisch, nur noch der riesige Kopf ist zu sehen.
func _apply_pose(phase: int, animate: bool) -> void:
	if _pose_tween:
		_pose_tween.kill()
	var target_pos: Vector2 = [Vector2.ZERO, Vector2(0, -150), Vector2(-60, 170)][phase]
	var target_scale: Vector2 = [Vector2.ONE, Vector2.ONE, Vector2(1.5, 1.5)][phase]
	var hurt_size: Vector2 = [Vector2(320, 520), Vector2(320, 840), Vector2(420, 620)][phase]
	_inkwell.visible = phase != 2
	attack_label.position.y = [-640.0, -880.0, -820.0][phase]
	(_hurt_shape.shape as RectangleShape2D).size = hurt_size
	_hurt_shape.position = Vector2(0, -hurt_size.y * 0.5)
	if not animate:
		_upper.position = target_pos
		_upper.scale = target_scale
		return
	_pose_tween = create_tween()
	_pose_tween.tween_property(_upper, "position", target_pos, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pose_tween.parallel().tween_property(_upper, "scale", target_scale, 1.2)
	if phase == 1:  # schweben
		_pose_tween.tween_property(_upper, "position:y", target_pos.y - 24.0, 0.9).set_trans(Tween.TRANS_SINE)
		_pose_tween.tween_property(_upper, "position:y", target_pos.y, 0.9).set_trans(Tween.TRANS_SINE)
		_pose_tween.set_loops()


func _on_rage() -> void:
	AudioDirector.play_sfx(&"boss_gong")
	var tw := create_tween()
	tw.tween_property(_monocle, "position", MONOCLE_POS + Vector2(14, 420), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	Events.boss_rage.emit()


func _on_defeated() -> void:
	hurtbox.active = false
	contact.enabled = false
	attack_label.text = ""
	if _anim:
		_anim.kill()
	AudioDirector.play_sfx(&"boss_laugh")
	Game.shake(12.0, 0.6)
	_anim = create_tween()
	_anim.tween_method(func(v: float) -> void: _fx.set_shader_parameter(&"dissolve", v), 0.0, 1.0, 1.2)
	_anim.tween_callback(func() -> void: visual.visible = false)
	Events.boss_defeated.emit()


## Platzhalter für AnimationPlayer-Clips (Namen nach Vertrag A3 → A2).
func _play(anim: StringName, duration: float) -> void:
	if _anim:
		_anim.kill()
	_head.scale = Vector2.ONE
	_head.rotation = 0.0
	_quill_arm.rotation = 0.0
	_anim = create_tween()
	match anim:
		&"telegraph_ink_spit":  # Wangen blähen
			_anim.tween_property(_head, "scale", Vector2(1.18, 1.1), duration).set_trans(Tween.TRANS_SINE)
		&"attack_ink_spit":
			_anim.tween_property(_head, "scale", Vector2(0.92, 1.05), 0.08)
			_anim.tween_property(_head, "scale", Vector2.ONE, 0.2)
		&"telegraph_quill":  # schreibt auf Pergament
			var steps := maxi(int(duration / 0.1), 2)
			for i in steps:
				_anim.tween_property(_quill_arm, "rotation", 0.35 if i % 2 == 0 else -0.1, duration / steps)
		&"attack_quill":
			_anim.tween_property(_quill_arm, "rotation", -0.9, 0.12)
			_anim.tween_property(_quill_arm, "rotation", 0.0, 0.3)
		&"telegraph_seal":  # hebt das Siegel
			_anim.tween_property(_seal_arm, "position", SEAL_REST + Vector2(0, -200), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		&"attack_seal":
			_anim.tween_property(_seal_arm, "position", SEAL_REST, 0.12)
		&"telegraph_paper":  # faltet Papier
			var steps := maxi(int(duration / 0.12), 2)
			for i in steps:
				_anim.tween_property(_quill_arm, "rotation", 0.6 if i % 2 == 0 else 0.0, duration / steps)
		&"telegraph_wave":  # Fass blubbert, Kopf bläht
			_anim.tween_property(_head, "scale", Vector2(1.1, 1.25), duration).set_trans(Tween.TRANS_ELASTIC)
		&"telegraph_whistle":  # Pfeife
			_anim.tween_property(_head, "rotation", -0.3, duration * 0.5)
			_anim.tween_property(_head, "rotation", 0.0, duration * 0.5)
		&"telegraph_spiral":  # Kopf rotiert, Lachen
			_anim.tween_property(_head, "rotation", TAU, duration).set_trans(Tween.TRANS_QUAD)
		&"telegraph_strike":  # holt mit der Feder aus
			_anim.tween_property(_head, "rotation", 0.35, duration).set_trans(Tween.TRANS_BACK)
		&"attack_strike":
			_anim.tween_property(_head, "rotation", -0.2, 0.1)
			_anim.tween_property(_head, "rotation", 0.0, 0.3)
		&"intro":
			_anim.tween_property(_head, "rotation", -0.12, duration * 0.25)
			_anim.tween_property(_head, "rotation", 0.12, duration * 0.25)
			_anim.tween_property(_head, "rotation", 0.0, duration * 0.25)
		_:  # kein Clip für diesen Namen
			_anim.kill()
			_anim = null


func _build_graybox() -> void:
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	# Tintenfass (Zeichnung art/reginald/inkwell.svg, Ursprung: Boden Mitte)
	_inkwell = Node2D.new()
	_inkwell.use_parent_material = true
	visual.add_child(_inkwell)
	_inkwell.add_child(EnemyBase.sprite(preload("res://art/reginald/inkwell.svg"), Vector2(0, -162)))
	# Oberkörper (Kopf + Arme), bewegt sich je Phase
	_upper = Node2D.new()
	_upper.use_parent_material = true
	visual.add_child(_upper)
	_arm_lines = [_hose(), _hose()]
	_head = Node2D.new()
	_head.use_parent_material = true
	_head.position = Vector2(0, -420)
	_upper.add_child(_head)
	_head.add_child(EnemyBase.sprite(preload("res://art/reginald/head.svg"), Vector2(0, -10)))
	_monocle = EnemyBase.sprite(preload("res://art/reginald/monocle.svg"), MONOCLE_POS)
	_head.add_child(_monocle)
	# Federkiel-Arm
	_quill_arm = Node2D.new()
	_quill_arm.position = Vector2(-150, -300)
	_quill_arm.use_parent_material = true
	_upper.add_child(_quill_arm)
	_quill_arm.add_child(EnemyBase.sprite(preload("res://art/reginald/quill_arm.svg"), Vector2(-37.5, -78.5)))
	# Siegel-Arm
	_seal_arm = Node2D.new()
	_seal_arm.position = SEAL_REST
	_seal_arm.use_parent_material = true
	_upper.add_child(_seal_arm)
	_seal_arm.add_child(EnemyBase.sprite(preload("res://art/reginald/seal_arm.svg"), Vector2(0, -25)))


func _hose() -> Line2D:
	var l := Line2D.new()
	l.width = 11.0
	l.default_color = Palette.INK
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.antialiased = true
	l.use_parent_material = true
	_upper.add_child(l)
	return l


## Rubber-Hose-Arme vom Kragen zu den Handschuhen, folgen jeder Pose.
func _process(_delta: float) -> void:
	var collar := _head.position + Vector2(0, 120)
	var ends := [_quill_arm.position, _seal_arm.position]
	for i in 2:
		var a := collar + Vector2(-60.0 if i == 0 else 60.0, 0)
		var b: Vector2 = ends[i]
		var ctrl := (a + b) * 0.5 + Vector2(-40.0 if i == 0 else 40.0, 40)
		var pts := PackedVector2Array()
		for k in 9:
			var t := k / 8.0
			pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
		_arm_lines[i].points = pts
