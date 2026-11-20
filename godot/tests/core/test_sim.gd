extends RefCounted
## Sim v2 (P2-C1): khoi tao 3 Dem, night_start, pause, thu tu 12 buoc, tat dinh, reset.

const SimC = preload("res://src/core/sim.gd")
const Loader = preload("res://src/adapters/headless/scenario_loader.gd")
const Codec = preload("res://src/adapters/headless/contract_codec.gd")
const MapBuilder = preload("res://src/core/maps/map_builder.gd")

static func idle() -> Dictionary:
	return {"move": Vector2.ZERO, "cam_yaw_deg": 0.0, "jump": false, "interact": false, "pulse": false, "dash": false, "pause": false}

static func fr(over: Dictionary) -> Dictionary:
	var f := idle()
	for k in over:
		f[k] = over[k]
	return f

## Ten event, bo night_start (chi xuat hien o step dau).
static func names(ev: Array) -> Array:
	var out: Array = []
	for e in ev:
		if e["name"] != "night_start":
			out.append(e["name"])
	return out

static func find(ev: Array, n: String) -> Dictionary:
	for e in ev:
		if e["name"] == n:
			return e
	return {}

## Snapshot bo truong tick (de so sanh khi tick khac nhau vi pause).
static func snap_no_tick(st: SimState) -> String:
	var s := Codec.snapshot_line(st)
	var i := s.find('"sim_tick"')
	return s.substr(i)

func _hand() -> Dictionary:
	return {"player": {"pos": [0, 0, 0], "carried": GameConfig.LANTERN_COST, "flames": 3},
		"random_motes": false, "random_shades": false, "motes": [], "shades": [],
		"lanterns": [{"id": "L1", "pos": [0, 0, 1], "deposited": 0}]}

func run(t: TS) -> void:
	_init_nights(t)
	_scenario_lists(t)
	_hand_deposit(t)
	_pause(t)
	_ordering(t)
	_spawn_next_tick(t)
	_determinism_reset(t)
	_time(t)

func _init_nights(t: TS) -> void:
	# khoi tao Dem 1/2/3: map, so den, vi tri den, mote 20 sau begin, shade 0, charm theo map, thoi gian
	var want_charms := {1: 0, 2: 1, 3: 2}
	for n in [1, 2, 3]:
		var s := SimC.new(1, n)
		var m := MapBuilder.build(n)
		t.eq(s.state.night, n, "night %d" % n)
		t.eq(int(s.state.map.get("night", -1)), n, "map night %d" % n)
		t.eq(s.state.lanterns.size(), GameConfig.lantern_count(n), "so den night %d" % n)
		t.eq(s.state.lanterns.size(), [0, 5, 6, 7][n], "5/6/7 den night %d" % n)
		var same := true
		for i in s.state.lanterns.size():
			same = same and s.state.lanterns[i]["pos"] == m["lanterns"][i]["pos"] and s.state.lanterns[i]["id"] == "L%d" % (i + 1)
		t.ok(same, "vi tri den theo map night %d" % n)
		t.eq(s.state.motes.size(), 0, "chua mote truoc begin night %d" % n)
		t.near(s.state.time_left_initial, GameConfig.night_duration_s(n), "time night %d" % n)
		s.begin()
		s.begin()   # idempotent
		t.eq(s.state.motes.size(), GameConfig.INITIAL_MOTES, "20 mote ban dau night %d" % n)
		var distinct := {}
		for mo in s.state.motes:
			distinct[mo["point_index"]] = true
		t.eq(distinct.size(), GameConfig.INITIAL_MOTES, "mote tren diem rieng biet night %d" % n)
		t.eq(s.state.shades.size(), 0, "0 shade ban dau night %d" % n)
		t.eq(s.state.drifters.size(), 0, "0 drifter ban dau night %d" % n)
		t.eq(s.state.charms.size(), want_charms[n], "charm theo map night %d" % n)
		t.eq(s.state.player["pos"], m["start"]["pos"], "player o diem xuat phat night %d" % n)
		t.eq(s.state.player["flames"], GameConfig.FLAMES, "flames day night %d" % n)
		var ev := s.step(idle())
		t.ok(ev.size() >= 1 and ev[0]["name"] == "night_start", "night_start la event dau night %d" % n)
		t.eq(ev[0]["data"], {"night": n}, "night_start data night %d" % n)
		t.eq(ev[0]["tick"], 1, "night_start tick 1")
		var ev2 := s.step(idle())
		t.eq(find(ev2, "night_start"), {}, "night_start chi 1 lan night %d" % n)
		t.ok(s.state.map_height_fn.is_valid(), "map_height_fn gan night %d" % n)
	# Dem 2: height_at theo map that (dao B o x=70; cau; bien)
	var s2 := SimC.new(1, 2)
	t.near(s2.state.height_at(70.0, 0.0, 0.0), 0.0, "height dao B")
	t.near(s2.state.height_at(35.0, 0.0, 0.0), 0.0, "height cau")
	t.ok(s2.state.height_at(35.0, 10.0, 0.0) < -1.0e8, "ngoai cau = void")

