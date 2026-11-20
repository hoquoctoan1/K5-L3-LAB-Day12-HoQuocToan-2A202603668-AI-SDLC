class_name SpawnSystem
extends RefCounted
## Sinh shade/mote theo lich (buoc 10) + khoi tao ban dau. Contract v1.1.
## Shade: lan dau SHADE_FIRST_SPAWN_COUNT con khi dem shade_spawn_ticks_left (khoi dau 300) ve 0, sau do 1 con moi
##  shade_spawn_interval_ticks(night). Het diem hop le / dat max_shades -> bo luot (van dat lai bo dem).
##  Diem hop le: >= 15 m (XZ) tu May (moi Dem, ASSUMPTION P3), ngoai vung an toan den sang, di bo duoc.
##  Chon dao co it shade nhat truoc (hoa -> luan phien theo shade_island_cursor), diem chon bang rng_shade.
## Mote: 20 ban dau tren diem rieng biet (rng_mote); hoi sinh dau tien sau 240 lan goi step, roi moi 240; 1 mote/lan
##  tren diem trong neu < 30; khong co diem trong -> bo luot. Bo dem dung state.mote_respawn_ticks_left
##  (0 chua khoi tao -> dat 240; co extras["mote_respawn_armed"]).
## Moi shade moi o state "spawning" (SPAWNING_TICKS tick vo hai).

const _MapGeo = preload("res://src/core/maps/map_geometry.gd")
const _MapBuilder = preload("res://src/core/maps/map_builder.gd")
const _Shade = preload("res://src/core/systems/shade_system.gd")

static func _valid_points(state: SimState) -> Array:
	var out: Array = []
	var pl: Vector3 = state.player["pos"] if state.player.has("pos") else Vector3(1e6, 0, 1e6)
	var pts: Array = state.map.get("shade_spawn_points", [])
	for i in pts.size():
		var p: Vector3 = pts[i]
		if Vector2(p.x - pl.x, p.z - pl.z).length() < GameConfig.SHADE_SPAWN_MIN_PLAYER_DIST:
			continue
		if _Shade._zone_of(state, Vector2(p.x, p.z)) != null:
			continue
		if not _Shade.can_stand(state, p):
			continue
		out.append(i)
	return out

static func _spawn_shade(state: SimState, events: Array) -> bool:
	if state.shades.size() >= GameConfig.max_shades(state.night):
		return false
	var valid := _valid_points(state)
	if valid.is_empty():
		return false
	var pts: Array = state.map["shade_spawn_points"]
	var isl: Array = state.map["islands"]
	var n_isl := maxi(1, isl.size())
	var counts: Array = []
	counts.resize(n_isl)
	counts.fill(0)
	for s in state.shades:
		var k := _MapGeo.closest_island_index(state.map, s["pos"])
		if k >= 0 and k < n_isl:
			counts[k] += 1
	var by_island: Array = []
	by_island.resize(n_isl)
	for k in n_isl:
		by_island[k] = []
	for i in valid:
		var k := _MapGeo.closest_island_index(state.map, pts[i])
		by_island[clampi(k, 0, n_isl - 1)].append(i)
	var chosen := -1
	for j in n_isl:
		var k := (state.shade_island_cursor + j) % n_isl
		if by_island[k].is_empty():
			continue
		if chosen < 0 or counts[k] < counts[chosen]:
			chosen = k
	if chosen < 0:
		return false
	var cand: Array = by_island[chosen]
	var pi: int = cand[state.rng_shade.next_int(cand.size())]
	state.shade_island_cursor = (chosen + 1) % n_isl
	var id := "S" + str(state.next_shade_id)
	state.next_shade_id += 1
	var sh := SimState.make_shade(id, pts[pi], "spawning")
	sh["state_ticks_left"] = _Shade.SPAWNING_TICKS
	state.shades.append(sh)
	events.append({"name": "shade_spawned", "data": {"id": id}})
	return true

static func _spawn_mote_at_free(state: SimState) -> bool:
	var free := _MapGeo.free_mote_points(state.map, state.motes)
	if free.is_empty():
		return false
	var idx: int = free[state.rng_mote.next_int(free.size())]
	state.motes.append(SimState.make_mote("m" + str(state.next_mote_id), state.map["mote_points"][idx], "random", -1, idx))
	state.next_mote_id += 1
	return true

static func _ensure_map(state: SimState) -> void:
	if state.map.is_empty():
		state.map = _MapBuilder.build(state.night)

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	_ensure_map(state)
	if state.random_shades:
		state.shade_spawn_ticks_left -= 1
		if state.shade_spawn_ticks_left <= 0:
			var n := 1
			if not state.shade_first_spawned:
				n = GameConfig.SHADE_FIRST_SPAWN_COUNT
				state.shade_first_spawned = true
			for _i in n:
				_spawn_shade(state, events)
			state.shade_spawn_ticks_left = GameConfig.shade_spawn_interval_ticks(state.night)
	if state.random_motes:
		if not state.extras.get("mote_respawn_armed", false):
			state.extras["mote_respawn_armed"] = true
			if state.mote_respawn_ticks_left <= 0:
				state.mote_respawn_ticks_left = GameConfig.MOTE_RESPAWN_FIRST_TICKS
		state.mote_respawn_ticks_left -= 1
		if state.mote_respawn_ticks_left <= 0:
			if state.motes.size() < GameConfig.MOTE_CAP:
				_spawn_mote_at_free(state)
			state.mote_respawn_ticks_left = GameConfig.MOTE_RESPAWN_TICKS

static func populate_initial(state: SimState) -> void:
	_ensure_map(state)
	if state.lanterns.is_empty():
		for l in state.map["lanterns"]:
			state.lanterns.append(SimState.make_lantern(l["id"], l["pos"]))
	if state.random_motes:
		var pts: Array = state.map["mote_points"]
		var idx: Array = range(pts.size())
		var cnt := mini(GameConfig.INITIAL_MOTES, pts.size())
		for i in cnt:
			var j: int = i + state.rng_mote.next_int(idx.size() - i)
			var tmp = idx[i]
			idx[i] = idx[j]
			idx[j] = tmp
			state.motes.append(SimState.make_mote("m" + str(state.next_mote_id), pts[idx[i]], "random", -1, idx[i]))
			state.next_mote_id += 1
	# shade khoi dau: INITIAL_SHADES = 0 (2 con dau sinh theo lich tai tick 300)
