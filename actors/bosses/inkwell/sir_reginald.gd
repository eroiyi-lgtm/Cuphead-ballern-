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

var _head: Node2D
var _quill_arm: Node2D
var _seal_arm: Node2D
var _monocle: Polygon2D
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
	_seal_arm.position = Vector2(150, -330)
	_monocle.visible = true
	_monocle.position = Vector2.ZERO
	_fx.set_shader_parameter(&"dissolve", 0.0)
	_fx.set_shader_parameter(&"flash_amount", 0.0)
	hurtbox.active = true
	contact.enabled = true
	attack_label.text = ""


func mouth_position() -> Vector2:
	return global_position + Vector2(-70, -430)


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
	_fx.set_shader_parameter(&"flash_amount", 0.8)
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
	Events.boss_phase_changed.emit(index)


func _on_rage() -> void:
	AudioDirector.play_sfx(&"boss_gong")
	var tw := create_tween()
	tw.tween_property(_monocle, "position", Vector2(30, 420), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
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
			_anim.tween_property(_seal_arm, "position", Vector2(150, -520), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		&"attack_seal":
			_anim.tween_property(_seal_arm, "position", Vector2(150, -330), 0.12)
		&"intro":
			_anim.tween_property(_head, "rotation", -0.12, duration * 0.25)
			_anim.tween_property(_head, "rotation", 0.12, duration * 0.25)
			_anim.tween_property(_head, "rotation", 0.0, duration * 0.25)


func _build_graybox() -> void:
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	# Tintenfass
	visual.add_child(EnemyBase.poly([Vector2(-180, 0), Vector2(180, 0), Vector2(150, -280), Vector2(-150, -280)], Palette.INK))
	visual.add_child(EnemyBase.poly([Vector2(-150, -150), Vector2(150, -150), Vector2(145, -200), Vector2(-145, -200)], Palette.BOSS_GOLD))
	visual.add_child(EnemyBase.poly([Vector2(-90, -280), Vector2(90, -280), Vector2(80, -320), Vector2(-80, -320)], Palette.INK.lightened(0.15)))
	# Kopf: Federhalter-Spitze mit Gesicht, Perücke, Monokel
	_head = Node2D.new()
	_head.position = Vector2(0, -420)
	visual.add_child(_head)
	_head.add_child(EnemyBase.poly([Vector2(-80, 100), Vector2(80, 100), Vector2(0, -150)], Palette.BOSS_GOLD))
	_head.add_child(EnemyBase.ellipse(Vector2(0, 10), Vector2(70, 80), Palette.PAPER))
	for p in [Vector2(-75, -30), Vector2(-85, 30), Vector2(75, -30), Vector2(85, 30), Vector2(0, -80)]:
		_head.add_child(EnemyBase.ellipse(p, Vector2(32, 32), Color.WHITE))
	_head.add_child(EnemyBase.ellipse(Vector2(-25, -5), Vector2(10, 14), Palette.INK))
	_head.add_child(EnemyBase.ellipse(Vector2(-70, 15), Vector2(26, 16), Palette.INK))  # Mund
	_monocle = EnemyBase.ellipse(Vector2(25, -5), Vector2(18, 18), Palette.BOSS_GOLD)
	_head.add_child(_monocle)
	# Federkiel-Arm
	_quill_arm = Node2D.new()
	_quill_arm.position = Vector2(-120, -330)
	visual.add_child(_quill_arm)
	_quill_arm.add_child(EnemyBase.poly([Vector2(0, 0), Vector2(-20, -10), Vector2(-60, -150), Vector2(-40, -150)], Color.WHITE))
	_quill_arm.add_child(EnemyBase.ellipse(Vector2(0, 0), Vector2(16, 16), Color.WHITE))
	# Siegel-Arm
	_seal_arm = Node2D.new()
	_seal_arm.position = Vector2(150, -330)
	visual.add_child(_seal_arm)
	_seal_arm.add_child(EnemyBase.ellipse(Vector2.ZERO, Vector2(16, 16), Color.WHITE))
	_seal_arm.add_child(EnemyBase.ellipse(Vector2(0, -30), Vector2(26, 26), Palette.HERO.darkened(0.3)))
