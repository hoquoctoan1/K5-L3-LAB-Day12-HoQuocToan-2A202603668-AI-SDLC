extends RefCounted
const PS = preload("res://src/core/systems/player_system.gd")
const MapBuilder = preload("res://src/core/maps/map_builder.gd")

func _inp(move := Vector2.ZERO, jump := false, dash := false) -> Dictionary:
	return {"move": move, "cam_yaw_deg": 0.0, "jump": jump, "interact": false, "pulse": false, "dash": dash}

func _new(night := 1) -> SimState:
	var s := SimState.new()
	s.night = night
	s.map = MapBuilder.build(night)
	s.player = SimState.make_default_player()
	return s

func _fall_state() -> SimState:
	var s := _new()
	s.player["pos"] = Vector3(39.9, 0, 0)
	s.player["carried"] = 7
	return s

func _hits(ev: Array) -> Array:
	var h := []
	for e in ev:
		if e["name"] == "player_hit":
			h.append(e)
	return h

func run(t: TS) -> void:
	var ev := []
	var s := _new()
	for i in 60:
		PS.step(s, _inp(Vector2(1, 0)), ev)
	t.near(s.player["pos"].x, 6.0, "chay 60 tick = 6 m")
	for i in 3:
		PS.step(s, _inp(), ev)
	t.ok(s.player["vel"].x > 0.0 and s.player["vel"].x < 6.0, "giam toc dan")
	for i in 3:
		PS.step(s, _inp(), ev)
	t.near(s.player["vel"].x, 0.0, "dung sau 6 tick")
	t.eq(ev.size(), 0, "khong event")
	# charm
	s = _new()
	s.player["charm_ticks"] = 100
	for i in 60:
		PS.step(s, _inp(Vector2(0, 1)), ev)
	t.near(s.player["pos"].z, 7.2, "charm 7.2 m/s")
	# nhay
	s = _new()
	PS.step(s, _inp(Vector2.ZERO, true), ev)
	t.ok(not s.player["grounded"] and s.player["pos"].y > 0.0, "nhay")
	var n := 1
	var max_y: float = s.player["pos"].y
	while not s.player["grounded"] and n < 1000:
		PS.step(s, _inp(), ev)
		max_y = maxf(max_y, s.player["pos"].y)
		n += 1
	t.ok(absi(n - 42) <= 2, "tiep dat sau ~42 tick (got %d)" % n)
	t.near(s.player["pos"].y, 0.0, "y=0 khi dat")
	t.ok(absf(max_y - 1.225) < 0.1, "do cao nhay ~1.225 (got %f)" % max_y)
	# khong double jump
	s = _new()
	PS.step(s, _inp(Vector2.ZERO, true), ev)
	for i in 5:
		PS.step(s, _inp(), ev)
	var vy: float = s.player["vel"].y
	PS.step(s, _inp(Vector2.ZERO, true), ev)
	t.ok(s.player["vel"].y < vy, "khong nhay doi")
	# dash
	s = _new()
	ev = []
	PS.step(s, _inp(Vector2(0, 1), false, true), ev)
	t.eq(ev.size(), 1, "event dash")
	t.eq(ev[0]["name"], "dash", "ten event dash")
	t.eq(s.player["dash_cd_ticks"], 90, "cd 90 luc bat dau")
	for i in 11:
		PS.step(s, _inp(Vector2(0, 1)), ev)
	t.near(s.player["pos"].z, 2.8, "luot 2.8 m / 12 tick")
	t.eq(s.player["dash_ticks_left"], 0, "het luot")
	t.eq(s.player["invuln_ticks"], 0, "luot khong bat tu")
	# bam khi dang luot / cd bi bo qua; cd 90
	s = _new()
	ev = []
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	for i in 88:
		PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	t.eq(ev.size(), 1, "tick 89 chua het cd")
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	t.eq(ev.size(), 1, "tick 90 van cd")
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	t.eq(ev.size(), 2, "tick 91 luot lai")
	# huong
	s = _new()
	PS.step(s, _inp(Vector2(1, 0)), ev)
	for i in 10:
		PS.step(s, _inp(), ev)
	var x0: float = s.player["pos"].x
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	for i in 11:
		PS.step(s, _inp(), ev)
	t.near(s.player["pos"].x - x0, 2.8, "luot dung yen theo facing +X")
	s = _new()
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	for i in 11:
		PS.step(s, _inp(), ev)
	t.near(s.player["pos"].z, 2.8, "facing mac dinh +Z")
	# charm dash
	s = _new()
	s.player["charm_ticks"] = 600
	ev = []
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	t.eq(s.player["dash_cd_ticks"], 0, "charm cd 0")
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	t.eq(ev.size(), 1, "charm: bam khi dang luot bo qua")
	for i in 11:
		PS.step(s, _inp(), ev)
	PS.step(s, _inp(Vector2.ZERO, false, true), ev)
	t.eq(ev.size(), 2, "charm: luot lien tiep voi bam moi")
	# luot tren khong
	s = _new()
	PS.step(s, _inp(Vector2.ZERO, true), ev)
	PS.step(s, _inp(Vector2(0, 1), false, true), ev)
	t.ok(s.player["vel"].y > 0.0 and s.player["pos"].y > 0.0, "luot tren khong giu vy")
	# roi: dung 1 lan
	s = _fall_state()
	ev = []
	var guard := 0
	while s.player["fall_wait_ticks"] == 0 and guard < 400:
		PS.step(s, _inp(Vector2(1, 0)), ev)
		guard += 1
	var hits := _hits(ev)
	t.eq(hits.size(), 1, "player_hit 1 lan")
	t.eq(hits[0]["data"]["by"], "fall", "by fall")
	t.eq(hits[0]["data"]["lost"], 7, "lost = 7")
	t.eq(hits[0]["data"]["flames"], 2, "flames event")
	t.eq(s.player["flames"], 2, "flames-1")
	t.eq(s.player["carried"], 0, "mat het mote")
	t.eq(s.player["fall_wait_ticks"], 60, "cho 60")
	for i in 59:
		PS.step(s, _inp(Vector2(1, 0), true), ev)
	t.ok(s.player["pos"].y < -10.0, "van dang cho")
	PS.step(s, _inp(), ev)
	t.eq(s.player["pos"], Vector3.ZERO, "hoi sinh o xuat phat")
	t.eq(s.player["vel"], Vector3.ZERO, "van toc 0")
	t.eq(s.player["invuln_ticks"], 90, "bat tu 90")
	t.eq(_hits(ev).size(), 1, "tong 1 hit")
	# het lua
	s = _fall_state()
	s.player["flames"] = 1
	ev = []
	for i in 200:
		PS.step(s, _inp(Vector2(1, 0)), ev)
	t.eq(s.player["flames"], 0, "flames 0")
	t.eq(ev.size(), 1, "1 event khi het lua")
	# vach tang: buoc ra mep tang 1 -> roi xuong tang 0
	s = _new(3)
	s.player["pos"] = Vector3(20, 3, 10)
	var landed := false
	for i in 300:
		PS.step(s, _inp(Vector2(1, 0)), ev)
		if s.player["grounded"] and s.player["pos"].y < 0.01:
			landed = true
			break
	t.ok(landed, "buoc ra mep tang roi xuong tang 0")
	# tang 0 -> tang 1: vach chan leo
	s = _new(3)
	s.player["pos"] = Vector3(0, 0, 30)
	for i in 120:
		PS.step(s, _inp(Vector2(0, -1)), ev)
	t.ok(s.player["pos"].y < 0.01, "vach chan leo (y=%f)" % s.player["pos"].y)
	# thap chuong
	s = _new(3)
	s.player["pos"] = Vector3(0, 6, 6)
	for i in 120:
		PS.step(s, _inp(Vector2(0, -1)), ev)
	t.ok(Vector2(s.player["pos"].x, s.player["pos"].z).length() >= 1.99, "thap chan")
	# gio
	s = _new()
	s.wind = {"active": true, "push": Vector2(2, 0)}
	for i in 60:
		PS.step(s, _inp(), ev)
	t.near(s.player["pos"].x, 2.0, "gio day 2 m/s")
	# tat dinh
	var a := _new()
	var b := _new()
	for i in 200:
		var inp := _inp(Vector2(cos(i * 0.1), sin(i * 0.1)), i % 50 == 0, i % 37 == 0)
		PS.step(a, inp, ev)
		PS.step(b, inp, ev)
	t.eq(a.player["pos"], b.player["pos"], "tat dinh")
	# timers
	s = _new()
	s.player["invuln_ticks"] = 2
	s.player["pulse_cd_ticks"] = 100
	for i in 3:
		PS.step(s, _inp(), ev)
	t.eq(s.player["invuln_ticks"], 0, "invuln san 0")
	t.eq(s.player["pulse_cd_ticks"], 97, "pulse cd giam")
	# no-op
	for st in ["won", "lost", "paused"]:
		s = _new()
		if st == "paused":
			s.paused = true
		else:
			s.status = st
		s.player["invuln_ticks"] = 5
		PS.step(s, _inp(Vector2(1, 0), true, true), ev)
		t.eq(s.player["pos"], Vector3.ZERO, "no-op pos " + st)
		t.eq(s.player["invuln_ticks"], 5, "no-op timer " + st)
