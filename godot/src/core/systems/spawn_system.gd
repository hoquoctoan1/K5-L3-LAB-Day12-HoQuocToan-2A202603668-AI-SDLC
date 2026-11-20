class_name SpawnSystem
extends RefCounted
## Sinh shade/mote theo seed + khoi tao ban dau.

static func _far_from_lit(p: Vector3, state: SimState) -> bool:
	for l in state.lanterns:
		if l.get("lit", false) and Vector2(p.x - l["pos"].x, p.z - l["pos"].z).length() < GameConfig.SAFE_RADIUS:
			return false
	return true

static func _edge_pos(state: SimState, min_player: float) -> Variant:
	for _i in range(30):
		var a := state.rng.next_float() * TAU
		var r := GameConfig.ISLAND_RADIUS - 1.0 - state.rng.next_float() * 4.0
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		if not _far_from_lit(p, state):
			continue
		if state.player.has("pos"):
			var pl: Vector3 = state.player["pos"]
			if Vector2(p.x - pl.x, p.z - pl.z).length() < min_player:
				continue
		return p
	return null

static func _spawn_shade(state: SimState, events: Array, emit: bool) -> bool:
	var p = _edge_pos(state, 15.0)
	if p == null:
		return false
	var id := "S" + str(state.next_shade_id)
	state.next_shade_id += 1
	state.shades.append({"id": id, "pos": p, "state": "chase", "stun_left": 0.0})
	if emit:
		events.append({"name": "shade_spawned", "data": {"id": id}})
	return true

static func _spawn_mote(state: SimState) -> void:
	var a := state.rng.next_float() * TAU
	var r := sqrt(state.rng.next_float()) * (GameConfig.ISLAND_RADIUS - 2.0)
	state.motes.append({"id": "m" + str(state.next_mote_id), "pos": Vector3(cos(a) * r, 0.0, sin(a) * r)})
	state.next_mote_id += 1

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing":
		return
	if state.random_shades:
		state.spawn_timer_s += GameConfig.DT
		if state.spawn_timer_s >= GameConfig.SHADE_SPAWN_INTERVAL_S:
			state.spawn_timer_s = 0.0
			if state.shades.size() < GameConfig.MAX_SHADES:
				_spawn_shade(state, events, true)
	if state.random_motes:
		if state.mote_respawn_ticks_left > 0:
			state.mote_respawn_ticks_left -= 1
		if state.mote_respawn_ticks_left <= 0 and state.motes.size() < GameConfig.INITIAL_MOTES:
			_spawn_mote(state)
			state.mote_respawn_ticks_left = GameConfig.MOTE_RESPAWN_TICKS

static func populate_initial(state: SimState) -> void:
	if state.random_motes:
		for _i in range(GameConfig.INITIAL_MOTES):
			_spawn_mote(state)
	if state.random_shades:
		for _i in range(GameConfig.INITIAL_SHADES):
			_spawn_shade(state, [], false)
	if state.lanterns.is_empty():
		for i in range(GameConfig.LANTERN_COUNT_NIGHT1):
			var a := PI / 2.0 - deg_to_rad(72.0) * i   # L1 tai (0,0,25)
			state.lanterns.append({
				"id": "L" + str(i + 1),
				"pos": Vector3(cos(a) * GameConfig.LANTERN_RING_RADIUS, 0.0, sin(a) * GameConfig.LANTERN_RING_RADIUS),
				"lit": false, "deposited": 0})
