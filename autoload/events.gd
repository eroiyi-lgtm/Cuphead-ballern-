extends Node
## Signal-Bus. Die vier Rollen koppeln sich nur hierüber und über .tres-Ressourcen.

signal player_hp_changed(hp: int)
signal player_died
signal boss_arena_entered
signal boss_phase_changed(phase: int)
signal boss_rage
signal boss_defeated
signal danger_level_changed(level: int)
signal level_started
signal level_restarted
signal level_completed(time_s: float, deaths: int, grade: String)
signal pause_changed(paused: bool)
