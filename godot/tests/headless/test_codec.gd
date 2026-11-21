extends RefCounted

const Codec = preload("res://src/adapters/headless/contract_codec.gd")
const Loader = preload("res://src/adapters/headless/scenario_loader.gd")
const Runner = preload("res://src/adapters/headless/headless_runner.gd")

class FakeSim extends RefCounted:
	var state: SimState = SimState.new()
	var win_at := -1
	func _init() -> void:
		state.player = SimState.make_default_player()
	func step(_f: Dictionary) -> Array:
		state.tick += 1
		state.steps += 1
		var evs: Array = [{"name": "mote_picked", "data": {"carried": 1}}]
		if win_at == state.steps:
			state.status = "won"
		return evs

func _state() -> SimState:
	var s := SimState.new()
	s.player = SimState.make_default_player()
	for i in range(1, 6):
		s.lanterns.append({"id": "L%d" % i, "pos": Vector3(0, 0, 5.0 * i), "lit": false, "deposited": 0})
	return s

func run(t: TS) -> void:
	# codec
	t.eq(Codec.fmt_num(1.23456), "1.235", "round 3")
	t.eq(Codec.fmt_num(-0.0), "0.0", "-0")
	t.eq(Codec.fmt_num(-0.0001), "0.0", "-0 sau lam tron")
	t.eq(Codec.fmt_num(12.0), "12.0", "so nguyen")
	t.eq(Codec.fmt_num(0.5), "0.5", "trim zero")
	var s := _state()
	s.player["pos"] = Vector3(-0.0, 0.0, 12.0)
	s.shades.append({"id": "S1", "pos": Vector3(30.1, 1.0, 2.0), "state": "chase", "stun_left": 0.0})
	s.motes.append({"id": "m1", "pos": Vector3(1, 0, 2)})
	var line := Codec.snapshot_line(s)
	var want := '{"type":"snapshot","tick":0,"sim_tick":0,"state":"playing","time_left_s":300.0,"score":0,"night":1,"wind":{"active":false,"dir_deg":0.0},"player":{"pos":[0.0,0.0,12.0],"vel":[0.0,0.0,0.0],"grounded":true,"invuln":0.0,"dash_cd_s":0.0,"pulse_cd_s":0.0,"charm_s":0.0,"flames":3,"carried":0,"capacity":10},"lanterns":[{"id":"L1","pos":[0.0,0.0,5.0],"lit":false,"deposited":0,"fuel":0.0,"ever_lit":false,"relit_count":0},{"id":"L2","pos":[0.0,0.0,10.0],"lit":false,"deposited":0,"fuel":0.0,"ever_lit":false,"relit_count":0},{"id":"L3","pos":[0.0,0.0,15.0],"lit":false,"deposited":0,"fuel":0.0,"ever_lit":false,"relit_count":0},{"id":"L4","pos":[0.0,0.0,20.0],"lit":false,"deposited":0,"fuel":0.0,"ever_lit":false,"relit_count":0},{"id":"L5","pos":[0.0,0.0,25.0],"lit":false,"deposited":0,"fuel":0.0,"ever_lit":false,"relit_count":0}],"shades":[{"id":"S1","pos":[30.1,1.0,2.0],"state":"chase"}],"motes_active":1,"motes":[{"id":"m1","pos":[1.0,0.0,2.0],"kind":"random","ttl_s":-1.0}],"drifters":[],"charms":[]}'
	t.eq(line, want, "snapshot byte-exact + key order")
	t.ok(JSON.parse_string(line) != null, "snapshot la JSON hop le")
	t.eq(Codec.event_line(131, {"name": "pulse", "data": {"stunned_ids": ["S1"]}}),
		'{"type":"event","tick":131,"name":"pulse","data":{"stunned_ids":["S1"]}}', "event line")
	t.eq(Codec.end_line(4800, "won", 1730), '{"type":"end","ticks":4800,"state":"won","score":1730}', "end line")

	_v11(t)

	# scenario
	var st := _state()
	var sc := {
		"player": {"pos": [1, 0, 2], "carried": 2, "flames": 1},
		"random_motes": false, "random_shades": false,
		"motes": [[0, 0, 5], [1, 0, 6]],
		"shades": [{"pos": [10, 0, 0]}, {"id": "S9", "pos": [0, 0, 1]}],
		"lanterns": [{"id": "L1", "pos": [0, 0, 25], "deposited": 3, "lit": true}],
		"time_left_s": 100}
	var r := Loader.apply(st, sc)
	t.ok(r["ok"], "scenario hop le")
	t.eq(st.player["pos"], Vector3(1, 0, 2), "player pos")
	t.eq(st.player["carried"], 2, "carried")
	t.eq(st.player["flames"], 1, "flames")
	t.eq(st.random_motes, false, "random_motes")
	t.eq(st.motes.size(), 2, "motes thay the")
	t.eq(st.motes[1]["id"], "m2", "mote id")
	t.eq(st.shades[0]["id"], "S1", "shade id auto")
	t.eq(st.shades[0]["state"], "chase", "shade state mac dinh")
	t.eq(st.shades[1]["id"], "S9", "shade id tuong minh")
	t.eq(st.lanterns[0]["lit"], true, "lantern lit")
	t.eq(st.lanterns[0]["deposited"], 3, "lantern deposited")
	t.eq(st.lanterns[1]["pos"], Vector3(0, 0, 10), "lantern khong de cap giu nguyen")
	t.near(st.time_left_s(), 100.0, "time_left_s")
	t.eq(st.score, 0, "scenario khong cong diem")
	t.eq(st.tick, 0, "scenario khong tang tick")
	t.eq(Loader.apply(_state(), {})["ok"], true, "scenario rong hop le")
	var bad := [
		[1, 2], {"player": 3}, {"player": {"pos": [1, 2]}}, {"motes": [[1, 2]]}, {"motes": "x"},
		{"shades": [{"id": "S1"}]}, {"lanterns": [{"id": "L9"}]}, {"lanterns": [{"pos": [0, 0, 0]}]},
		{"time_left_s": "a"}, {"random_motes": 1}, {"player": {"flames": -1}}]
	for b in bad:
		var s2 := _state()
		var rb := Loader.apply(s2, b)
		t.ok(not rb["ok"] and rb["error"] != "", "scenario sai: " + str(b))
		t.eq(s2.player["flames"], 3, "state khong bi sua khi loi")

	# parse_args
	var pa := Runner.parse_args(PackedStringArray(["--seed", "7", "--ticks", "100", "--out", "o.jsonl"]))
	t.ok(pa["ok"], "args hop le")
	t.eq(pa["opts"]["snapshot_every"], 10, "snapshot-every mac dinh")
	t.eq(pa["opts"]["seed"], 7, "seed")
	t.ok(not Runner.parse_args(PackedStringArray(["--seed", "7", "--ticks", "1"]))["ok"], "thieu --out")
	t.ok(not Runner.parse_args(PackedStringArray([]))["ok"], "thieu het")
	t.ok(not Runner.parse_args(PackedStringArray(["--seed", "x", "--ticks", "1", "--out", "o"]))["ok"], "seed khong so")
	t.ok(not Runner.parse_args(PackedStringArray(["--seed", "1", "--ticks", "1.5", "--out", "o"]))["ok"], "ticks khong nguyen")
	t.ok(not Runner.parse_args(PackedStringArray(["--seed", "1", "--ticks", "1", "--out", "o", "--snapshot-every", "0"]))["ok"], "every 0")
	t.ok(not Runner.parse_args(PackedStringArray(["--seed", "1", "--ticks", "1", "--out"]))["ok"], "thieu gia tri")
	t.ok(not Runner.parse_args(PackedStringArray(["--bogus", "1"]))["ok"], "tham so la")

	# simulate
	var fs := FakeSim.new()
	var lines := Runner.simulate(fs, null, 25, 10)
	var types: Array = []
	for l in lines:
		types.append(JSON.parse_string(l)["type"])
	t.eq(lines.size(), 1 + 25 + 2 + 1, "so dong")
	t.eq(JSON.parse_string(lines[0])["tick"], 0, "snapshot tick 0 dau tien")
	t.eq(JSON.parse_string(lines[1])["tick"], 1, "event dau tick=1")
	t.eq(JSON.parse_string(lines[11])["type"], "snapshot", "snapshot o tick 10")
	t.eq(JSON.parse_string(lines[11])["tick"], 10, "snapshot tick 10")
	t.eq(types[types.size() - 1], "end", "end cuoi")
	t.eq(JSON.parse_string(lines[lines.size() - 1])["ticks"], 25, "end ticks 25")
	t.eq(types.count("snapshot"), 3, "khong snapshot cuoi them")
	var l0 := Runner.simulate(FakeSim.new(), null, 0, 10)
	t.eq(l0.size(), 2, "ticks 0: snapshot + end")
	t.eq(JSON.parse_string(l0[0])["type"], "snapshot", "ticks 0 snapshot")
	t.eq(JSON.parse_string(l0[1])["ticks"], 0, "ticks 0 end")
	var fw := FakeSim.new()
	fw.win_at = 5
	var lw := Runner.simulate(fw, null, 100, 10)
	var e = JSON.parse_string(lw[lw.size() - 1])
	t.eq(e["ticks"], 5, "dung khi won")
	t.eq(e["state"], "won", "end state won")
	t.eq(lw.size(), 1 + 5 + 1, "khong snapshot sau khi dung")

