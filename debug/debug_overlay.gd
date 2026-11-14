extends CanvasLayer
## Nur in Debug-Builds. F1 Hitboxen · F2 zur Arena · F3 Phase überspringen · F4 nächste Attacke
## erzwingen · F5 Pattern-Seed fixieren/lösen · F6 Touch-Steuerung am Desktop · F7 Film-Look ·
## F8 God-Mode.

var _label: Label
var _overlay: HitboxOverlay
var _attack_cycle := 0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		queue_free()
		return
	_label = Label.new()
	_label.position = Vector2(20, 130)
	_label.add_theme_font_size_override(&"font_size", 22)
	_label.add_theme_color_override(&"font_color", Palette.INK)
	_label.add_theme_color_override(&"font_outline_color", Palette.PAPER)
	_label.add_theme_constant_override(&"outline_size", 6)
	add_child(_label)


func _process(_delta: float) -> void:
	var lines := ["FPS %d" % Engine.get_frames_per_second()]
	if Game.level:
		var boss: SirReginald = Game.level.boss
		var b := boss.brain
		lines.append("Boss %s · Phase %d · HP %d/%d · %s" % [
			BossBrain.State.keys()[b.state], b.phase_index + 1, b.hp_left(), b.total_hp(),
			b.current.id if b.current else "-"])
		lines.append("Geschosse %d · Seed %d%s · Neustart %.2f ms" % [
			Game.pool.active_count(), Game.current_seed, " (fix)" if Game.fixed_seed != 0 else "",
			Game.last_restart_ms])
		lines.append("Musik %s · Takt %d%s" % [AudioDirector.state, AudioDirector.bar, " · GOD" if Game.god_mode else ""])
	_label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_F1:
			if _overlay:
				_overlay.queue_free()
				_overlay = null
			elif Game.level:
				_overlay = HitboxOverlay.new()
				Game.level.add_child(_overlay)
		KEY_F2:
			if Game.level:
				Game.level.skip_to_arena()
		KEY_F3:
			if Game.level:
				var b: BossBrain = Game.level.boss.brain
				b.take_damage(maxi(b.phase_hp, 1))
		KEY_F4:
			if Game.level:
				var b: BossBrain = Game.level.boss.brain
				var attacks := b.data.phases[b.phase_index].attacks
				b.forced_attack = attacks[_attack_cycle % attacks.size()].id
				_attack_cycle += 1
		KEY_F5:
			Game.fixed_seed = 0 if Game.fixed_seed != 0 else 1930
		KEY_F6:
			var touch := get_node_or_null(^"../TouchControls")
			if touch:
				touch.set_force_visible(not touch.force_visible)
		KEY_F7:
			var fx := get_node_or_null(^"../PostFX")
			if fx:
				fx.set_enabled(not fx.visible)
		KEY_F8:
			Game.god_mode = not Game.god_mode
