extends RefCounted
## LifecycleSystem v2: state.steps = so tick da hoan tat (Sim tang o buoc 2 truoc khi goi lifecycle).
const LifecycleSystem = preload("res://src/core/systems/lifecycle_system.gd")

func _mk(steps: int = 0, tl: float = -1.0, night: int = 1) -> SimState:
	var s := SimState.new()
	s.night = night
	s.steps = steps
	s.time_left_initial = GameConfig.night_duration_s(night) if tl < 0.0 else tl
	s.player = SimState.make_default_player()
	for i in GameConfig.lantern_count(night):
		s.lanterns.append(SimState.make_lantern("L%d" % (i + 1), Vector3.ZERO))
	return s

func _light(s: SimState, n: int = -1) -> void:
	var k := 0
	for l in s.lanterns:
		if n >= 0 and k >= n:
			break
		l["lit"] = true
		k += 1

func _overs(ev: Array) -> int:
	var n := 0
	for e in ev:
		if e["name"] == "game_over":
			n += 1
	return n

func run(t: TS) -> void:
	# tong tick moi Dem tu GameConfig
	for n in [1, 2, 3]:
		var sn := _mk(0, -1.0, n)
		t.eq(LifecycleSystem.ticks_total(sn), GameConfig.night_duration_ticks(n), "ticks_total night %d" % n)
	t.eq(GameConfig.night_duration_ticks(1), 18000, "18000")
	t.eq(GameConfig.night_duration_ticks(2), 19800, "19800")
	t.eq(GameConfig.night_duration_ticks(3), 21600, "21600")

	# thang + bonus 1 lan: steps 61 => con 18000-61 tick => floor(298.98) = 298 giay
	var s := _mk(61)
	_light(s)
	s.player["flames"] = 2
	var ev := []
	LifecycleSystem.step(s, {}, ev)
	var secs := int(floor(float(GameConfig.night_duration_ticks(1) - 61) / 60.0))
	var want := GameConfig.SCORE_PER_FLAME_LEFT * 2 + GameConfig.SCORE_PER_SECOND_LEFT * secs
	t.eq(secs, 298, "giay con lai")
	t.eq(want, 2 * 298 + 100, "bonus = floor(giay)*2 + 50*flames")
	t.eq(s.status, "won", "won")
	t.eq(s.loss_reason, "", "no loss_reason")
	t.eq(s.score, want, "bonus tu config")
	t.eq(ev.size(), 1, "1 event")
	t.eq(ev[0]["data"], {"result": "won", "reason": "all_lit"}, "event won")
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.score, want, "bonus khong lap")
	t.eq(_overs(ev), 1, "khong game_over lan 2")

	# Dem 2: 6 den; 5 sang chua thang (khong dung LANTERN_COUNT_NIGHT1)
	s = _mk(10, -1.0, 2)
	_light(s, 5)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "night2: 5/6 den chua thang")
	_light(s)
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "won", "night2: 6/6 thang")
	t.eq(s.score, GameConfig.SCORE_PER_SECOND_LEFT * int(floor((19800.0 - 10.0) / 60.0)) + GameConfig.SCORE_PER_FLAME_LEFT * 3, "night2 bonus")
	s = _mk(10, -1.0, 3)
	_light(s, 6)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "night3: 6/7 den chua thang")

	# no_flames
	s = _mk(1)
	s.player["flames"] = 0
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "lost", "no_flames lost")
	t.eq(s.loss_reason, "no_flames", "no_flames reason")
	t.eq(ev[0]["data"], {"result": "lost", "reason": "no_flames"}, "event no_flames")

	# dawn dung tick: time 1s => 60 tick
	s = _mk(59, 1.0)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "chua dawn o step 59")
	t.eq(LifecycleSystem.ticks_left(s), 1, "con 1 tick")
	s.steps = 60
	t.eq(LifecycleSystem.ticks_left(s), 0, "het tick")
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "lost", "dawn o step 60")
	t.eq(s.loss_reason, "dawn", "dawn reason")
	t.eq(ev[0]["data"], {"result": "lost", "reason": "dawn"}, "event dawn")

	# dawn mac dinh Dem 3 dung tick 21600
	s = _mk(21599, -1.0, 3)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "night3 tick 21599 playing")
	s.steps = 21600
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.loss_reason, "dawn", "night3 dawn tai 21600")

	# thang dung tick het gio => won, bonus giay = 0
	s = _mk(60, 1.0)
	_light(s)
	s.player["flames"] = 3
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "won", "all_lit > dawn (cung tick)")
	t.eq(s.score, GameConfig.SCORE_PER_FLAME_LEFT * 3, "giay 0 => chi bonus lua")
	t.eq(_overs(ev), 1, "1 game_over")

	# het lua va moi den sang cung tick => no_flames (luon uu tien, ticket v1.1)
	s = _mk(30, 1.0)
	_light(s)
	s.player["flames"] = 0
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "lost", "no_flames > all_lit")
	t.eq(s.loss_reason, "no_flames", "reason no_flames")
	t.eq(s.score, 0, "khong bonus khi thua")
	t.eq(_overs(ev), 1, "1 game_over")

	# no_flames + dawn => no_flames
	s = _mk(60, 1.0)
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

	# paused: khong xet
	s = _mk(60, 1.0)
	s.paused = true
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "paused: khong xet thang/thua")