func _scenario_lists(t: TS) -> void:
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
	# scenario night 2 tham chieu L6 (chi co o Dem 2)
	var s3 := SimC.new(1, 2)
	t.ok(Loader.apply(s3.state, {"lanterns": [{"id": "L6", "deposited": 3}]})["ok"], "L6 hop le o Dem 2")
	t.ok(not Loader.apply(SimC.new(1, 1).state, {"lanterns": [{"id": "L6"}]})["ok"], "L6 khong co o Dem 1")

func _hand_deposit(t: TS) -> void:
	var h := SimC.new(1)
	t.ok(Loader.apply(h.state, _hand())["ok"], "hand apply")
	var ev := h.step(fr({"interact": true}))
	t.eq(h.state.steps, 1, "steps 1")
	t.eq(h.state.tick, 1, "tick 1")
	for e in ev:
		t.eq(e["tick"], 1, "event tick")
	t.eq(names(ev), ["deposit", "lantern_lit"], "events")
	t.eq(find(ev, "deposit")["data"], {"lantern_id": "L1", "amount": GameConfig.LANTERN_COST, "deposited": GameConfig.LANTERN_COST}, "deposit data")
	t.eq(h.state.player["carried"], 0, "carried 0")
	t.ok(h.state.lanterns[0]["lit"], "L1 lit")
	t.eq(h.state.status, "playing", "van playing")

func _pause(t: TS) -> void:
	var p := SimC.new(3)
	for i in 10:
		p.step(fr({"move": Vector2(0, 1)}))
	var pos10: Vector3 = p.state.player["pos"]
	var nmotes := p.state.motes.size()
	var ev := p.step(fr({"pause": true, "move": Vector2(0, 1)}))
	t.eq(names(ev), ["paused"], "pause press => paused{}")
	t.eq(ev[0]["data"], {}, "paused data {}")
	t.eq(ev[0]["tick"], 11, "paused event tick 11")
	t.ok(p.state.paused, "state.paused")
	t.eq(p.state.tick, 11, "tick tang khi pause")
	t.eq(p.state.steps, 10, "steps dung khi vua pause")
	t.eq(p.state.player["pos"], pos10, "vua pause: khong di chuyen trong tick do")
	t.ok(Codec.snapshot_line(p.state).contains('"state":"paused"'), "snapshot state paused")
	var tl := p.state.time_left_s()
	var before := snap_no_tick(p.state)
	for i in 400:
		var e := p.step(fr({"move": Vector2(1, 0), "jump": true, "pulse": true, "dash": true, "interact": true}))
		if not e.is_empty():
			t.ok(false, "paused: khong event (tick %d)" % p.state.tick)
	t.eq(p.state.tick, 411, "tick van tang khi paused")
	t.eq(p.state.steps, 10, "steps dung yen khi paused")
	t.near(p.state.time_left_s(), tl, "thoi gian dung yen")
	t.eq(snap_no_tick(p.state), before, "state dung yen khi paused (vi tri, mote, spawn tick 300 khong xay ra)")
	t.eq(p.state.motes.size(), nmotes, "mote khong respawn khi paused")
	t.eq(p.state.shades.size(), 0, "khong spawn shade khi paused (lich tick 300 dung)")
	# resume: chay tiep buoc 2..11 trong CUNG step
	ev = p.step(fr({"pause": true, "move": Vector2(0, 1)}))
	t.eq(names(ev).slice(0, 1), ["resumed"], "resumed{} la event dau")
	t.eq(ev[0]["tick"], 412, "resumed tick")
	t.ok(not p.state.paused, "het paused")
	t.eq(p.state.steps, 11, "resume chay step trong cung tick")
	t.ok((p.state.player["pos"] as Vector3).z > pos10.z, "resume: di chuyen ngay tick do")
	# pause ngay step dau: [night_start, paused]
	var q := SimC.new(1)
	ev = q.step(fr({"pause": true}))
	var all_names: Array = []
	for e in ev:
		all_names.append(e["name"])
	t.eq(all_names, ["night_start", "paused"], "pause o step dau")
	t.eq(q.state.steps, 0, "steps 0")
	# tuong duong: pause/resume chi lam tre tick, khong doi mo phong
	var a := SimC.new(9)
	var b := SimC.new(9)
	var mv := fr({"move": Vector2(0.6, 0.8)})
	for i in 200:
		a.step(mv)
	a.step(fr({"pause": true}))
	for i in 150:
		a.step(mv)
	var rf := mv.duplicate()
	rf["pause"] = true
	a.step(rf)
	for i in 199:
		a.step(mv)
	for i in 400:
		b.step(mv)
	t.eq(a.state.steps, 400, "a steps 400")
	t.eq(a.state.tick, 551, "a tick 551")
	t.eq(snap_no_tick(a.state), snap_no_tick(b.state), "pause/resume == chay lien tuc (modulo tick)")
	t.eq(a.state.shades.size(), b.state.shades.size(), "shade spawn giong nhau")

