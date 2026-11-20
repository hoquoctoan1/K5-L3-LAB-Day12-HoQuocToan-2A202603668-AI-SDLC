extends RefCounted

const Pulse = preload("res://src/core/systems/pulse_system.gd")
const Shade = preload("res://src/core/systems/shade_system.gd")
const MapBuilder = preload("res://src/core/maps/map_builder.gd")

func _mk(carried: int, shades: Array) -> SimState:
	var s := SimState.new()
	s.player = SimState.make_default_player()
	s.player["carried"] = carried
	s.shades = shades
	return s

func _sh(id: String, pos: Vector3) -> Dictionary:
	return SimState.make_shade(id, pos, "chase")

func run(t: TS) -> void:
	var inp := {"pulse": true}
	# khong du carried
	var s := _mk(GameConfig.PULSE_COST - 1, [_sh("S1", Vector3(2, 0, 0))])
	var ev := []
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 0, "thieu carried: khong event")
	t.eq(s.shades[0]["state"], "chase", "thieu carried: khong choang")
	t.eq(s.player["carried"], GameConfig.PULSE_COST - 1, "thieu carried: giu carried")
	# cooldown
	s = _mk(GameConfig.PULSE_COST + 2, [_sh("S1", Vector3(2, 0, 0))])
	s.player["pulse_cd_ticks"] = 5
	ev = []
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 0, "cooldown: khong event")
	t.eq(s.player["carried"], GameConfig.PULSE_COST + 2, "cooldown: giu carried")
	# khong input / khong playing / paused
	s = _mk(5, [])
	ev = []
	Pulse.step(s, {"pulse": false}, ev)
	t.eq(ev.size(), 0, "khong bam: khong event")
	s.status = "won"
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 0, "won: no-op")
	s.status = "playing"
	s.paused = true
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 0, "paused: no-op")
	# chi phi + hoi chieu + tam + extras
	s = _mk(GameConfig.PULSE_COST + 1, [])
	s.player["pos"] = Vector3(3, 2, 4)
	s.tick = 9
	ev = []
	Pulse.step(s, inp, ev)
	t.eq(s.player["carried"], 1, "tru chi phi 3")
	t.eq(s.player["pulse_cd_ticks"], 180, "cooldown 180 tick")
	t.eq(s.extras["pulse_center"], Vector3(3, 2.8, 4), "tam = chan + 0.8")
	t.eq(s.extras["pulse_tick"], 9, "pulse_tick")
	t.eq(ev.size(), 1, "pulse rong: van co event")
	t.eq(ev[0]["data"]["stunned_ids"], [], "mang rong")
	t.eq(s.score, 0, "rong: 0 diem")
	# ban kinh 3D: tam y = 0.8
	var c := GameConfig.PULSE_RADIUS
	s = _mk(9, [_sh("S1", Vector3(c, 0.8, 0)), _sh("S2", Vector3(c + 0.01, 0.8, 0)),
		_sh("S3", Vector3(0, 0.8 + c, 0)), _sh("S4", Vector3(0, 0.8 + c + 0.01, 0)),
		_sh("S5", Vector3(0, 0, c)), _sh("S6", Vector3(0, 0.8 - c, 0)), _sh("S7", Vector3(0, -4.2 - 0.01, 0))])
	ev = []
	Pulse.step(s, inp, ev)
	t.eq(ev[0]["data"]["stunned_ids"], ["S1", "S3", "S6"], "bien 5.0 gom; 3D; lech tam y 0.8")
	t.eq(s.score, 3 * GameConfig.SCORE_PER_STUN, "5 diem moi con")
	t.eq(s.shades[0]["state_ticks_left"], 120, "stun 120 tick")
	t.eq(s.shades[0]["knock_ticks_left"], 15, "knock 15 tick")
	t.eq(s.shades[1]["state"], "chase", "ngoai ban kinh")
	# day lui 4 m / 15 tick (shade_system thuc hien), huong ra xa tam
	s = _mk(9, [_sh("S1", Vector3(2, 0, 0))])
	Pulse.step(s, inp, [])
	for i in range(5):
		Shade.step(s, {}, [])
	t.near(s.shades[0]["pos"].x, 2.0 + 4.0 * 5.0 / 15.0, "day lui deu 4/15 m moi tick")
	for i in range(14):
		Shade.step(s, {}, [])
	t.near(s.shades[0]["pos"].x, 6.0, "tong 4 m")
	t.eq(s.shades[0]["knock_ticks_left"], 0, "het day lui")
	# stun dung 120 tick
	t.eq(s.shades[0]["state"], "stunned", "van choang sau 19 tick")
	s = _mk(9, [_sh("S1", Vector3(2, 0, 0))])
	Pulse.step(s, inp, [])
	for i in range(120):
		Shade.step(s, {}, [])
	t.eq(s.shades[0]["state"], "stunned", "choang du 120 tick")
	Shade.step(s, {}, [])
	t.ok(s.shades[0]["state"] != "stunned", "tick 121 het choang")
	# trung vi tri nguoi choi: +X
	s = _mk(9, [_sh("S1", Vector3.ZERO)])
	Pulse.step(s, inp, [])
	for i in range(15):
		Shade.step(s, {}, [])
	t.near(s.shades[0]["pos"].x, 4.0, "trung vi tri: +X")
	# huong -Z
	s = _mk(9, [_sh("S1", Vector3(0, 0, -2))])
	Pulse.step(s, inp, [])
	for i in range(15):
		Shade.step(s, {}, [])
	t.near(s.shades[0]["pos"].z, -6.0, "ra xa tam theo -Z")
	# chan o mep dao
	s = _mk(9, [_sh("S1", Vector3(39, 0, 0))])
	s.player["pos"] = Vector3(36, 0, 0)
	Pulse.step(s, inp, [])
	for i in range(15):
		Shade.step(s, {}, [])
	t.ok(s.shades[0]["pos"].x <= 40.0 + 0.0001, "khong roi khoi dao khi bi day")
	# chan boi vat can (Chuong, Dem 3)
	s = _mk(9, [_sh("S1", Vector3(4, 6, 0))])
	s.night = 3
	s.map = MapBuilder.build(3)
	s.player["pos"] = Vector3(6, 6, 0)
	Pulse.step(s, inp, [])
	for i in range(15):
		Shade.step(s, {}, [])
	var sx: float = s.shades[0]["pos"].x
	t.ok(sx > 2.0 and sx < 3.0, "dung truoc tru chuong x=%f" % sx)
	# re-pulse lam moi
	s = _mk(9, [_sh("S1", Vector3(2, 0, 0))])
	Pulse.step(s, inp, [])
	for i in range(30):
		Shade.step(s, {}, [])
	s.player["pulse_cd_ticks"] = 0
	s.player["pos"] = Vector3(3, 0, 0)
	var ev2 := []
	Pulse.step(s, inp, ev2)
	t.eq(s.shades[0]["state_ticks_left"], 120, "re-pulse lam moi choang")
	t.eq(s.shades[0]["knock_ticks_left"], 15, "re-pulse lam moi day lui")
	t.eq(s.score, 2 * GameConfig.SCORE_PER_STUN, "re-pulse tinh diem lai")
	t.eq(ev2[0]["data"]["stunned_ids"], ["S1"], "re-pulse event")
