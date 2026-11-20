extends RefCounted

const Drifter = preload("res://src/core/systems/drifter_system.gd")

func _mk(night: int, carried: int) -> SimState:
	var s := SimState.new()
	s.night = night
	s.seed_streams(7)
	s.player = SimState.make_default_player()
	s.player["carried"] = carried
	s.random_drifters = false
	return s

func _add(s: SimState, pos: Vector3, st: String = "idle") -> Dictionary:
	var d := SimState.make_drifter("D%d" % s.next_drifter_id, pos, st)
	s.next_drifter_id += 1
	s.drifters.append(d)
	return d

func _step(s: SimState, ev: Array) -> void:
	s.tick += 1
	s.steps += 1
	Drifter.step(s, {}, ev)

func _pulse(s: SimState) -> void:
	s.extras["pulse_center"] = s.player["pos"] + Vector3(0, GameConfig.PULSE_CENTER_Y, 0)
	s.extras["pulse_tick"] = s.tick + 1   # tick cua lan step ke tiep

func _named(ev: Array, n: String) -> Array:
	var r := []
	for e in ev:
		if e["name"] == n:
			r.append(e)
	return r

func run(t: TS) -> void:
	# --- timeline idle -> chase -> steal -> flee -> removed ---
	var s := _mk(2, 7)
	var d := _add(s, Vector3(10, 0, 0))
	var ev := []
	_step(s, ev)
	t.eq(d["state"], "chase", "idle->chase khi carried>=5 va <=15m")
	var n_chase := int(ceil((10.0 - GameConfig.DRIFTER_STEAL_DIST) / (GameConfig.DRIFTER_SPEED * GameConfig.DT)))
	var steal_at := -1
	for i in range(2, 200):
		_step(s, ev)
		if d["has_stolen"]:
			steal_at = i
			break
	t.eq(steal_at, n_chase, "tick cuop = ceil(8.8/(7*DT)) = 76")
	var st := _named(ev, "drifter_steal")
	t.eq(st.size(), 1, "1 event steal")
	t.eq(st[0]["data"], {"drifter_id": "D1", "amount": 3, "carried": 4}, "steal data min(3,carried)")
	t.eq(s.player["carried"], 4, "carried giam 3")
	t.eq(d["state"], "flee", "sau cuop: flee")
	t.eq(s.player["flames"], GameConfig.FLAMES, "khong mat flame")
	var x0: float = d["pos"].x
	for i in range(GameConfig.DRIFTER_FLEE_TICKS - 1):
		_step(s, ev)
	t.eq(d["state"], "flee", "van flee o tick 239")
	t.near(d["pos"].x - x0, 7.0 * GameConfig.DT * 239.0, "flee 7 m/s ra xa", 0.01)
	_step(s, ev)
	t.eq(d["state"], "removed", "removed sau 240 tick flee")
	t.eq(d["stolen"], 0, "mote cuop bien mat")
	t.eq(s.player["carried"], 4, "khong tra lai")
	_step(s, ev)
	t.eq(s.drifters.size(), 0, "removed bi don o tick sau")
	t.eq(_named(ev, "drifter_steal").size(), 1, "chi 1 steal")

	# steal amount = min(3, carried)
	s = _mk(2, 5)
	d = _add(s, Vector3(1.0, 0, 0))
	ev = []
	_step(s, ev)
	t.eq(_named(ev, "drifter_steal")[0]["data"]["amount"], 3, "carried 5 -> cuop 3")
	t.eq(s.player["carried"], 2, "con 2")
	# once per drifter: khong cuop lai
	for i in range(20):
		_step(s, ev)
	t.eq(_named(ev, "drifter_steal").size(), 1, "khong cuop lan 2")
	# carried 6 -> 3 (carried >= 3 nhung < 5 sau)
	s = _mk(2, 6)
	d = _add(s, Vector3(1.0, 0, 0))
	ev = []
	_step(s, ev)
	t.eq(s.player["carried"], 3, "carried 6 -> 3")

	# --- carried < 5: khong aggro ---
	s = _mk(2, 4)
	d = _add(s, Vector3(3, 0, 0))
	ev = []
	for i in range(30):
		_step(s, ev)
	t.eq(d["state"], "idle", "carried 4: idle")
	t.eq(_named(ev, "drifter_steal").size(), 0, "carried 4: khong cuop")
	s = _mk(2, 9)
	d = _add(s, Vector3(20, 0, 0))
	_step(s, [])
	t.eq(d["state"], "idle", "xa 20m: idle")
	s = _mk(2, 9)
	d = _add(s, Vector3(12, 0, 0))
	_step(s, [])
	t.eq(d["state"], "chase", "chase")
	s.player["carried"] = 4
	_step(s, [])
	t.eq(d["state"], "idle", "chase->idle")
	var p0: Vector3 = d["pos"]
	for i in range(30):
		_step(s, [])
	t.ok(p0.distance_to(d["pos"]) > 0.1 and p0.distance_to(d["pos"]) <= 2.0 * 30 * GameConfig.DT + 0.001, "idle wander <= 2 m/s")

	# --- pulse khi chase -> flee, khong cuop ---
	s = _mk(2, 8)
	d = _add(s, Vector3(1.0, 0, 0), "chase")
	ev = []
	_pulse(s)
	_step(s, ev)
	t.eq(d["state"], "flee", "pulse khi chase -> flee")
	t.eq(_named(ev, "drifter_steal").size(), 0, "pulse: khong cuop")
	t.eq(s.player["carried"], 8, "carried nguyen")
	t.eq(d["flee_ticks_left"], GameConfig.DRIFTER_FLEE_TICKS - 1, "flee 240 tick (da di 1)")
	s = _mk(2, 8)
	d = _add(s, Vector3(5.5, 0, 0), "chase")
	_pulse(s)
	_step(s, [])
	t.eq(d["state"], "chase", "pulse ngoai 5m: khong trung")
	s = _mk(2, 8)
	d = _add(s, Vector3(3, 0, 0), "chase")
	s.extras["pulse_center"] = Vector3.ZERO
	s.extras["pulse_tick"] = 999
	_step(s, [])
	t.eq(d["state"], "chase", "pulse_tick khac: bo qua")

	# --- pulse trung flee dang mang: tha mote, bien mat sau 120 ---
	s = _mk(2, 5)
	d = _add(s, Vector3(1.0, 0, 0))
	ev = []
	_step(s, ev)
	t.eq(d["state"], "flee", "da cuop")
	for i in range(10):
		_step(s, ev)
	s.player["pos"] = d["pos"] + Vector3(2, 0, 0)
	_pulse(s)
	var before := s.motes.size()
	_step(s, ev)
	var dr := _named(ev, "drifter_drop")
	t.eq(dr.size(), 1, "event drop")
	t.eq(dr[0]["data"], {"drifter_id": "D1", "amount": 3}, "drop data")
	t.eq(s.motes.size() - before, 3, "3 mote roi")
	t.eq(s.motes[s.motes.size() - 1]["ttl_ticks"], GameConfig.DRIFTER_DROPPED_MOTE_TTL_TICKS, "ttl 120")
	t.eq(s.motes[s.motes.size() - 1]["kind"], "dropped", "kind dropped")
	t.eq(d["stolen"], 0, "stolen = 0")
	t.eq(s.score, 0, "khong diem")
	for i in range(118):
		_step(s, ev)
	t.eq(d["state"], "flee", "chua removed o tick 119")
	_step(s, ev)
	t.eq(d["state"], "removed", "removed sau 120 tick")
	t.eq(s.player["carried"], 2, "carried khong doi")

	# --- ignores invuln / safe zone, khong mat flame ---
	s = _mk(2, 6)
	s.player["invuln_ticks"] = 50
	s.lanterns.append(SimState.make_lantern("L1", Vector3.ZERO))
	s.lanterns[0]["lit"] = true
	d = _add(s, Vector3(0.5, 0, 0), "chase")
	ev = []
	_step(s, ev)
	t.eq(_named(ev, "drifter_steal").size(), 1, "cuop du invuln + safe zone")
	t.eq(s.player["flames"], GameConfig.FLAMES, "khong mat flame")

	# --- sinh: tick 1200, 2400; max 2 alive; id D1,D2 ---
	s = _mk(2, 0)
	s.random_drifters = true
	var spawned := {}
	for i in range(1, 3601):
		_step(s, [])
		if s.drifters.size() > 0 and not spawned.has(s.drifters.size()):
			spawned[s.drifters.size()] = i
	t.eq(spawned.get(1, -1), 1200, "D1 tick 1200")
	t.eq(spawned.get(2, -1), 2400, "D2 tick 2400")
	t.eq(s.drifters.size(), 2, "max 2 alive (tick 3600 khong sinh them)")
	t.eq([s.drifters[0]["id"], s.drifters[1]["id"]], ["D1", "D2"], "ids")
	t.ok(Vector2(s.drifters[0]["pos"].x, s.drifters[0]["pos"].z).length() <= GameConfig.island_radius(2), "spawn tren dao")
	var s2 := _mk(2, 0)
	s2.random_drifters = true
	for i in range(1, 2401):
		_step(s2, [])
	var s4 := _mk(2, 0)
	s4.random_drifters = true
	for i in range(1, 2401):
		_step(s4, [])
	t.eq(s2.drifters[0]["pos"], s4.drifters[0]["pos"], "tat dinh cung seed")
	t.eq(s2.drifters[1]["pos"], s4.drifters[1]["pos"], "tat dinh D2")
	s = _mk(1, 0)
	s.random_drifters = true
	for i in range(1, 1301):
		_step(s, [])
	t.eq(s.drifters.size(), 0, "Dem 1: khong Gio Lac")
	# --- paused: no-op ---
	s = _mk(2, 8)
	s.random_drifters = true
	d = _add(s, Vector3(5, 0, 0))
	s.paused = true
	var pos0: Vector3 = d["pos"]
	var cnt := s.drifter_spawn_ticks_left
	for i in range(1300):
		_step(s, [])
	t.eq(d["pos"], pos0, "paused: khong di chuyen")
	t.eq(s.drifter_spawn_ticks_left, cnt, "paused: dem sinh dung yen")
	t.eq(s.drifters.size(), 1, "paused: khong sinh")
