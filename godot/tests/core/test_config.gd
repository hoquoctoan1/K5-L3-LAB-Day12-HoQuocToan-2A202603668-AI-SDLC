extends RefCounted

func run(t: TS) -> void:
	var f := FileAccess.open("res://../game.contract.json", FileAccess.READ)
	t.ok(f != null, "doc duoc game.contract.json")
	if f == null:
		return
	var c = JSON.parse_string(f.get_as_text())
	t.eq(c["contract_version"], GameConfig.CONTRACT_VERSION, "contract_version")
	t.eq(c["contract_version"], "1.2", "contract_version 1.2")
	var want := GameConfig.tuning_dict()
	var got: Dictionary = c["tuning"]
	for k in want.keys():
		if k == "score":
			for s in want[k].keys():
				t.eq(float(got["score"][s]), float(want["score"][s]), "score." + s)
		elif k == "fall_enabled":
			t.eq(got[k], want[k], k)
		else:
			t.eq(float(got[k]), float(want[k]), k)
	for k in got.keys():
		t.ok(want.has(k), "contract khong co khoa thua: " + k)
	for k in ["dash_speed", "dash_duration_s", "dash_cooldown_s", "night2_duration_s", "night3_duration_s"]:
		t.ok(got.has(k), "contract v1.1 co khoa " + k)
	# v1.2 (TICKET-03 muc 7): khoa tuning moi va gia tri dung nhu ticket
	var v12 := {"fuel_max": 100.0, "fuel_decay_per_s": 1.0, "fuel_per_mote": 10.0, "relight_cost": 5.0,
		"win_ratio": 0.6, "drain_per_s": 5.0, "low_fuel_threshold": 30.0, "capacity_max": 20.0,
		"night1_duration_s": 240.0, "night2_duration_s": 270.0, "night3_duration_s": 300.0}
	for k in v12.keys():
		t.ok(got.has(k), "contract v1.2 co khoa " + k)
		if got.has(k):
			t.eq(float(got[k]), v12[k], "contract v1.2 " + k + " = ticket")
	t.ok(not got["score"].has("per_second_left"), "v1.2 bo thuong thoi gian (per_second_left)")
	t.eq(GameConfig.night_duration_ticks(1), 14400, "dem 1 ticks (240 s)")
	t.eq(GameConfig.night_duration_ticks(2), 16200, "dem 2 ticks (270 s)")
	t.eq(GameConfig.night_duration_ticks(3), 18000, "dem 3 ticks (300 s)")
	# don vi nguyen 1/60 fuel phai khop so thuc cua ticket
	t.eq(GameConfig.FUEL_MAX_UNITS, int(round(GameConfig.FUEL_MAX * 60.0)), "fuel max units")
	t.eq(GameConfig.FUEL_DECAY_UNITS_PER_TICK, int(round(GameConfig.FUEL_DECAY_PER_S)), "decay units/tick")
	t.eq(GameConfig.FUEL_DRAIN_UNITS_PER_TICK, int(round(GameConfig.DRAIN_PER_S)), "drain units/tick")
	t.eq(GameConfig.FUEL_UNITS_PER_MOTE, GameConfig.FUEL_PER_MOTE * 60, "units/mote")
	t.eq(GameConfig.LOW_FUEL_UNITS, int(round(GameConfig.LOW_FUEL_THRESHOLD * 60.0)), "low fuel units")
	# nguong thang = ceil(0.6 * tong den)
	t.eq(GameConfig.win_threshold(5), 3, "Dem 1 can 3/5")
	t.eq(GameConfig.win_threshold(6), 4, "Dem 2 can 4/6")
	t.eq(GameConfig.win_threshold(7), 5, "Dem 3 can 5/7")
	for n in range(1, 21):
		t.eq(GameConfig.win_threshold(n), int(ceil(0.6 * n - 1e-9)), "win_threshold(%d) = ceil(0.6n)" % n)
	# suc chua 10 + 2n, toi da 20
	var pl := SimState.make_default_player()
	t.eq(int(pl["successful_lights"]), 0, "player mac dinh successful_lights 0")
	t.eq(SimState.capacity_of(pl), 10, "capacity 0 lan thap = 10")
	pl["successful_lights"] = 3
	t.eq(SimState.capacity_of(pl), 16, "capacity 3 lan thap = 16")
	pl["successful_lights"] = 5
	t.eq(SimState.capacity_of(pl), 20, "capacity 5 lan thap = 20")
	pl["successful_lights"] = 9
	t.eq(SimState.capacity_of(pl), 20, "capacity toi da 20")
	# truong den / bong muc moi
	var L := SimState.make_lantern("L1", Vector3.ZERO)
	t.eq(int(L["fuel_units"]), 0, "den moi fuel 0")
	t.eq(L["ever_lit"], false, "den moi ever_lit false")
	t.eq(int(L["relit_count"]), 0, "den moi relit_count 0")
	t.eq(SimState.fuel_out(L), 0.0, "den tat xuat fuel 0.0")
	L["lit"] = true
	L["fuel_units"] = GameConfig.FUEL_MAX_UNITS
	t.eq(SimState.fuel_out(L), 100.0, "den day xuat 100.0")
	t.ok(SimState.has_safe_zone(L) and not SimState.is_low_fuel(L), "den day co vung an toan")
	L["fuel_units"] = GameConfig.LOW_FUEL_UNITS
	t.ok(SimState.has_safe_zone(L) and not SimState.is_low_fuel(L), "fuel dung 30 van con vung an toan")
	L["fuel_units"] = GameConfig.LOW_FUEL_UNITS - 1
	t.ok(not SimState.has_safe_zone(L) and SimState.is_low_fuel(L), "fuel 29.98 mat vung an toan")
	L["fuel_units"] = 4403   # 73.383.. -> 73.4
	t.eq(SimState.fuel_out(L), 73.4, "fuel_out lam tron 1 chu so (73.383 -> 73.4)")
	L["fuel_units"] = 3       # 0.05 -> 0.1 (round half up)
	t.eq(SimState.fuel_out(L), 0.1, "fuel_out 0.05 -> 0.1")
	L["lit"] = false
	t.eq(SimState.fuel_of(L), 0.0, "den tat fuel_of 0")
	var S := SimState.make_shade("S1", Vector3.ZERO, "wander")
	t.eq(S["target_lantern_id"], "", "shade moi target rong")
	t.eq(int(S["drain_ticks"]), 0, "shade moi drain_ticks 0")
	t.eq(GameConfig.PULSE_COOLDOWN_TICKS, int(round(GameConfig.PULSE_COOLDOWN_S * 60.0)), "pulse cd ticks")
	t.eq(GameConfig.PULSE_STUN_TICKS, int(round(GameConfig.PULSE_STUN_S * 60.0)), "stun ticks")
	t.eq(GameConfig.INVULN_TICKS, int(round(GameConfig.INVULN_S * 60.0)), "invuln ticks")
	t.eq(GameConfig.DASH_TICKS, int(round(GameConfig.DASH_DURATION_S * 60.0)), "dash ticks")
	t.eq(GameConfig.DASH_COOLDOWN_TICKS, int(round(GameConfig.DASH_COOLDOWN_S * 60.0)), "dash cd ticks")
	var ss := SimState.new()
	ss.seed_streams(5)
	var ss2 := SimState.new()
	ss2.seed_streams(5)
	t.eq(ss.rng_mote.next_u32(), ss2.rng_mote.next_u32(), "stream mote tat dinh")
	t.ok(ss.rng_shade.next_u32() != ss.rng_wind.next_u32(), "stream khac nhau")
	t.eq(ss.height_at(0, 0), 0.0, "fallback height_at trong dao")
	t.eq(ss.height_at(41, 0), SimState.VOID_Y, "fallback height_at ngoai dao = VOID")
	ss.steps = 7
	t.eq(ss.sim_ticks, 7, "sim_ticks alias")
	var r := Rng.new(1)
	var r2 := Rng.new(1)
	t.eq(r.next_u32(), r2.next_u32(), "rng tat dinh")
	t.ok(Rng.new(1).next_u32() != Rng.new(2).next_u32(), "seed khac -> khac")
