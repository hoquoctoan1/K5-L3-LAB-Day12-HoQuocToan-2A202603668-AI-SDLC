extends RefCounted
const LifecycleSystem = preload("res://src/core/systems/lifecycle_system.gd")

func _mk(steps: int = 0, tl: float = 300.0) -> SimState:
	var s := SimState.new()
	s.steps = steps
	s.time_left_initial = tl
	s.player = SimState.make_default_player()
	for i in GameConfig.LANTERN_COUNT_NIGHT1:
		s.lanterns.append({"id": "L%d" % (i + 1), "pos": Vector3.ZERO, "lit": false, "deposited": 0})
	return s

func _light(s: SimState) -> void:
	for l in s.lanterns:
		l["lit"] = true

func _overs(ev: Array) -> int:
	var n := 0
	for e in ev:
		if e["name"] == "game_over":
			n += 1
	return n

func run(t: TS) -> void:
	# thang + bonus 1 lan
	var s := _mk(60, 300.0)
	_light(s)
	s.player["flames"] = 2
	var ev := []
	LifecycleSystem.step(s, {}, ev)
	var secs := int(floor(300.0 - 61.0 / 60.0))
	var want := GameConfig.SCORE_PER_FLAME_LEFT * 2 + GameConfig.SCORE_PER_SECOND_LEFT * secs
	t.eq(s.status, "won", "won")
	t.eq(s.loss_reason, "", "no loss_reason")
	t.eq(s.score, want, "bonus tu config")
	t.eq(ev.size(), 1, "1 event")
	t.eq(ev[0]["data"], {"result": "won", "reason": "all_lit"}, "event won")
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.score, want, "bonus khong lap")
	t.eq(_overs(ev), 1, "khong game_over lan 2")

	# no_flames
	s = _mk()
	s.player["flames"] = 0
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "lost", "no_flames lost")
	t.eq(s.loss_reason, "no_flames", "no_flames reason")
	t.eq(ev[0]["data"], {"result": "lost", "reason": "no_flames"}, "event no_flames")

	# dawn dung tick: time 1s => 60 tick
	s = _mk(58, 1.0)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "chua dawn o step 59")
	s.steps = 59
	t.near(LifecycleSystem.time_left_after(s), 0.0, "time_left_after = 0")
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "lost", "dawn o step 60")
	t.eq(s.loss_reason, "dawn", "dawn reason")
	t.eq(ev[0]["data"], {"result": "lost", "reason": "dawn"}, "event dawn")

	# thang va thua cung tick => won, bonus giay = 0
	s = _mk(59, 1.0)
	_light(s)
	s.player["flames"] = 0
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "won", "win > lose")
	t.eq(s.score, 0, "flames 0, giay 0 => bonus 0")
	t.eq(_overs(ev), 1, "1 game_over")

	# no_flames + dawn => no_flames
	s = _mk(59, 1.0)
	s.player["flames"] = 0
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.loss_reason, "no_flames", "no_flames uu tien hon dawn")

	# terminal: khong lap
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(ev.size(), 0, "khong event sau terminal")
	s = _mk()
	s.status = "won"
	_light(s)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.score, 0, "won roi khong cong them")
	t.eq(ev.size(), 0, "won roi khong event")
