extends CanvasLayer
## HUD: 3 HP-Karten, Titelkarte, Todes- und Siegbildschirm (je ein Button "Nochmal"), Pause.
## Die Boss-Fortschrittsleiste erscheint erst im Todesbildschirm.

const CARD_SIZE := Vector2(62, 86)

var _root: Control
var _cards: Array[Panel] = []
var _intro: Control
var _intro_title: Label
var _intro_count: Label
var _death: PanelContainer
var _death_info: Label
var _progress: Control
var _progress_value := 0.0
var _progress_markers: Array[float] = []
var _win: PanelContainer
var _win_info: Label
var _pause: Control
var _death_pending := 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_cards()
	_build_intro()
	_build_death()
	_build_win()
	_build_pause()
	Events.player_hp_changed.connect(_on_hp)
	Events.player_died.connect(_on_died)
	Events.level_restarted.connect(_on_restarted)
	Events.level_completed.connect(_on_completed)
	Events.pause_changed.connect(func(p: bool) -> void: _pause.visible = p)
	_on_hp(3)


## Titelkarte mit Projektor-Countdown, 1,5 s. Nur beim ersten Start, nicht beim Neustart.
func play_intro() -> void:
	_intro.visible = true
	for n in ["3", "2", "1"]:
		_intro_count.text = n
		_intro_count.scale = Vector2(1.4, 1.4)
		create_tween().tween_property(_intro_count, "scale", Vector2.ONE, 0.2)
		await get_tree().create_timer(0.5).timeout
	_intro.visible = false


func is_death_screen_visible() -> bool:
	return _death.visible


func _unhandled_input(event: InputEvent) -> void:
	if (_death.visible or _win.visible) and (event.is_action_pressed("jump") or event.is_action_pressed("fire")):
		get_viewport().set_input_as_handled()
		Game.restart_level()


func _on_hp(hp: int) -> void:
	for i in _cards.size():
		_cards[i].modulate = Color.WHITE if i < hp else Color(1, 1, 1, 0.18)
	if hp == 1:
		var tw := _cards[0].create_tween().set_loops(3)
		tw.tween_property(_cards[0], "modulate", Color(1.6, 0.6, 0.5), 0.15)
		tw.tween_property(_cards[0], "modulate", Color.WHITE, 0.15)


func _on_died() -> void:
	_death_pending += 1
	var token := _death_pending
	await get_tree().create_timer(0.8, true, false, true).timeout
	if token != _death_pending or Game.running:
		return
	_progress_value = Game.level.get_progress() if Game.level else 0.0
	_progress_markers.clear()
	if Game.level:
		_progress_markers.assign(Game.level.get_progress_markers())
	_death_info.text = "Zeit %s  ·  Versuch %d" % [_fmt_time(Game.run_time), Game.attempt_deaths + 1]
	_progress.queue_redraw()
	_death.visible = true
	get_tree().set_deferred(&"paused", true)  # nicht mitten im Timer-Callback pausieren


func _on_restarted() -> void:
	_death_pending += 1
	_death.visible = false
	_win.visible = false
	_pause.visible = false


func _on_completed(time_s: float, deaths: int, grade: String) -> void:
	_death_pending += 1
	var token := _death_pending
	await get_tree().create_timer(1.6, true, false, true).timeout
	if token != _death_pending:
		return
	_win_info.text = "Note %s\nZeit %s  ·  Tode %d\nBestzeit %s" % [grade, _fmt_time(time_s), deaths, _fmt_time(SaveData.best_time)]
	_win.visible = true


# --- Aufbau -----------------------------------------------------------------

