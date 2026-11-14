class_name BossAttack
extends Resource
## Eine Boss-Attacke: TELEGRAPH → ACTIVE → RECOVERY. Das Muster selbst ist ein BossPattern-Skript.

@export var id: StringName
@export var display_name := ""
@export var weight := 1.0
@export var windup_time := 0.6           ## sichtbare + hörbare Vorwarnung, nie unter 0,5 s
@export var active_time := 1.2
@export var recovery_time := 0.6
@export var telegraph_anim: StringName   ## Vertrag A3 → A2: telegraph_*, attack_*, recover_*
@export var telegraph_sfx: StringName    ## Vertrag A3 → A4
@export var pattern: Script
@export var params := {}
