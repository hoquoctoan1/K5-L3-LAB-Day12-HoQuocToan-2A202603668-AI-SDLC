extends RefCounted
## LifecycleSystem v3 (contract v1.2, TICKET-03 muc 3 + 5). state.steps = so tick da hoan tat.
## P3 regression: cac kiem tra all_lit / thang som / thuong giay cua v1.1 da bi THAY THE va duoc viet lai o day
## (ly do: docs/notes/p3-regression-changes.md).
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

## Thap n den dau tien (n < 0: tat ca) voi fuel_units cho truoc.
func _light(s: SimState, n: int = -1, units: int = GameConfig.FUEL_MAX_UNITS) -> void:
	var k := 0
	for l in s.lanterns:
		if n >= 0 and k >= n:
			break
		l["lit"] = true
		l["ever_lit"] = true
		l["fuel_units"] = units
		k += 1

func _overs(ev: Array) -> int:
	var n := 0
	for e in ev:
		if e["name"] == "game_over":
			n += 1
	return n

func run(t: TS) -> void:
	# tong tick moi Dem (v1.2: 240/270/300 s)
	for n in [1, 2, 3]:
		var sn := _mk(0, -1.0, n)
		t.eq(LifecycleSystem.ticks_total(sn), GameConfig.night_duration_ticks(n), "ticks_total night %d" % n)
	t.eq(GameConfig.night_duration_ticks(1), 14400, "14400")
	t.eq(GameConfig.night_duration_ticks(2), 16200, "16200")
	t.eq(GameConfig.night_duration_ticks(3), 18000, "18000")

	# khong con thang som: Dem 1 thap du 5/5 o tick 61 -> van playing
	var s := _mk(61)
	_light(s)
	var ev := []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "thap du den truoc binh minh: KHONG ket thuc")
	t.eq(ev.size(), 0, "khong game_over som")

	# Dem 1 binh minh: 3/5 sang -> thang dawn_survived + thuong
	s = _mk(14400)
	_light(s, 3, 1234)           # floor(1234/60) = 20
	s.player["flames"] = 2
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "won", "Dem 1 3/5 -> won")
	t.eq(s.loss_reason, "", "won: khong loss_reason")
	t.eq(ev.size(), 1, "1 event")
	t.eq(ev[0]["data"], {"result": "won", "reason": "dawn_survived"}, "event dawn_survived")
	var want := 3 * (50 + 20) + 50 * 2
	t.eq(LifecycleSystem.win_bonus(s), want, "bonus = sum(50 + floor(fuel)) + 50*flames")
	t.eq(s.score, want, "diem thuong binh minh")
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.score, want, "bonus khong lap")
	t.eq(_overs(ev), 1, "khong game_over lan 2")

	# Dem 1 binh minh: 2/5 -> thua dawn
	s = _mk(14400)
	_light(s, 2)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "lost", "Dem 1 2/5 -> lost")
	t.eq(s.loss_reason, "dawn", "reason dawn")
	t.eq(ev[0]["data"], {"result": "lost", "reason": "dawn"}, "event dawn")
	t.eq(s.score, 0, "thua: khong thuong")

	# nguong tung Dem: 4/6 (Dem 2), 5/7 (Dem 3); thieu 1 thi thua
	for c in [[2, 4], [3, 5]]:
		var night: int = c[0]
		var need: int = c[1]
		s = _mk(GameConfig.night_duration_ticks(night), -1.0, night)
		_light(s, need - 1)
		LifecycleSystem.step(s, {}, [])
		t.eq(s.loss_reason, "dawn", "Dem %d: %d den -> dawn" % [night, need - 1])
		s = _mk(GameConfig.night_duration_ticks(night), -1.0, night)
		_light(s, need)
		LifecycleSystem.step(s, {}, [])
		t.eq(s.status, "won", "Dem %d: %d den -> won" % [night, need])

	# fuel 100 -> floor 100: 1 den day + 3 lua: 150 + 150
	s = _mk(14400)
	_light(s, 3)
	s.player["flames"] = 3
	LifecycleSystem.step(s, {}, [])
	t.eq(s.score, 3 * 150 + 150, "3 den day dau, 3 lua")

	# no_flames (giua Dem)
	s = _mk(1)
	s.player["flames"] = 0
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "lost", "no_flames lost")
	t.eq(s.loss_reason, "no_flames", "no_flames reason")
	t.eq(ev[0]["data"], {"result": "lost", "reason": "no_flames"}, "event no_flames")

	# no_flames o tick binh minh du den -> no_flames (luon uu tien)
	s = _mk(14400)
	_light(s)
	s.player["flames"] = 0
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.loss_reason, "no_flames", "no_flames > dawn_survived o tick cuoi")
	t.eq(s.score, 0, "khong bonus khi thua")
	t.eq(_overs(ev), 1, "1 game_over")

	# dawn dung tick: time 1s => 60 tick
	s = _mk(59, 1.0)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.status, "playing", "chua dawn o step 59")
	t.eq(LifecycleSystem.ticks_left(s), 1, "con 1 tick")
	s.steps = 60
	t.eq(LifecycleSystem.ticks_left(s), 0, "het tick")
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.loss_reason, "dawn", "dawn o step 60")

	# Dem 3 binh minh dung tick 18000
	s = _mk(17999, -1.0, 3)
	LifecycleSystem.step(s, {}, [])
	t.eq(s.status, "playing", "night3 tick 17999 playing")
	s.steps = 18000
	LifecycleSystem.step(s, {}, [])
	t.eq(s.loss_reason, "dawn", "night3 dawn tai 18000")

	# khong co den: khong the thang
	s = _mk(60, 1.0)
	s.lanterns = []
	LifecycleSystem.step(s, {}, [])
	t.eq(s.loss_reason, "dawn", "0 den -> dawn")

	# terminal / paused
	s = _mk(14400)
	s.status = "won"
	_light(s)
	ev = []
	LifecycleSystem.step(s, {}, ev)
	t.eq(s.score, 0, "won roi khong cong them")
	t.eq(ev.size(), 0, "won roi khong event")
	s = _mk(60, 1.0)
	s.paused = true
	LifecycleSystem.step(s, {}, [])
	t.eq(s.status, "playing", "paused: khong xet thang/thua")