func _v11(t: TS) -> void:
	var s := _state()
	s.night = 2
	s.tick = 100
	s.steps = 60
	s.paused = true
	s.wind = {"active": true, "dir_deg": 123.45678}
	s.player["vel"] = Vector3(1.0, -0.0, 2.0)
	s.player["grounded"] = false
	s.player["invuln_ticks"] = 90
	s.player["dash_cd_ticks"] = 30
	s.player["pulse_cd_ticks"] = 1
	s.player["charm_ticks"] = 600
	s.motes.append(SimState.make_mote("m1", Vector3(1, 0, 2), "dropped", 120))
	s.drifters.append(SimState.make_drifter("D1", Vector3(1, 0, 2), "flee"))
	s.drifters[0]["stolen"] = 3
	s.charms.append(SimState.make_charm("C1", Vector3(0, 0, 0)))
	s.charms[0]["available"] = false
	s.charms[0]["respawn_ticks"] = 90
	var line := Codec.snapshot_line(s)
	var d = JSON.parse_string(line)
	t.ok(d != null, "snapshot v1.1 la JSON")
	t.eq(d["state"], "paused", "paused -> state paused")
	t.eq(int(d["tick"]), 100, "tick tiep tuc khi paused")
	t.eq(int(d["sim_tick"]), 60, "sim_tick dung yen")
	t.eq(int(d["night"]), 2, "night")
	t.eq(d["wind"]["active"], true, "wind active")
	t.near(d["wind"]["dir_deg"], 123.457, "wind dir lam tron")
	t.ok(line.find('"vel":[1.0,0.0,2.0]') >= 0, "vel, -0 chuan hoa")
	t.eq(d["player"]["grounded"], false, "grounded")
	t.near(d["player"]["invuln"], 1.5, "invuln 90 tick = 1.5 s")
	t.near(d["player"]["dash_cd_s"], 0.5, "dash_cd_s")
	t.ok(line.find('"pulse_cd_s":0.017') >= 0, "pulse_cd_s 3 chu so")
	t.near(d["player"]["charm_s"], 10.0, "charm_s")
	t.eq(d["motes"][0]["kind"], "dropped", "mote kind")
	t.near(d["motes"][0]["ttl_s"], 2.0, "mote ttl_s")
	t.eq(d["drifters"][0]["state"], "flee", "drifter state")
	t.eq(int(d["drifters"][0]["stolen"]), 3, "drifter stolen")
	t.eq(d["charms"][0]["available"], false, "charm available")
	t.near(d["charms"][0]["respawn_s"], 1.5, "charm respawn_s")
	var keys: Array = []
	for k in ["type", "tick", "sim_tick", "state", "time_left_s", "score", "night", "wind", "player", "lanterns", "shades", "motes_active", "motes", "drifters", "charms"]:
		keys.append(line.find('"%s":' % k))
	var sorted_keys := keys.duplicate()
	sorted_keys.sort()
	t.eq(keys, sorted_keys, "thu tu key goc co dinh")
	s.status = "lost"
	t.eq(JSON.parse_string(Codec.snapshot_line(s))["state"], "lost", "lost thang paused")
	t.eq(Codec.event_line(5, {"name": "dash", "data": {}}), '{"type":"event","tick":5,"name":"dash","data":{}}', "event dash")
	t.eq(Codec.event_line(5, {"name": "night_start", "data": {"night": 3}}), '{"type":"event","tick":5,"name":"night_start","data":{"night":3}}', "event night_start")
	t.eq(Codec.event_line(7, {"name": "player_hit", "data": {"by": "fall", "flames": 2, "dropped": 0, "lost": 4}}),
		'{"type":"event","tick":7,"name":"player_hit","data":{"by":"fall","flames":2,"dropped":0,"lost":4}}', "player_hit fall lost")
	# scenario v1.1
	var st := _state()
	var sc := {
		"player": {"invuln_ticks": 10, "dash_cd_ticks": 20, "pulse_cd_ticks": 30, "charm_ticks": 40},
		"shades": [{"pos": [1, 0, 1], "state": "stunned", "state_ticks_left": 50}],
		"drifters": [{"pos": [2, 0, 2], "state": "chase", "stolen": 2}, {"id": "D5", "pos": [3, 0, 3]}],
		"charms": [{"pos": [4, 0, 4], "available": false, "respawn_ticks": 70}],
		"random_drifters": false, "wind_enabled": false, "random_shades": false}
	var r := Loader.apply(st, sc)
	t.ok(r["ok"], "scenario v1.1 hop le: " + str(r["error"]))
	t.eq(st.player["invuln_ticks"], 10, "invuln_ticks")
	t.eq(st.player["dash_cd_ticks"], 20, "dash_cd_ticks")
	t.eq(st.player["pulse_cd_ticks"], 30, "pulse_cd_ticks")
	t.eq(st.player["charm_ticks"], 40, "charm_ticks")
	t.eq(st.shades[0]["state"], "stunned", "shade state")
	t.eq(st.shades[0]["state_ticks_left"], 50, "state_ticks_left")
	t.eq(st.drifters.size(), 2, "drifters thay the")
	t.eq(st.drifters[0]["id"], "D1", "drifter id auto")
	t.eq(st.drifters[0]["stolen"], 2, "stolen")
	t.eq(st.drifters[1]["id"], "D5", "drifter id tuong minh")
	t.eq(st.drifters[1]["state"], "idle", "drifter state mac dinh")
	t.eq(st.charms[0]["id"], "C1", "charm id")
	t.eq(st.charms[0]["available"], false, "charm available")
	t.eq(st.charms[0]["respawn_ticks"], 70, "charm respawn_ticks")
	t.eq(st.random_drifters, false, "random_drifters")
	t.eq(st.wind_enabled, false, "wind_enabled")
	t.eq(st.score, 0, "scenario v1.1 khong cong diem")
	t.eq(st.tick, 0, "scenario v1.1 khong tang tick")
	var bad := [
		{"player": {"invuln_ticks": -1}}, {"player": {"dash_cd_ticks": "a"}}, {"player": {"pulse_cd_ticks": 1.5}},
		{"player": {"charm_ticks": -3}}, {"shades": [{"pos": [0, 0, 0], "state": "flying"}]},
		{"shades": [{"pos": [0, 0, 0], "state_ticks_left": -1}]}, {"drifters": "x"}, {"drifters": [{"id": "D1"}]},
		{"drifters": [{"pos": [0, 0, 0], "state": "bogus"}]}, {"drifters": [{"pos": [0, 0, 0], "stolen": -1}]},
		{"charms": [{"pos": [0, 0]}]}, {"charms": [{"pos": [0, 0, 0], "available": 1}]},
		{"charms": [{"pos": [0, 0, 0], "respawn_ticks": -1}]}, {"random_drifters": 1}, {"wind_enabled": "x"}]
	for b in bad:
		var s2 := _state()
		var rb := Loader.apply(s2, b)
		t.ok(not rb["ok"] and rb["error"] != "", "scenario v1.1 sai: " + str(b))
		t.eq(s2.drifters.size(), 0, "state khong bi sua khi loi (v1.1)")
	for sn in ["spawning", "wander", "chase", "recoil", "stunned"]:
		t.ok(Loader.apply(_state(), {"shades": [{"pos": [0, 0, 0], "state": sn}]})["ok"], "shade state " + sn)
	for n in [1, 2, 3]:
		t.ok(Runner.parse_args(PackedStringArray(["--seed", "1", "--ticks", "1", "--out", "o", "--night", str(n)]))["ok"], "night %d" % n)
	for n in ["0", "4", "-1", "x"]:
		t.ok(not Runner.parse_args(PackedStringArray(["--seed", "1", "--ticks", "1", "--out", "o", "--night", n]))["ok"], "night sai " + n)
	t.eq(Runner.parse_args(PackedStringArray(["--seed", "1", "--ticks", "1", "--out", "o"]))["opts"]["night"], 1, "night mac dinh 1")
	var fd := Runner.default_frame()
	t.ok(fd.has("dash") and fd.has("pause"), "default frame co dash, pause")
