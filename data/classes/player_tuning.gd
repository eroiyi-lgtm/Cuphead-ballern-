class_name PlayerTuning
extends Resource
## Petes Bewegungswerte (60 Hz). Im Inspector oder per .tres am Gerät nachjustierbar.

@export var run_speed := 520.0            ## px/s, ohne Beschleunigungsrampe
@export var jump_velocity := -1150.0      ## px/s, ca. 2,6 Pete-Höhen
@export var gravity_up := 3200.0          ## px/s² beim Steigen
@export var gravity_down := 4600.0        ## px/s² beim Fallen
@export var jump_cut_velocity := -350.0   ## Loslassen kappt v.y hierauf (variable Sprunghöhe)
@export var coyote_frames := 6
@export var jump_buffer_frames := 8
@export var max_fall_speed := 1600.0
@export var body_size := Vector2(40, 104)     ## Kollision mit der Welt
@export var hurtbox_size := Vector2(34, 58)   ## kleiner als das Sprite (ca. 96 × 120)
@export var hurtbox_center := Vector2(0, -52)
@export var invuln_time := 1.5
@export var blink_hz := 8.0
@export var max_hp := 3
@export var aim_deadzone := 0.3
