extends RefCounted
## DrifterSystem (P2-B6): Gio Lac, Dem 2-3. Goi 1 lan/tick, sau pulse_system (buoc 7). Thu tu ben trong:
## don removed cu -> pulse (tu extras) -> di chuyen (8) -> cuop (9) -> sinh (10).
## Pulse: doc state.extras["pulse_center"] (Vector3) va ["pulse_tick"]==state.tick; ban kinh 3D PULSE_RADIUS.
## Entity "removed" duoc giu 1 tick roi bi xoa khoi state.drifters o dau step ke tiep.
## Truong them (ASSUMPTION): wander_dir:Vector2, wander_ticks:int.
## Spawn point (ASSUMPTION): dao ngau nhien (rng_drifter) trong map.islands (hoac goc toa do), goc ngau nhien,
##   ban kinh = 0.9 * ban kinh dao; y = state.height_at.
## Dem sinh: state.drifter_spawn_ticks_left (1200 -> 0), sinh neu con < DRIFTER_MAX_ALIVE va random_drifters, roi dat lai 1200.

const MoteSystem = preload("res://src/core/systems/mote_system.gd")
const EDGE_FRAC: float = 0.9
const WANDER_PERIOD: int = 60

static func alive_count(state: SimState) -> int:
	var n := 0
	for d in state.drifters:
		if d["state"] != "removed":
			n += 1
	return n

static func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

static func _move(state: SimState, d: Dictionary, dir: Vector2, speed: float, keep_on_surface: bool) -> void:
	var np: Vector3 = d["pos"] + Vector3(dir.x, 0.0, dir.y) * speed * GameConfig.DT
	var h: float = state.height_at(np.x, np.z, np.y + 0.5)
	if h <= SimState.VOID_Y * 0.5:
		if keep_on_surface:
			return
	else:
		np.y = h
	d["pos"] = np

static func _start_flee(d: Dictionary, away_from: Vector3) -> void:
	var dir := _xz(d["pos"] - away_from)
	d["flee_dir"] = dir.normalized() if dir.length() > 1e-6 else Vector2(1, 0)
	d["flee_ticks_left"] = GameConfig.DRIFTER_FLEE_TICKS
	d["state"] = "flee"

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.paused or state.status != "playing":
		return
	if not GameConfig.has_drifters(state.night):
		return
	var keep: Array = []
	for d in state.drifters:
		if d["state"] != "removed":
			keep.append(d)
	state.drifters = keep
	var p: Dictionary = state.player
	var ppos: Vector3 = p["pos"]
	# --- pulse (da chot o buoc 7) ---
	if state.extras.has("pulse_center") and int(state.extras.get("pulse_tick", -1)) == state.tick:
		var pc: Vector3 = state.extras["pulse_center"]
		for d in state.drifters:
			if (d["pos"] - pc).length() > GameConfig.PULSE_RADIUS:
				continue
			if d["state"] == "chase":
				_start_flee(d, ppos)
			elif d["state"] == "flee" and int(d["stolen"]) > 0:
				var amt: int = int(d["stolen"])
				MoteSystem.drop_motes(state, d["pos"], amt, GameConfig.DRIFTER_DROPPED_MOTE_TTL_TICKS)
				d["stolen"] = 0
				d["drop_after_ticks"] = GameConfig.DRIFTER_DROPPED_MOTE_TTL_TICKS
				d["flee_ticks_left"] = GameConfig.DRIFTER_DROPPED_MOTE_TTL_TICKS
				events.append({"name": "drifter_drop", "data": {"drifter_id": d["id"], "amount": amt}})
	# --- di chuyen (8) ---
	for d in state.drifters:
		match d["state"]:
			"idle", "chase":
				var to_p := _xz(ppos - d["pos"])
				var aggro: bool = int(p["carried"]) >= GameConfig.DRIFTER_AGGRO_CARRIED and to_p.length() <= GameConfig.DRIFTER_AGGRO_DIST
				d["state"] = "chase" if aggro else "idle"
				if aggro:
					if to_p.length() > 1e-6:
						_move(state, d, to_p.normalized(), minf(GameConfig.DRIFTER_SPEED, to_p.length() / GameConfig.DT), false)
				else:
					_wander(state, d)
			"flee":
				_move(state, d, d["flee_dir"], GameConfig.DRIFTER_SPEED, false)
				d["flee_ticks_left"] = int(d["flee_ticks_left"]) - 1
				if int(d["drop_after_ticks"]) > 0:
					d["drop_after_ticks"] = int(d["drop_after_ticks"]) - 1
				if int(d["flee_ticks_left"]) <= 0:
					d["state"] = "removed"
					d["stolen"] = 0
	# --- cuop (9) ---
	for d in state.drifters:
		if d["state"] == "chase" and not bool(d["has_stolen"]):
			if _xz(ppos - d["pos"]).length() <= GameConfig.DRIFTER_STEAL_DIST and int(p["carried"]) > 0:
				var amount: int = mini(GameConfig.DRIFTER_STEAL_MAX, int(p["carried"]))
				p["carried"] = int(p["carried"]) - amount
				d["stolen"] = amount
				d["has_stolen"] = true
				_start_flee(d, ppos)
				events.append({"name": "drifter_steal", "data": {"drifter_id": d["id"], "amount": amount, "carried": int(p["carried"])}})
	# --- sinh (10) ---
	state.drifter_spawn_ticks_left -= 1
	if state.drifter_spawn_ticks_left <= 0:
		state.drifter_spawn_ticks_left = GameConfig.DRIFTER_SPAWN_EVERY_TICKS
		if state.random_drifters and alive_count(state) < GameConfig.DRIFTER_MAX_ALIVE:
			_spawn(state)

static func _wander(state: SimState, d: Dictionary) -> void:
	if int(d.get("wander_ticks", 0)) <= 0:
		var a: float = state.rng_drifter.next_float() * TAU
		d["wander_dir"] = Vector2(cos(a), sin(a))
		d["wander_ticks"] = WANDER_PERIOD
	d["wander_ticks"] = int(d["wander_ticks"]) - 1
	var before: Vector3 = d["pos"]
	_move(state, d, d["wander_dir"], GameConfig.DRIFTER_IDLE_SPEED, true)
	if d["pos"] == before:
		d["wander_ticks"] = 0

static func _spawn(state: SimState) -> void:
	var c := Vector3.ZERO
	var r: float = GameConfig.island_radius(state.night)
	var isl: Array = state.map.get("islands", [])
	if not isl.is_empty():
		var it: Dictionary = isl[state.rng_drifter.next_int(isl.size())]
		c = it["center"]
		r = float(it["radius"])
	var a: float = state.rng_drifter.next_float() * TAU
	var x: float = c.x + cos(a) * r * EDGE_FRAC
	var z: float = c.z + sin(a) * r * EDGE_FRAC
	var y: float = state.height_at(x, z, 1.0e9)
	if y <= SimState.VOID_Y * 0.5:
		y = c.y
	var d := SimState.make_drifter("D%d" % state.next_drifter_id, Vector3(x, y, z), "idle")
	state.next_drifter_id += 1
	d["wander_dir"] = Vector2.ZERO
	d["wander_ticks"] = 0
	state.drifters.append(d)