func _style(bg: Color, border: Color, width := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(12)
	s.set_content_margin_all(28)
	return s


func _label(text: String, size: int, color := Palette.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(440, 140)
	b.add_theme_font_size_override(&"font_size", 60)
	b.add_theme_stylebox_override(&"normal", _style(Palette.BOSS_GOLD, Palette.INK))
	b.add_theme_stylebox_override(&"hover", _style(Palette.BOSS_GOLD.lightened(0.1), Palette.INK))
	b.add_theme_stylebox_override(&"pressed", _style(Palette.BOSS_GOLD.darkened(0.2), Palette.INK))
	b.add_theme_color_override(&"font_color", Palette.INK)
	b.add_theme_color_override(&"font_pressed_color", Palette.INK)
	b.add_theme_color_override(&"font_hover_color", Palette.INK)
	b.pressed.connect(Game.restart_level)
	return b


func _build_cards() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(40, 30)
	box.add_theme_constant_override(&"separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	for i in 3:
		var card := Panel.new()
		card.custom_minimum_size = CARD_SIZE
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s := _style(Palette.PAPER, Palette.INK, 5)
		s.set_corner_radius_all(8)
		card.add_theme_stylebox_override(&"panel", s)
		var heart := _label("♥", 44, Palette.HERO)
		heart.set_anchors_preset(Control.PRESET_FULL_RECT)
		heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(heart)
		box.add_child(card)
		_cards.append(card)


func _build_intro() -> void:
	_intro = ColorRect.new()
	(_intro as ColorRect).color = Palette.INK
	_intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_intro)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_intro.add_child(v)
	v.add_child(_label("PROJECT INKWELL  ·  LEVEL 1", 34, Palette.BOSS_GOLD))
	_intro_title = _label("DAS SCHREIBTISCH-DUELL", 92, Palette.PAPER)
	v.add_child(_intro_title)
	_intro_count = _label("3", 140, Palette.PAPER)
	_intro_count.pivot_offset = Vector2(60, 90)
	v.add_child(_intro_count)
	_intro.visible = false


func _build_death() -> void:
	_death = _center_panel()
	var v := _death.get_child(0) as VBoxContainer
	v.add_child(_label("K.O.!", 120, Palette.HERO))
	_death_info = _label("", 38)
	v.add_child(_death_info)
	_progress = Control.new()
	_progress.custom_minimum_size = Vector2(900, 90)
	_progress.draw.connect(_draw_progress)
	v.add_child(_progress)
	v.add_child(_button("Nochmal"))


func _build_win() -> void:
	_win = _center_panel()
	var v := _win.get_child(0) as VBoxContainer
	v.add_child(_label("SIEG!", 120, Palette.BOSS_GOLD.darkened(0.2)))
	_win_info = _label("", 44)
	v.add_child(_win_info)
	v.add_child(_button("Nochmal"))


func _build_pause() -> void:
	_pause = ColorRect.new()
	(_pause as ColorRect).color = Color(Palette.INK, 0.6)
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.visible = false
	_root.add_child(_pause)
	var l := _label("PAUSE\nTippen zum Weiterspielen", 72, Palette.PAPER)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause.add_child(l)
	_pause.gui_input.connect(_on_pause_input)


func _on_pause_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.is_pressed():
		Game.toggle_pause()


func _center_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", _style(Palette.PAPER, Palette.INK, 8))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override(&"separation", 22)
	p.add_child(v)
	_root.add_child(p)
	return p


func _draw_progress() -> void:
	var w := _progress.size.x
	var y := _progress.size.y * 0.5
	_progress.draw_line(Vector2(0, y), Vector2(w, y), Palette.INK, 8.0)
	for m in _progress_markers:
		_progress.draw_line(Vector2(w * m, y - 22), Vector2(w * m, y + 22), Palette.INK, 6.0)
	_progress.draw_circle(Vector2(w, y), 18.0, Palette.BOSS_GOLD)  # Ziel: Reginald
	_progress.draw_circle(Vector2(w * _progress_value, y), 22.0, Palette.HERO)  # Pete


static func _fmt_time(t: float) -> String:
	return "%d:%05.2f" % [int(t) / 60, fmod(t, 60.0)]
