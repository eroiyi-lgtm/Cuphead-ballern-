class_name BossBrain
extends Node
## Generische Boss-KI: Phasen nach HP, Attacken aus gewichtetem Beutel (max. 2 Wiederholungen),
## Ablauf TELEGRAPH → ACTIVE → RECOVERY. Nie zwei Muster gleichzeitig. Alle Werte aus BossData.

signal telegraph_started(attack: BossAttack, windup: float)
signal attack_started(attack: BossAttack)
signal phase_changed(index: int)
signal rage_started
signal defeated

enum State { IDLE, INTRO, TELEGRAPH, ACTIVE, RECOVERY, TRANSITION, DEAD }

var data: BossData
var state := State.IDLE
var phase_index := 0
var phase_hp := 0
var total_damage := 0
var current: BossAttack
var raging := false
var forced_attack: StringName = &""   ## Debug: nächste Attacke erzwingen

var _patterns := {}
var _timer := 0.0
var _last_id: StringName = &""
var _repeats := 0


func setup(boss_data: BossData, boss: Node2D) -> void:
	data = boss_data
	for phase in data.phases:
		for attack in phase.attacks:
			if _patterns.has(attack.id):
				continue
			var p: BossPattern = attack.pattern.new()
			p.name = String(attack.id)
			p.attack = attack
			p.boss = boss
			p.brain = self
			boss.add_child(p)
			_patterns[attack.id] = p
	reset()


func start() -> void:
	reset()
	_set_state(State.INTRO, data.intro_time)


func reset() -> void:
	state = State.IDLE
	phase_index = 0
	phase_hp = data.phases[0].hp
	total_damage = 0
	current = null
	raging = false
	_last_id = &""
	_repeats = 0
	for p: BossPattern in _patterns.values():
		p.reset()


func total_hp() -> int:
	return data.total_hp()


func hp_left() -> int:
	return total_hp() - total_damage


func speed_mult() -> float:
	return data.phases[phase_index].speed_mult * (data.rage_speed_mult if raging else 1.0)


func is_fighting() -> bool:
	return state != State.IDLE and state != State.DEAD


func take_damage(amount: int) -> void:
	if state == State.IDLE or state == State.DEAD or state == State.TRANSITION:
		return
	phase_hp -= amount
	total_damage = mini(total_damage + amount, total_hp())
	var phase := data.phases[phase_index]
	if not raging and phase.rage_below_fraction > 0.0 and phase_hp <= phase.hp * phase.rage_below_fraction:
		raging = true
		rage_started.emit()
	if phase_hp <= 0:
		_end_phase()


func _physics_process(delta: float) -> void:
	if state == State.IDLE or state == State.DEAD:
		return
	_timer -= delta
	if state == State.ACTIVE and current:
		_patterns[current.id].tick(delta)
	if _timer > 0.0:
		return
	match state:
		State.INTRO, State.TRANSITION, State.RECOVERY:
			_begin_next_attack()
		State.TELEGRAPH:
			_set_state(State.ACTIVE, current.active_time / speed_mult())
			_patterns[current.id].activate()
			attack_started.emit(current)
		State.ACTIVE:
			_patterns[current.id].deactivate()
			var pause := current.recovery_time * (data.rage_pause_mult if raging else 1.0)
			_set_state(State.RECOVERY, maxf(pause, 0.1))


func _begin_next_attack() -> void:
	current = _draw_attack()
	var windup := maxf(current.windup_time / speed_mult(), data.min_telegraph)
	_set_state(State.TELEGRAPH, windup)
	_patterns[current.id].telegraph(windup)
	telegraph_started.emit(current, windup)


func _draw_attack() -> BossAttack:
	var attacks := data.phases[phase_index].attacks
	if forced_attack != &"":
		for a in attacks:
			if a.id == forced_attack:
				forced_attack = &""
				_note_pick(a)
				return a
		forced_attack = &""
	var pool: Array[BossAttack] = []
	for a in attacks:
		if a.id == _last_id and _repeats >= data.max_repeats:
			continue
		pool.append(a)
	if pool.is_empty():
		pool = attacks.duplicate()
	var total := 0.0
	for a in pool:
		total += a.weight
	var r := Game.rng.randf() * total
	var pick := pool[pool.size() - 1]
	for a in pool:
		r -= a.weight
		if r <= 0.0:
			pick = a
			break
	_note_pick(pick)
	return pick


func _note_pick(a: BossAttack) -> void:
	if a.id == _last_id:
		_repeats += 1
	else:
		_last_id = a.id
		_repeats = 1


func _end_phase() -> void:
	if current and state == State.ACTIVE:
		_patterns[current.id].deactivate()
	for p: BossPattern in _patterns.values():
		p.cancel()
	current = null
	if phase_index >= data.phases.size() - 1:
		state = State.DEAD
		defeated.emit()
		return
	phase_index += 1
	phase_hp = data.phases[phase_index].hp
	raging = false
	_last_id = &""
	_repeats = 0
	phase_changed.emit(phase_index)
	_set_state(State.TRANSITION, data.phase_transition_time)


func _set_state(s: State, duration: float) -> void:
	state = s
	_timer = duration
