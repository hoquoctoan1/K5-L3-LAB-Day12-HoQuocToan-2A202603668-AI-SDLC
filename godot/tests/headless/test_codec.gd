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
	var want := '{"type":"snapshot","tick":0,"sim_tick":0,"state":"playing","time_left_s":300.0,"score":0,"player":{"pos":[0.0,0.0,12.0],"flames":3,"carried":0},"lanterns":[{"id":"L1","pos":[0.0,0.0,5.0],"lit":false,"deposited":0},{"id":"L2","pos":[0.0,0.0,10.0],"lit":false,"deposited":0},{"id":"L3","pos":[0.0,0.0,15.0],"lit":false,"deposited":0},{"id":"L4","pos":[0.0,0.0,20.0],"lit":false,"deposited":0},{"id":"L5","pos":[0.0,0.0,25.0],"lit":false,"deposited":0}],"shades":[{"id":"S1","pos":[30.1,1.0,2.0],"state":"chase"}],"motes_active":1,"motes":[{"id":"m1","pos":[1.0,0.0,2.0]}]}'
	t.eq(line, want, "snapshot byte-exact + key order")
	t.ok(JSON.parse_string(line) != null, "snapshot la JSON hop le")
	t.eq(Codec.event_line(131, {"name": "pulse", "data": {"stunned_ids": ["S1"]}}),
		'{"type":"event","tick":131,"name":"pulse","data":{"stunned_ids":["S1"]}}', "event line")
	t.eq(Codec.end_line(4800, "won", 1730), '{"type":"end","ticks":4800,"state":"won","score":1730}', "end line")

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
