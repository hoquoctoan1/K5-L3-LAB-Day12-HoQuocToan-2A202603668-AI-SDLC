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
	s.motes = [{"id": "m1", "pos": Vector3(R, 5.0, 0)}, {"id": "m2", "pos": Vector3(R + 0.01, 0, 0)}]
	var ev := []
	MoteSystem.step(s, {}, ev)
	t.eq(s.player["carried"], 1, "dung ban kinh -> nhat (bo qua Y)")
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
	s.player["carried"] = 4
	ev = []
	LanternSystem.step(s, {"interact": true}, ev)
	t.ok(s.lanterns[0]["lit"], "sang den")
	t.eq(s.player["carried"], 2, "du 2 -> con 2")
	t.eq(s.score, GameConfig.SCORE_PER_LANTERN, "diem lantern")
	t.eq(_names(ev), ["deposit", "lantern_lit"], "thu tu deposit, lantern_lit")
	t.eq(ev[0]["data"]["amount"], 2, "amount=2")
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
