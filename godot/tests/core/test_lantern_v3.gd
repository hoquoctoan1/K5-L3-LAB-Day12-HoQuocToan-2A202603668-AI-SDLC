extends RefCounted
## P3-B1/B2: luat dau den + muc tieu Bong Muc (contract v1.2, TICKET-03 muc 1-2). Dap an tinh tay.
const LanternSystem = preload("res://src/core/systems/lantern_system.gd")
const ShadeSystem = preload("res://src/core/systems/shade_system.gd")
const PulseSystem = preload("res://src/core/systems/pulse_system.gd")

func _st() -> SimState:
	var s := SimState.new()
	s.player = SimState.make_default_player()
	return s

func _lit(id: String, pos: Vector3, units: int = GameConfig.FUEL_MAX_UNITS) -> Dictionary:
	var l := SimState.make_lantern(id, pos)
	l["lit"] = true
	l["ever_lit"] = true
	l["fuel_units"] = units
	return l

func run(t: TS) -> void:
	# den day dau KHONG duoc chon: den chua sang xa hon van nhan
	var s := _st()
	s.player["carried"] = 4
	s.lanterns = [_lit("L1", Vector3(0.5, 0, 0)), SimState.make_lantern("L2", Vector3(1.5, 0, 0))]
	var ev := []
	LanternSystem._interact(s, {"interact": true}, ev)
	t.eq(ev.size(), 1, "1 event")
	t.eq(ev[0]["name"], "deposit", "nap vao L2 (L1 day)")
	t.eq(ev[0]["data"]["lantern_id"], "L2", "bo qua den day dau")
	# chi co den day: khong event, khong diem, khong tru mote
	s = _st()
	s.player["carried"] = 4
	s.lanterns = [_lit("L1", Vector3(0.5, 0, 0))]
	ev = []
	LanternSystem._interact(s, {"interact": true}, ev)
	t.ok(ev.is_empty() and s.score == 0 and s.player["carried"] == 4, "den day: khong lam gi")
	# hoa khoang cach: id nho hon (den sang chua day vs den chua sang)
	s = _st()
	s.player["carried"] = 1
	s.lanterns = [SimState.make_lantern("L2", Vector3(1, 0, 0)), _lit("L1", Vector3(-1, 0, 0), 3000)]
	ev = []
	LanternSystem._interact(s, {"interact": true}, ev)
	t.eq(ev[0]["name"], "refuel", "hoa -> L1 (id nho) -> refuel")
	t.eq(ev[0]["data"], {"lantern_id": "L1", "amount": 1, "fuel": 60.0}, "refuel 50 -> 60")
	t.eq(s.score, GameConfig.SCORE_PER_MOTE, "+5 moi mote cham dau")
	# cham dau khong vuot 100 va dung dung so mote can: fuel 95.0 (5700) thieu 300 -> 1 mote
	s = _st()
	s.player["carried"] = 6
	s.lanterns = [_lit("L1", Vector3.ZERO, 5700)]
	ev = []
	LanternSystem._interact(s, {"interact": true}, ev)
	t.eq(ev[0]["data"], {"lantern_id": "L1", "amount": 1, "fuel": 100.0}, "95 -> 100 bang 1 mote")
	t.eq(s.player["carried"], 5, "con 5")
	# den chua tung sang van can 10; thap lan dau tang successful_lights, capacity 12
	s = _st()
	s.player["carried"] = 10
	s.lanterns = [SimState.make_lantern("L1", Vector3.ZERO)]
	ev = []
	LanternSystem._interact(s, {"interact": true}, ev)
	t.eq(ev[1]["data"], {"lantern_id": "L1", "relight": false}, "thap lan dau")
	t.eq(s.score, 10 * 5 + 100, "diem 150")
	t.eq(s.capacity(), 12, "capacity 12")
	# tick_fuel: hao + 2 con drain -> 11 unit/tick; Bong Muc drain den KHAC khong tinh
	s = _st()
	s.lanterns = [_lit("L1", Vector3.ZERO, 100), _lit("L2", Vector3(10, 0, 0), 100)]
	var a := SimState.make_shade("S1", Vector3.ZERO, "drain")
	a["target_lantern_id"] = "L1"
	var b := SimState.make_shade("S2", Vector3.ZERO, "drain")
	b["target_lantern_id"] = "L1"
	var c := SimState.make_shade("S3", Vector3.ZERO, "wander")
	c["target_lantern_id"] = "L2"
	s.shades = [a, b, c]
	ev = []
	LanternSystem.tick_fuel(s, ev)
	t.eq(int(s.lanterns[0]["fuel_units"]), 100 - 11, "L1 -11")
	t.eq(int(s.lanterns[1]["fuel_units"]), 99, "L2 chi tu hao (S3 khong drain)")
	t.ok(ev.is_empty(), "chua toi 60 tick hut")
	# het dau: dung 0 -> tat, deposited 0, ever_lit, event
	s = _st()
	var L := _lit("L1", Vector3.ZERO, 1)
	L["deposited"] = 10
	s.lanterns = [L]
	ev = []
	LanternSystem.tick_fuel(s, ev)
	t.ok(not L["lit"] and int(L["deposited"]) == 0 and L["ever_lit"] and int(L["fuel_units"]) == 0, "tat dung luc 0")
	t.eq(ev, [{"name": "lantern_out", "data": {"lantern_id": "L1"}}], "lantern_out")
	# paused: dau dung yen
	s = _st()
	s.paused = true
	s.lanterns = [_lit("L1", Vector3.ZERO, 50)]
	LanternSystem.tick_fuel(s, [])
	t.eq(int(s.lanterns[0]["fuel_units"]), 50, "paused: khong hao")
	# vung an toan: 30.0 con, 29.98 mat
	s = _st()
	s.lanterns = [_lit("L1", Vector3.ZERO, GameConfig.LOW_FUEL_UNITS)]
	t.ok(LanternSystem.in_safe_zone(s, Vector3(3, 0, 0)), "fuel 30 -> co vung")
	s.lanterns[0]["fuel_units"] = GameConfig.LOW_FUEL_UNITS - 1
	t.ok(not LanternSystem.in_safe_zone(s, Vector3(3, 0, 0)), "fuel 29.98 -> mat vung")
	# muc tieu Bong Muc: den yeu gan nhat, hoa -> id nho; khong co yeu -> den tat gan nhat; khong co -> {}
	s = _st()
	s.lanterns = [_lit("L2", Vector3(5, 0, 0), 600), _lit("L1", Vector3(-5, 0, 0), 600),
		SimState.make_lantern("L3", Vector3(1, 0, 0)), _lit("L4", Vector3(2, 0, 0))]
	t.eq(ShadeSystem.pick_target(s, Vector2.ZERO)["id"], "L1", "den yeu, hoa -> L1 (bo qua den tat gan hon)")
	s.lanterns[0]["fuel_units"] = 6000
	s.lanterns[1]["fuel_units"] = 6000
	t.eq(ShadeSystem.pick_target(s, Vector2.ZERO)["id"], "L3", "khong den yeu -> den tat gan nhat")
	s.lanterns[2]["lit"] = true
	s.lanterns[2]["fuel_units"] = 6000
	t.ok(ShadeSystem.pick_target(s, Vector2.ZERO).is_empty(), "moi den sang day -> khong muc tieu (di ngau nhien)")
	# pulse: drain +15, chase +5
	s = _st()
	s.player["carried"] = 3
	var d := SimState.make_shade("S1", Vector3(1, 0, 0), "drain")
	d["target_lantern_id"] = "L1"
	s.shades = [d, SimState.make_shade("S2", Vector3(-1, 0, 0), "chase")]
	PulseSystem.step(s, {"pulse": true}, [])
	t.eq(s.score, 15 + 5, "drain 15 + chase 5")
	t.eq(d["target_lantern_id"], "", "het muc tieu sau khi choang")
