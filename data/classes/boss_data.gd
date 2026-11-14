class_name BossData
extends Resource

@export var display_name := ""
@export var phases: Array[BossPhase] = []
@export var intro_time := 1.5
@export var phase_transition_time := 2.0
@export var min_telegraph := 0.5          ## Grundregel: mindestens 0,5 s Vorwarnung
@export var max_repeats := 2              ## kein Muster mehr als 2-mal hintereinander
@export var rage_speed_mult := 1.15       ## Rage: alles 15 % schneller
@export var rage_pause_mult := 0.8        ## Rage: Pausen 20 % kürzer


func total_hp() -> int:
	var sum := 0
	for p in phases:
		sum += p.hp
	return sum