func _ordering(t: TS) -> void:
	# buoc 4 truoc 5: nhat mote va nap cung tick (carried 9 + 1 = 10 -> nap 10)
	var s := SimC.new(1)
	Loader.apply(s.state, {"player": {"pos": [0, 0, 0], "carried": 9}, "random_motes": false, "random_shades": false,
		"motes": [[0, 0, 0.5]], "lanterns": [{"id": "L1", "pos": [0, 0, 2]}]})
	var ev := s.step(fr({"interact": true}))
	t.eq(names(ev), ["mote_picked", "deposit", "lantern_lit"], "nhat roi nap cung tick (9+1 = 10 => sang)")
	t.eq(find(ev, "deposit")["data"]["amount"], 10, "nap ca mote vua nhat")
	# buoc 9: Gio Lac cuop TRUOC Bong Muc hit (Dem 2)
	var d := SimC.new(1, 2)
	t.ok(Loader.apply(d.state, {"player": {"pos": [0, 0, 0], "carried": 6, "flames": 3},
		"random_motes": false, "random_shades": false, "random_drifters": false, "motes": [], "charms": [],
		"drifters": [{"pos": [0.5, 0, 0], "state": "chase"}], "shades": [{"pos": [0.5, 0, 0], "state": "chase"}]})["ok"], "apply steal+hit")
	ev = d.step(idle())
	t.eq(names(ev), ["drifter_steal", "player_hit"], "cuop truoc hit")
	t.eq(find(ev, "drifter_steal")["data"], {"drifter_id": "D1", "amount": 3, "carried": 3}, "steal tu 6")
	t.eq(find(ev, "player_hit")["data"], {"by": "shade", "flames": 2, "dropped": 1}, "hit roi floor(3/2) sau cuop")
	t.eq(d.state.player["carried"], 2, "con 2")
	# buoc 7 truoc 8-9: Toa Sang cung tick chan hit (shade choang khong cham)
	var pz := SimC.new(1)
	Loader.apply(pz.state, {"player": {"pos": [0, 0, 0], "carried": 3}, "random_motes": false, "random_shades": false,
		"motes": [], "shades": [{"pos": [0.9, 0, 0], "state": "chase"}]})
	ev = pz.step(fr({"pulse": true}))
	t.eq(names(ev), ["pulse"], "pulse truoc cham => khong hit")
	t.eq(pz.state.player["flames"], 3, "khong mat lua")
	# buoc 3 truoc 4: di chuyen roi moi nhat (mote cach 1.05 m, buoc 0.1 m => nhat ngay tick 1)
	var mvs := SimC.new(1)
	Loader.apply(mvs.state, {"random_motes": false, "random_shades": false, "motes": [[0, 0, 1.05]]})
	ev = mvs.step(fr({"move": Vector2(0, 1)}))
	t.eq(names(ev), ["mote_picked"], "di chuyen truoc nhat")
	# buoc 5 truoc 11: thap den cuoi => thang cung tick
	var w := SimC.new(1)
	Loader.apply(w.state, {"player": {"carried": 10}, "random_motes": false, "random_shades": false,
		"lanterns": [{"id": "L1", "pos": [0, 0, 1]}, {"id": "L2", "lit": true}, {"id": "L3", "lit": true}, {"id": "L4", "lit": true}, {"id": "L5", "lit": true}]})
	ev = w.step(fr({"interact": true}))
	t.eq(names(ev), ["deposit", "lantern_lit", "game_over"], "thang cung tick")
	t.eq(w.state.score, GameConfig.SCORE_PER_LANTERN + GameConfig.SCORE_PER_SECOND_LEFT * int(floor((18000.0 - 1.0) / 60.0)) + GameConfig.SCORE_PER_FLAME_LEFT * 3, "diem thang")
	t.eq(w.step(idle()), [], "het playing => []")

