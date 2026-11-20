extends RefCounted
const PS = preload("res://src/core/systems/player_system.gd")

func _inp(move := Vector2.ZERO, jump := false) -> Dictionary:
	return {"move": move, "cam_yaw_deg": 0.0, "jump": jump, "interact": false, "pulse": false}

func _new() -> SimState:
	var s := SimState.new()
	s.player = SimState.make_default_player()
	return s

func run(t: TS) -> void:
	var dt := GameConfig.DT
	# di thang
	var s := _new()
	var ev := []
	for i in 60:
		PS.step(s, _inp(Vector2(1, 0)), ev)
	t.near(s.player["pos"].x, GameConfig.PLAYER_SPEED * 60.0 * dt, "di thang 60 tick")
	t.near(s.player["pos"].z, 0.0, "z khong doi")
	t.eq(ev.size(), 0, "khong event")
	# cheo chuan hoa
	s = _new()
	var d := Vector2(1, 1).normalized()
	for i in 30:
		PS.step(s, _inp(d), ev)
	var dist := Vector2(s.player["pos"].x, s.player["pos"].z).length()
	t.near(dist, GameConfig.PLAYER_SPEED * 30.0 * dt, "cheo quang duong = toc do")
	# nhay: dung tick roi xuong dat
	s = _new()
	PS.step(s, _inp(Vector2.ZERO, true), ev)
	t.ok(not s.player["on_ground"], "roi dat sau nhay")
	t.ok(s.player["pos"].y > 0.0, "len cao")
	var n := 1
	var max_y: float = s.player["pos"].y
	while not s.player["on_ground"] and n < 1000:
		PS.step(s, _inp(), ev)
		max_y = maxf(max_y, s.player["pos"].y)
		n += 1
	var expect := int(ceil(2.0 * GameConfig.JUMP_SPEED / GameConfig.GRAVITY / dt))
	t.ok(absi(n - expect) <= 2, "tiep dat sau ~%d tick (got %d)" % [expect, n])
	t.near(s.player["pos"].y, 0.0, "y = 0 khi dat")
	t.near(s.player["vy"], 0.0, "vy = 0 khi dat")
	t.ok(max_y <= GameConfig.JUMP_SPEED * GameConfig.JUMP_SPEED / (2.0 * GameConfig.GRAVITY) + 0.2, "do cao toi da hop ly")
	# khong double jump
	s = _new()
	PS.step(s, _inp(Vector2.ZERO, true), ev)
	for i in 5:
		PS.step(s, _inp(), ev)
	var vy_before: float = s.player["vy"]
	PS.step(s, _inp(Vector2.ZERO, true), ev)
	t.ok(s.player["vy"] < vy_before, "nhay lan 2 tren khong bi bo qua")
	# gioi han dao
	s = _new()
	for i in 600:
		PS.step(s, _inp(Vector2(1, 1).normalized()), ev)
		var pp: Vector3 = s.player["pos"]
		if Vector2(pp.x, pp.z).length() > GameConfig.ISLAND_RADIUS + 0.0001:
			t.ok(false, "vuot ban kinh dao tick %d" % i)
			break
	var pe: Vector3 = s.player["pos"]
	t.near(Vector2(pe.x, pe.z).length(), GameConfig.ISLAND_RADIUS, "dung o mep dao")
	t.eq(ev.size(), 0, "roi dao khong event")
	# timers
	s = _new()
	s.player["invuln_left"] = 0.05
	s.player["pulse_cd_left"] = 1.0
	PS.step(s, _inp(), ev)
	t.near(s.player["invuln_left"], 0.05 - dt, "invuln giam")
	t.near(s.player["pulse_cd_left"], 1.0 - dt, "pulse_cd giam")
	for i in 10:
		PS.step(s, _inp(), ev)
	t.near(s.player["invuln_left"], 0.0, "invuln san 0")
	t.ok(s.player["pulse_cd_left"] > 0.0 and s.player["pulse_cd_left"] < 1.0, "pulse_cd con lai")
	# no-op khi khong playing
	for st in ["won", "lost"]:
		s = _new()
		s.status = st
		s.player["invuln_left"] = 1.0
		PS.step(s, _inp(Vector2(1, 0), true), ev)
		t.eq(s.player["pos"], Vector3.ZERO, "no-op pos " + st)
		t.near(s.player["invuln_left"], 1.0, "no-op timer " + st)
		t.ok(s.player["on_ground"], "no-op nhay " + st)
