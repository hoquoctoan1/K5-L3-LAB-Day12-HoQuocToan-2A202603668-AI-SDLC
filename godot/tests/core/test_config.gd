extends RefCounted

func run(t: TS) -> void:
	var f := FileAccess.open("res://../game.contract.json", FileAccess.READ)
	t.ok(f != null, "doc duoc game.contract.json")
	if f == null:
		return
	var c = JSON.parse_string(f.get_as_text())
	t.eq(c["contract_version"], GameConfig.CONTRACT_VERSION, "contract_version")
	t.eq(c["contract_version"], "1.1", "contract_version 1.1")
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
	t.eq(GameConfig.night_duration_ticks(1), 18000, "dem 1 ticks")
	t.eq(GameConfig.night_duration_ticks(2), 19800, "dem 2 ticks")
	t.eq(GameConfig.night_duration_ticks(3), 21600, "dem 3 ticks")
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