func _spawn_next_tick(t: TS) -> void:
	# shade dau: 2 con tai tick 300, trang thai spawning (chua tuong tac)
	var s := SimC.new(2)
	Loader.apply(s.state, {"random_motes": false})
	var ev: Array = []
	for i in 300:
		ev = s.step(idle())
	t.eq(names(ev).count("shade_spawned"), GameConfig.SHADE_FIRST_SPAWN_COUNT, "2 shade tai tick 300")
	t.eq(s.state.tick, 300, "tick 300")
	for sh in s.state.shades:
		t.eq(sh["state"], "spawning", "shade moi: spawning")
	# mote hoi sinh o buoc 10 tick 240 vao diem trong duy nhat duoi chan May: chi nhat duoc tick 241
	var m := SimC.new(1)
	Loader.apply(m.state, {"random_shades": false})
	m.begin()
	var pts: Array = m.state.map["mote_points"]
	m.state.motes = []
	for i in range(1, pts.size()):
		m.state.motes.append(SimState.make_mote("m%d" % (100 + i), pts[i], "random", -1, i))
	m.state.player["pos"] = pts[0]
	var picked_at := -1
	var spawned_at := -1
	for i in 245:
		var n0 := m.state.motes.size()
		ev = m.step(idle())
		if spawned_at < 0 and m.state.motes.size() > n0:
			spawned_at = m.state.tick
		if picked_at < 0 and names(ev).has("mote_picked"):
			picked_at = m.state.tick
	t.eq(spawned_at, GameConfig.MOTE_RESPAWN_FIRST_TICKS, "mote hoi sinh tick 240")
	t.eq(picked_at, GameConfig.MOTE_RESPAWN_FIRST_TICKS + 1, "mote moi chi nhat tu tick sau (241)")

func _determinism_reset(t: TS) -> void:
	# reset => giong het; tat dinh; seed khac => khac
	for n in [1, 2, 3]:
		var a := SimC.new(7, n)
		a.begin()
		var snap0 := Codec.snapshot_line(a.state)
		for i in 50:
			a.step(idle())
		a.reset(7)
		t.eq(a.state.night, n, "reset giu night %d" % n)
		a.begin()
		t.eq(Codec.snapshot_line(a.state), snap0, "reset -> state ban dau night %d" % n)
		var b := SimC.new(7, n)
		var c := SimC.new(8, n)
		var ea: Array = []
		var eb: Array = []
		for i in 2500:
			var f := fr({"move": Vector2(cos(i * 0.01), sin(i * 0.013)), "dash": i % 97 == 0, "pulse": i % 151 == 0, "jump": i % 61 == 0})
			ea.append_array(a.step(f))
			eb.append_array(b.step(f))
			c.step(f)
		t.eq(Codec.snapshot_line(a.state), Codec.snapshot_line(b.state), "tat dinh night %d" % n)
		t.eq(str(ea), str(eb), "event tat dinh night %d" % n)
		t.ok(Codec.snapshot_line(a.state) != Codec.snapshot_line(c.state), "seed khac => khac night %d" % n)
	# reset doi Dem
	var r := SimC.new(1, 1)
	r.reset(4, 3)
	t.eq(r.state.night, 3, "reset(seed, 3)")
	t.eq(r.state.lanterns.size(), 7, "7 den sau reset night 3")
	t.near(r.state.time_left_initial, GameConfig.NIGHT3_DURATION_S, "360 s")
	var ev := r.step(idle())
	t.eq(ev[0]["data"], {"night": 3}, "night_start lai sau reset")

func _time(t: TS) -> void:
	# time_left theo steps/60
	var d := SimC.new(1)
	for i in 120:
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
	# Dem 2 dawn mac dinh dung tick 19800 (khong shade/drifter de song sot)
	var n2 := SimC.new(1, 2)
	Loader.apply(n2.state, {"random_shades": false, "random_drifters": false})
	var k := 0
	var lastev: Array = []
	while n2.state.status == "playing" and k < 20000:
		lastev = n2.step(idle())
		k += 1
	t.eq(k, GameConfig.night_duration_ticks(2), "Dem 2 het gio o tick 19800")
	t.eq(n2.state.loss_reason, "dawn", "Dem 2 dawn")
	t.eq(lastev[lastev.size() - 1]["tick"], 19800, "game_over tick 19800")
