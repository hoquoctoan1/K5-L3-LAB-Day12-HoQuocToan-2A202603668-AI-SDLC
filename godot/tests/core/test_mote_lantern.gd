extends RefCounted
const MoteSystem = preload("res://src/core/systems/mote_system.gd")
const LanternSystem = preload("res://src/core/systems/lantern_system.gd")

func _st() -> SimState:
	var s := SimState.new()
	s.player = SimState.make_default_player()
	return s

func _names(ev: Array) -> Array:
	var r := []
	for e in ev:
		r.append(e["name"])
	return r

func _lan(id: String, pos: Vector3, dep := 0) -> Dictionary:
	return {"id": id, "pos": pos, "lit": false, "deposited": dep}

func run(t: TS) -> void:
	var R := GameConfig.PICKUP_RADIUS
	# bien pick
	var s := _st()
	s.motes = [{"id": "m1", "pos": Vector3(R, GameConfig.PICKUP_MAX_DY, 0)}, {"id": "m2", "pos": Vector3(R + 0.01, 0, 0)}]
	var ev := []
	MoteSystem.step(s, {}, ev)
	t.eq(s.player["carried"], 1, "dung ban kinh -> nhat (|dy| <= PICKUP_MAX_DY; Phase 1 bo qua Y)")
	t.eq(s.motes.size(), 1, "mote ngoai ban kinh con lai")
	t.eq(s.score, GameConfig.SCORE_PER_MOTE, "diem mote")
	t.eq(_names(ev), ["mote_picked"], "event mote_picked 1 lan")
	t.eq(ev[0]["data"]["carried"], 1, "data carried")
	# day
	s = _st()
	s.player["carried"] = GameConfig.CARRY_CAPACITY
	s.motes = [{"id": "m1", "pos": Vector3.ZERO}]
	ev = []
	MoteSystem.step(s, {}, ev)
	t.eq(s.motes.size(), 1, "day -> mote o lai")
	t.eq(s.score, 0, "day -> khong diem")
	t.eq(ev.size(), 0, "day -> khong event")
	# status
	s = _st()
	s.status = "won"
	s.motes = [{"id": "m1", "pos": Vector3.ZERO}]
	MoteSystem.step(s, {}, [])
	t.eq(s.motes.size(), 1, "khong playing -> no-op")
	# nhat toi da toi capacity
	s = _st()
	s.player["carried"] = GameConfig.CARRY_CAPACITY - 1
	s.motes = [{"id": "m1", "pos": Vector3.ZERO}, {"id": "m2", "pos": Vector3.ZERO}]
	ev = []
	MoteSystem.step(s, {}, ev)
	t.eq(s.player["carried"], GameConfig.CARRY_CAPACITY, "chi nhat toi capacity")
	t.eq(s.motes.size(), 1, "mote thu 2 o lai")

	# lantern: deposit mot phan
	s = _st()
	var C := GameConfig.LANTERN_COST
	s.player["carried"] = 3
	s.lanterns = [_lan("L1", Vector3(1, 0, 0))]
	ev = []
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(s.player["carried"], 0, "carried=0 sau gui")
	t.eq(s.lanterns[0]["deposited"], 3, "deposited 3")
	t.ok(not s.lanterns[0]["lit"], "chua sang")
	t.eq(_names(ev), ["deposit"], "chi deposit")
	t.eq(ev[0]["data"], {"lantern_id": "L1", "amount": 3, "deposited": 3}, "data deposit")
	# hoan tat
	s.player["carried"] = C - 3 + 2
	ev = []
	LanternSystem.step(s, {"interact": true}, ev)
	t.ok(s.lanterns[0]["lit"], "sang den")
	t.eq(s.player["carried"], 2, "du C-3 -> con 2")
	t.eq(s.score, GameConfig.SCORE_PER_LANTERN, "diem lantern")
	t.eq(_names(ev), ["deposit", "lantern_lit"], "thu tu deposit, lantern_lit")
	t.eq(ev[0]["data"]["amount"], C - 3, "amount=C-3")
	# da sang -> bo qua, khong lit lan 2
	ev = []
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev.size(), 0, "den sang bi bo qua")
	t.eq(s.score, GameConfig.SCORE_PER_LANTERN, "diem khong cong lai")
	t.eq(s.player["carried"], 2, "carried giu nguyen")
	# khong interact / khong carried
	s = _st()
	s.lanterns = [_lan("L1", Vector3.ZERO)]
	ev = []
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev.size(), 0, "interact ma carried=0 -> khong lam gi")
	s.player["carried"] = 2
	LanternSystem.step(s, {"interact": false}, ev)
	t.eq(ev.size(), 0, "khong interact -> khong lam gi")
	# ngoai ban kinh
	s.lanterns = [_lan("L1", Vector3(GameConfig.INTERACT_RADIUS + 0.01, 0, 0))]
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev.size(), 0, "ngoai INTERACT_RADIUS")
	# dung ban kinh
	s.lanterns = [_lan("L1", Vector3(GameConfig.INTERACT_RADIUS, 0, 0))]
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev.size(), 1, "dung INTERACT_RADIUS -> gui")
	# hoa: id thap nhat
	s = _st()
	s.player["carried"] = 1
	s.lanterns = [_lan("L2", Vector3(1, 0, 0)), _lan("L1", Vector3(-1, 0, 0))]
	ev = []
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev[0]["data"]["lantern_id"], "L1", "hoa -> id thap nhat")
	# gan nhat, bo qua den sang
	s = _st()
	s.player["carried"] = 1
	var lit := _lan("L1", Vector3(0.5, 0, 0))
	lit["lit"] = true
	s.lanterns = [lit, _lan("L2", Vector3(2, 0, 0)), _lan("L3", Vector3(1, 0, 0))]
	ev = []
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev[0]["data"]["lantern_id"], "L3", "gan nhat chua sang")
	_run_p2(t)

