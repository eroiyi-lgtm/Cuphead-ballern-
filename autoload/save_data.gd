extends Node
## Bestzeit, Tode, Note und Optionen. Gespeichert in user://save.cfg.

const PATH := "user://save.cfg"
const GRADES := ["D", "C", "B", "A", "A+"]

var best_time := 0.0
var best_grade := ""
var deaths_total := 0
var wins := 0

# Optionen
var film_strength := 1.0      ## 0..1 Filmkorn, Kratzer, Flackern (Barrierefreiheit)
var screen_wobble := 1.0      ## 0..1 Bild-Wackeln und Screen Shake (Reisekrankheit)
var gramophone_level := 2     ## 0..2 Grammophon-Stärke
var lock_mode := "swipe"      ## "swipe": Feuer halten + Sprung nach unten wischen; "fire_hold": Lock beim Feuern
var haptics := true


func _ready() -> void:
	load_data()


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	best_time = cfg.get_value("stats", "best_time", best_time)
	best_grade = cfg.get_value("stats", "best_grade", best_grade)
	deaths_total = cfg.get_value("stats", "deaths_total", deaths_total)
	wins = cfg.get_value("stats", "wins", wins)
	film_strength = cfg.get_value("options", "film_strength", film_strength)
	screen_wobble = cfg.get_value("options", "screen_wobble", screen_wobble)
	gramophone_level = cfg.get_value("options", "gramophone_level", gramophone_level)
	lock_mode = cfg.get_value("options", "lock_mode", lock_mode)
	haptics = cfg.get_value("options", "haptics", haptics)


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "best_time", best_time)
	cfg.set_value("stats", "best_grade", best_grade)
	cfg.set_value("stats", "deaths_total", deaths_total)
	cfg.set_value("stats", "wins", wins)
	cfg.set_value("options", "film_strength", film_strength)
	cfg.set_value("options", "screen_wobble", screen_wobble)
	cfg.set_value("options", "gramophone_level", gramophone_level)
	cfg.set_value("options", "lock_mode", lock_mode)
	cfg.set_value("options", "haptics", haptics)
	cfg.save(PATH)


func record_death() -> void:
	deaths_total += 1
	save_data()


func record_win(time_s: float, grade: String) -> void:
	wins += 1
	if best_time <= 0.0 or time_s < best_time:
		best_time = time_s
	if best_grade == "" or GRADES.find(grade) > GRADES.find(best_grade):
		best_grade = grade
	save_data()
