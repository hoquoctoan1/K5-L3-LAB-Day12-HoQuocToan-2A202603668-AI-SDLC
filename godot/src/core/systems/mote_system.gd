extends RefCounted
## MoteSystem (P2-B34): TTL mote roi + nhat mote (tick-order buoc 2 va 4). Respawn do spawn_system lo.
##
## HELPER cho shade_system / drifter_system:
##   MoteSystem.drop_motes(state: SimState, center: Vector3, count: int, ttl: int) -> Array
##   - tao `count` mote kind "dropped", ttl_ticks=ttl (player hit: GameConfig.DROPPED_MOTE_TTL_TICKS=480;
##     drifter: GameConfig.DRIFTER_DROPPED_MOTE_TTL_TICKS=120), id "m<next_mote_id>" (tang next_mote_id),
##     vi tri tren vong ban kinh 1.5..2.5 quanh center (XZ, y = center.y), dung state.rng_mote (tat dinh).
##   - them vao state.motes, tra ve mang mote moi. Mote co "born_tick"=state.tick: khong nhat duoc trong
##     chinh tick do (chi tu tick sau).
## v1.2 (P3-B3, TICKET-03 muc 4-5): nhat KHONG cong diem (diem +5 cong luc nap, lantern_system);
##   suc chua = SimState.capacity_of(player) = min(20, 10 + 2 * successful_lights).

const DROP_RING_MIN: float = 1.5
const DROP_RING_MAX: float = 2.5

static func drop_motes(state: SimState, center: Vector3, count: int, ttl: int) -> Array:
	var made: Array = []
	for i in range(count):
		var ang: float = state.rng_mote.next_float() * TAU
		var r: float = DROP_RING_MIN + state.rng_mote.next_float() * (DROP_RING_MAX - DROP_RING_MIN)
		var m := SimState.make_mote("m%d" % state.next_mote_id, center + Vector3(cos(ang) * r, 0.0, sin(ang) * r), "dropped", ttl)
		m["born_tick"] = state.tick
		state.next_mote_id += 1
		state.motes.append(m)
		made.append(m)
	return made

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	# TTL: giam moi tick, het (0) thi xoa
	var alive: Array = []
	for m in state.motes:
		var ttl: int = int(m.get("ttl_ticks", -1))
		if ttl >= 0 and str(m.get("kind", "random")) == "dropped":
			ttl -= 1
			m["ttl_ticks"] = ttl
			if ttl <= 0:
				continue
		alive.append(m)
	state.motes = alive
	var p: Dictionary = state.player
	if int(p.get("fall_wait_ticks", 0)) > 0:
		return
	var kept: Array = []
	for m in state.motes:
		if int(p["carried"]) < SimState.capacity_of(p) and int(m.get("born_tick", -1)) != state.tick:
			var dxz := Vector2(m["pos"].x - p["pos"].x, m["pos"].z - p["pos"].z).length()
			var dy: float = absf(m["pos"].y - p["pos"].y)
			if dxz <= GameConfig.PICKUP_RADIUS + 1e-4 and dy <= GameConfig.PICKUP_MAX_DY + 1e-4:
				p["carried"] = int(p["carried"]) + 1
				events.append({"name": "mote_picked", "data": {"carried": p["carried"]}})
				continue
		kept.append(m)
	state.motes = kept
