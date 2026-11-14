extends CanvasLayer
## Der eine PostFX-Pass über der Spielwelt (unter HUD und Touch-Steuerung).

const SHADER := preload("res://fx/shaders/vintage_film.gdshader")
const DEFAULTS := {
	&"grain_amount": 0.07, &"scratch_amount": 0.5, &"dust_amount": 0.5, &"flicker_amount": 0.03,
}

var material: ShaderMaterial
var _rect: ColorRect


func _ready() -> void:
	layer = 5
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = SHADER
	_rect.material = material
	add_child(_rect)
	apply_settings()


## Film-Look in den Optionen abschwächbar (Abnahmekriterium).
func apply_settings() -> void:
	for key: StringName in DEFAULTS:
		material.set_shader_parameter(key, DEFAULTS[key] * SaveData.film_strength)
	material.set_shader_parameter(&"wobble_px", 0.8 * SaveData.screen_wobble)


func set_enabled(on: bool) -> void:
	visible = on
