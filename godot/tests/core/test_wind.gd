extends RefCounted

const Wind = preload("res://src/core/systems/wind_system.gd")

func _mk(night: int, seed_v: int = 5) -> SimState:
	var s := SimState.new()
	s.night = night
	s.seed_streams(seed_v)
	s.player = SimState.make_default_player()
	s.wind = SimState.make_default_wind()
	return s

func run(t: TS) -> void:
	var s := _mk(3)
	var first_warn := -1
	var starts: Array = []
	var ends: Array = []
	var dirs: Array = []
	var was := false
	for i in range(1, 3801):
		Wind.step(s, {}, [])
		var w: Dictionary = s.wind
		if first_warn < 0 and w["warning"]:
			first_warn = i
		if bool(w["active"]) and not was:
			starts.append(i)
			dirs.append(w["dir_deg"])
		if was and not bool(w["active"]):
			ends.append(i)
		was = bool(w["active"])
	t.eq(first_warn, 1800 - GameConfig.WIND_WARN_TICKS, "warning tai tick 1680 (next_ticks=120)")
	t.eq(starts, [1800, 3600], "gio bat dau 1800, 3600")
	t.eq(ends, [2100], "gio het sau 300 tick")
	s = _mk(3)
	for i in range(1799):
		Wind.step(s, {}, [])
	t.ok(s.wind["warning"] and not s.wind["active"], "truoc start: warning, chua active")
	t.eq(s.wind["push"], Vector3.ZERO, "chua push")
	Wind.step(s, {}, [])
	t.ok(s.wind["active"] and not s.wind["warning"], "active, het warning")
	var a: float = deg_to_rad(s.wind["dir_deg"])
	t.near(s.wind["push"].length(), GameConfig.WIND_PUSH_MPS, "push 2 m/s")
	t.near(s.wind["push"].x, cos(a) * 2.0, "push huong x")
	t.near(s.wind["push"].z, sin(a) * 2.0, "push huong z")
	t.eq(s.wind["push"].y, 0.0, "push ngang")
	t.eq(s.wind["ticks_left"], 300, "ticks_left 300")
	for i in range(299):
		Wind.step(s, {}, [])
	t.ok(s.wind["active"], "van active o tick 2099")
	Wind.step(s, {}, [])
	t.ok(not s.wind["active"], "het o 2100")
	t.eq(s.wind["push"], Vector3.ZERO, "push 0 sau gio")
	var s2 := _mk(3)
	for i in range(1800):
		Wind.step(s2, {}, [])
	t.eq(s2.wind["dir_deg"], dirs[0], "cung seed cung huong")
	var s3 := _mk(3, 99)
	for i in range(1800):
		Wind.step(s3, {}, [])
	t.ok(s3.wind["dir_deg"] != dirs[0], "seed khac -> huong khac")
	t.ok(s3.wind["dir_deg"] >= 0.0 and s3.wind["dir_deg"] < 360.0, "huong trong [0,360)")
	for n in [1, 2]:
		var g := _mk(n)
		for i in range(2000):
			Wind.step(g, {}, [])
		t.ok(not g.wind["active"] and not g.wind["warning"], "Dem %d: khong gio" % n)
	var f := _mk(3)
	f.wind_enabled = false
	for i in range(2000):
		Wind.step(f, {}, [])
	t.ok(not f.wind["active"] and not f.wind["warning"], "wind_enabled=false: khong gio")
	t.eq(f.wind["push"], Vector3.ZERO, "tat: push 0")
	var p := _mk(3)
	p.paused = true
	for i in range(2000):
		Wind.step(p, {}, [])
	t.eq(p.wind["next_ticks"], GameConfig.WIND_EVERY_TICKS, "paused: dem dung yen")
	t.ok(not p.wind["active"], "paused: khong active")
