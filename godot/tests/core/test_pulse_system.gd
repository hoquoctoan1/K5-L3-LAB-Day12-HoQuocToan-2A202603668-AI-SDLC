extends RefCounted

const Pulse = preload("res://src/core/systems/pulse_system.gd")

func _mk(carried: int, shades: Array) -> SimState:
	var s := SimState.new()
	s.player = SimState.make_default_player()
	s.player["carried"] = carried
	s.shades = shades
	return s

func _sh(id: String, pos: Vector3) -> Dictionary:
	return {"id": id, "pos": pos, "state": "chase", "stun_left": 0.0}

func run(t: TS) -> void:
	var inp := {"pulse": true}
	# khong du carried
	var s := _mk(1, [_sh("S1", Vector3(2, 0, 0))])
	var ev := []
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 0, "thieu carried: khong event")
	t.eq(s.shades[0]["state"], "chase", "thieu carried: shade khong choang")
	t.eq(s.player["carried"], 1, "thieu carried: giu carried")
	# cooldown
	s = _mk(5, [_sh("S1", Vector3(2, 0, 0))])
	s.player["pulse_cd_left"] = 0.5
	ev = []
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 0, "cooldown: khong event")
	t.eq(s.player["carried"], 5, "cooldown: giu carried")
	# khong co input
	s = _mk(5, [])
	ev = []
	Pulse.step(s, {"pulse": false}, ev)
	t.eq(ev.size(), 0, "khong nhan pulse: khong event")
	# status != playing
	s = _mk(5, [])
	s.status = "won"
	ev = []
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 0, "status won: no-op")
	# ranh gioi ban kinh + push + score + thu tu id
	s = _mk(4, [
		_sh("S1", Vector3(GameConfig.PULSE_RADIUS, 0, 0)),
		_sh("S2", Vector3(GameConfig.PULSE_RADIUS + 0.01, 0, 0)),
		_sh("S3", Vector3(0, 1.5, 3)),
	])
	ev = []
	Pulse.step(s, inp, ev)
	t.eq(s.shades[0]["state"], "stunned", "bang ban kinh: choang")
	t.eq(s.shades[1]["state"], "chase", "ngoai ban kinh: khong choang")
	t.near(s.shades[0]["pos"].x, GameConfig.PULSE_RADIUS + GameConfig.PULSE_PUSH_M, "push khoang cach")
	t.near(s.shades[2]["pos"].z, 3.0 + GameConfig.PULSE_PUSH_M, "push theo z")
	t.near(s.shades[2]["pos"].y, 1.5, "giu y")
	t.near(s.shades[0]["stun_left"], GameConfig.PULSE_STUN_S, "stun_left")
	t.eq(s.score, 2 * GameConfig.SCORE_PER_STUN, "score per_stun")
	t.eq(s.player["carried"], 4 - GameConfig.PULSE_COST, "tru chi phi")
	t.near(s.player["pulse_cd_left"], GameConfig.PULSE_COOLDOWN_S, "dat cooldown")
	t.eq(ev.size(), 1, "mot event")
	t.eq(ev[0]["name"], "pulse", "ten event")
	t.eq(ev[0]["data"]["stunned_ids"], ["S1", "S3"], "thu tu id")
	# trung nguoi choi: day theo +X
	s = _mk(2, [_sh("S1", Vector3.ZERO)])
	Pulse.step(s, inp, [])
	t.near(s.shades[0]["pos"].x, GameConfig.PULSE_PUSH_M, "tren nguoi choi: +X")
	# kep trong dao
	s = _mk(2, [_sh("S1", Vector3(GameConfig.ISLAND_RADIUS - 1.0, 0, 0))])
	s.player["pos"] = Vector3(GameConfig.ISLAND_RADIUS - 3.0, 0, 0)
	Pulse.step(s, inp, [])
	t.ok(Vector2(s.shades[0]["pos"].x, s.shades[0]["pos"].z).length() <= GameConfig.ISLAND_RADIUS + 0.0001, "kep ISLAND_RADIUS")
	# pulse rong van phat event va tieu chi phi
	s = _mk(3, [_sh("S1", Vector3(30, 0, 0))])
	ev = []
	Pulse.step(s, inp, ev)
	t.eq(ev.size(), 1, "pulse rong: co event")
	t.eq(ev[0]["data"]["stunned_ids"], [], "pulse rong: mang rong")
	t.eq(s.player["carried"], 3 - GameConfig.PULSE_COST, "pulse rong: tru chi phi")
	t.eq(s.score, 0, "pulse rong: 0 diem")
	# shade da stunned van tinh va khoi dong lai
	s = _mk(2, [_sh("S1", Vector3(1, 0, 0))])
	s.shades[0]["state"] = "stunned"
	s.shades[0]["stun_left"] = 0.2
	Pulse.step(s, inp, [])
	t.near(s.shades[0]["stun_left"], GameConfig.PULSE_STUN_S, "restart stun")
	t.eq(s.score, GameConfig.SCORE_PER_STUN, "tinh diem shade da stunned")
