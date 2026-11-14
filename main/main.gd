extends Node
## Main bleibt die ganze Zeit geladen. Neustart = Game.restart_level(), kein change_scene_*.

@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	await hud.play_intro()
	Game.start_level()
