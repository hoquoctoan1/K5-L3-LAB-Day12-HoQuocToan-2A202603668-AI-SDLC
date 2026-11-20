extends RefCounted

const SimC = preload("res://src/core/sim.gd")
const Loader = preload("res://src/adapters/headless/scenario_loader.gd")
const Codec = preload("res://src/adapters/headless/contract_codec.gd")

static func idle() -> Dictionary:
	return {"move": Vector2.ZERO, "cam_yaw_deg": 0.0, "jump": false, "interact": false, "pulse": false}

func _hand() -> Dictionary:
	return {"player": {"pos": [0, 0, 0], "carried": 5, "flames": 3},
		"random_motes": false, "random_shades": false, "motes": [], "shades": [],
		"lanterns": [{"id": "L1", "pos": [0, 0, 1], "deposited": 0}]}

func run(t: TS) -> void:
	# khoi tao: 5 lantern, L1 (0,0,25), mote/shade ngau nhien sau begin()
	var s := SimC.new(1)
	t.eq(s.state.lanterns.size(), 5, "5 lanterns")
	t.near(s.state.lanterns[0]["pos"].z, GameConfig.LANTERN_RING_RADIUS, "L1 z")
	t.eq(s.state.motes.size(), 0, "chua mote truoc begin")
	s.begin()
	t.eq(s.state.motes.size(), GameConfig.INITIAL_MOTES, "mote ban dau")
	t.eq(s.state.shades.size(), GameConfig.INITIAL_SHADES, "shade ban dau")
	t.near(s.state.time_left_initial, GameConfig.NIGHT1_DURATION_S, "time default")

	# scenario random=false: dung danh sach liet ke
	var s2 := SimC.new(5)
	var sc := {"random_motes": false, "random_shades": false, "motes": [[0, 0, 5]], "shades": [{"pos": [10, 0, 0]}]}
	t.ok(Loader.apply(s2.state, sc)["ok"], "apply")
	s2.begin()
	t.eq(s2.state.motes.size(), 1, "dung 1 mote")
	t.eq(s2.state.shades.size(), 1, "dung 1 shade")
	var s2b := SimC.new(5)
	Loader.apply(s2b.state, {"random_motes": false, "random_shades": false})
	s2b.begin()
	t.eq(s2b.state.motes.size() + s2b.state.shades.size(), 0, "random=false, khong liet ke => rong")

	# hand scenario: interact tick 0
	var h := SimC.new(1)
	t.ok(Loader.apply(h.state, _hand())["ok"], "hand apply")
	var f := idle()
	f["interact"] = true
	var ev := h.step(f)
	t.eq(h.state.steps, 1, "steps 1")
	t.eq(h.state.tick, 1, "tick 1")
	var names: Array = []
	for e in ev:
		names.append(e["name"])
		t.eq(e["tick"], 1, "event tick")
	t.eq(names, ["deposit", "lantern_lit"], "events")
	t.eq(ev[0]["data"], {"lantern_id": "L1", "amount": 5, "deposited": 5}, "deposit data")
	t.eq(h.state.player["carried"], 0, "carried 0")
	t.ok(h.state.lanterns[0]["lit"], "L1 lit")
	t.eq(h.state.status, "playing", "van playing")

	# reset => giong het
	var a := SimC.new(7)
	a.begin()
	var snap0 := Codec.snapshot_line(a.state)
	for i in range(50):
		a.step(idle())
	a.reset(7)
	a.begin()
	t.eq(Codec.snapshot_line(a.state), snap0, "reset -> state ban dau")
	var b := SimC.new(7)
	b.begin()
	for i in range(50):
		a.step(idle())
		b.step(idle())
	t.eq(Codec.snapshot_line(a.state), Codec.snapshot_line(b.state), "tat dinh")

	# time_left theo steps/60
	var d := SimC.new(1)
	for i in range(120):
		d.step(idle())
	t.near(d.state.time_left_s(), GameConfig.NIGHT1_DURATION_S - 2.0, "time_left sau 120 buoc")

	# dawn voi time_left_s=1 => sau 60 buoc, game_over dawn
	var e := SimC.new(1)
	Loader.apply(e.state, {"random_motes": false, "random_shades": false, "time_left_s": 1})
	var last: Array = []
	var n := 0
	while e.state.status == "playing" and n < 200:
		last = e.step(idle())
		n += 1
	t.eq(n, 60, "dawn sau 60 buoc")
	t.eq(e.state.status, "lost", "lost")
	t.eq(e.state.loss_reason, "dawn", "dawn")
	t.eq(last[last.size() - 1]["name"], "game_over", "game_over event")
	t.eq(e.step(idle()), [], "het playing => []")
	t.eq(e.state.steps, 60, "steps dung")