func _run_p2(t: TS) -> void:
	# dy bien 1.5 / vuot
	var s := _st()
	s.motes = [{"id": "m1", "pos": Vector3(0.5, 1.51, 0)}, {"id": "m2", "pos": Vector3(0.5, -1.5, 0)}]
	MoteSystem.step(s, {}, [])
	t.eq(s.player["carried"], 1, "dy 1.5 nhat, 1.51 khong")
	t.eq(s.motes[0]["id"], "m1", "m1 (dy>1.5) o lai")
	# TTL
	s = _st()
	s.motes = [SimState.make_mote("m1", Vector3(10, 0, 0), "dropped", 2), SimState.make_mote("m2", Vector3(10, 0, 0), "random", -1)]
	MoteSystem.step(s, {}, [])
	t.eq(s.motes.size(), 2, "ttl 2->1 con")
	MoteSystem.step(s, {}, [])
	t.eq(s.motes.size(), 1, "ttl het -> xoa; random vo han o lai")
	t.eq(s.motes[0]["id"], "m2", "m2 con")
	# tha mote: khong nhat cung tick, nhat tick sau; ring + tat dinh
	s = _st()
	s.seed_streams(7)
	var made := MoteSystem.drop_motes(s, Vector3.ZERO, 3, 480)
	t.eq(made.size(), 3, "3 mote tha")
	t.eq(s.next_mote_id, 4, "next_mote_id tang")
	t.eq(made[0]["id"], "m1", "id m1")
	for m in made:
		var r: float = Vector2(m["pos"].x, m["pos"].z).length()
		t.ok(r >= 1.5 - 1e-3 and r <= 2.5 + 1e-3, "tren vong 1.5..2.5")
		t.eq(m["kind"], "dropped", "kind dropped")
		t.eq(m["ttl_ticks"], 480, "ttl 480")
	var s2 := _st()
	s2.seed_streams(7)
	var made2 := MoteSystem.drop_motes(s2, Vector3.ZERO, 3, 480)
	t.ok(made[0]["pos"] == made2[0]["pos"] and made[2]["pos"] == made2[2]["pos"], "vi tri tha tat dinh theo seed")
	s = _st()
	s.seed_streams(7)
	s.player["pos"] = Vector3(2, 0, 0)
	s.motes = [SimState.make_mote("m1", Vector3(2, 0, 0), "dropped", 480)]
	s.motes[0]["born_tick"] = s.tick
	MoteSystem.step(s, {}, [])
	t.eq(s.player["carried"], 0, "mote vua tha khong nhat cung tick")
	s.tick += 1
	MoteSystem.step(s, {}, [])
	t.eq(s.player["carried"], 1, "nhat tu tick sau")
	# fall_wait / paused
	s = _st()
	s.player["fall_wait_ticks"] = 5
	s.motes = [{"id": "m1", "pos": Vector3.ZERO}]
	MoteSystem.step(s, {}, [])
	t.eq(s.player["carried"], 0, "fall_wait khong nhat")
	s = _st()
	s.paused = true
	s.motes = [SimState.make_mote("m1", Vector3.ZERO, "dropped", 5)]
	MoteSystem.step(s, {}, [])
	t.ok(s.player["carried"] == 0 and s.motes[0]["ttl_ticks"] == 5, "paused: khong nhat, ttl dung yen")
	s = _st()
	s.paused = true
	s.player["carried"] = 5
	s.lanterns = [_lan("L1", Vector3.ZERO)]
	var ev := []
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev.size(), 0, "paused: lantern no-op")
	s.paused = false
	s.player["fall_wait_ticks"] = 3
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(ev.size(), 0, "fall_wait: lantern no-op")
	# tien do nho + tie id (khoang cach bang)
	s = _st()
	s.player["carried"] = 4
	s.lanterns = [_lan("L1", Vector3(1.5, 0, 0), 8)]
	LanternSystem.step(s, {"interact": true}, ev)
	t.eq(s.lanterns[0]["deposited"], 10, "nap 2 (min(carried, 10-8)) -> sang")
	t.eq(s.player["carried"], 2, "con 2")
	# safe zone: shade trong vung den vua sang bi day ra <=30 tick, khong sat thuong (safe_push_ticks>0)
	s = _st()
	s.player["pos"] = Vector3(40, 0, 40)
	var lt := _lan("L1", Vector3.ZERO)
	lt["lit"] = true
	s.lanterns = [lt]
	s.shades = [SimState.make_shade("S1", Vector3(2, 0, 0))]
	var flagged := true
	var n := 0
	while s.shades[0]["safe_push_ticks"] != 0 or n == 0:
		LanternSystem.step(s, {}, [])
		n += 1
		if s.shades[0]["safe_push_ticks"] > 0 and s.shades[0]["safe_push_ticks"] <= 0:
			flagged = false
		if n > 40:
			break
	t.ok(n <= GameConfig.SAFE_PUSH_MAX_TICKS, "day ra trong <=30 tick (n=%d)" % n)
	var sd: float = Vector2(s.shades[0]["pos"].x, s.shades[0]["pos"].z).length()
	t.ok(absf(sd - GameConfig.SAFE_RADIUS) < 1e-3, "o mep vung an toan")
	t.ok(not LanternSystem.in_safe_zone(s, s.shades[0]["pos"]), "mep: khong con trong vung")
	t.ok(LanternSystem.in_safe_zone(s, Vector3(3, 0, 0)), "in_safe_zone true ben trong")
	s = _st()
	s.lanterns = [_lan("L1", Vector3.ZERO)]
	s.shades = [SimState.make_shade("S1", Vector3(2, 0, 0))]
	LanternSystem.step(s, {}, [])
	t.ok(s.shades[0]["pos"] == Vector3(2, 0, 0) and s.shades[0]["safe_push_ticks"] == 0, "den chua sang: khong day")
