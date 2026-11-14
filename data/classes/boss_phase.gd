class_name BossPhase
extends Resource

@export var display_name := ""
@export var hp := 1000
@export var attacks: Array[BossAttack] = []
@export var speed_mult := 1.0
@export var rage_below_fraction := 0.0   ## z. B. 0,3 = Rage ab 30 % HP (Phase 3)
