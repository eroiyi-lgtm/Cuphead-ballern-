class_name WeaponTuning
extends Resource
## Feste Waffe "Tintenpistole".

@export var fire_rate := 8.5              ## Schuss/s Dauerfeuer
@export var damage := 4
@export var pellet_speed := 1800.0        ## px/s
@export var pellet_delay_frames := 2      ## Pellet startet im 2. Frame des Mündungsfeuers
@export var muzzle_flash_time := 0.125    ## 3 Zeichnungen bei 24 fps
@export var muzzle_distance := 56.0
