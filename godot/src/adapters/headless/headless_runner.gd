extends SceneTree
## GODOT --headless --path godot --script res://src/adapters/headless/headless_runner.gd -- <args>
## Args: --seed N --ticks N --out FILE [--night 1|2|3] [--scenario F] [--inputs F] [--snapshot-every N=10]
## Exit: 0 ok; 1 tham so/loi chung (ke ca --night ngoai 1..3); 2 file scenario/inputs hong.
## v1.1: snapshot mo rong (contract_codec), scenario v1.1 (scenario_loader), FrameInput v2 (dash,pause).
## Snapshot `tick` va `sim_tick` deu doc tu state (tick tang ca khi paused, sim_tick (=steps) dung yen).
## Event `night_start{night}` do Sim phat o step dau (runner KHONG gia lap).
##
## Giao dien Sim (viet boi agent khac, runner chi dua vao day):
##   res://src/core/sim.gd : `Sim.new(seed:int, night:int = 1)`; neu _init chi co 1 tham so,
##   runner goi `Sim.new(seed)` roi gan `sim.state.night = night` (fallback); `.state: SimState`;
##   `.step(frame:Dictionary) -> Array` cac event {name,data}; Sim tu tang state.tick/steps.
##   Neu thieu sim.gd: dung StubSim (khong gameplay, chi dem tick).
## InputDecoder (res://src/core/input_decoder.gd): instance `.parse(data)->{ok,error}`, `.next(tick)->Dictionary`.
##   Neu thieu: frame mac dinh (dung yen); file inputs chi duoc kiem tra la JSON object co `frames` mang.

const Codec = preload("res://src/adapters/headless/contract_codec.gd")
const Loader = preload("res://src/adapters/headless/scenario_loader.gd")

class StubSim extends RefCounted:
	var state: SimState = SimState.new()
	func _init(seed: int) -> void:
		state.rng = Rng.new(seed)
		state.player = SimState.make_default_player()
	func step(_frame: Dictionary) -> Array:
		if state.status == "playing":
			state.tick += 1
			state.steps += 1
		return []

static func default_frame() -> Dictionary:
	return {"move": Vector2.ZERO, "cam_yaw_deg": 0.0, "jump": false, "interact": false, "pulse": false, "dash": false, "pause": false}

## Tra {ok,error,opts}. opts: seed,night,scenario,inputs,ticks,out,snapshot_every
static func parse_args(args: PackedStringArray) -> Dictionary:
	var opts := {"seed": 0, "night": 1, "scenario": "", "inputs": "", "ticks": 0, "out": "", "snapshot_every": 10}
	var seen := {}
	var i := 0
	while i < args.size():
		var a := args[i]
		var key := ""
		match a:
			"--seed": key = "seed"
			"--night": key = "night"
			"--scenario": key = "scenario"
			"--inputs": key = "inputs"
			"--ticks": key = "ticks"
			"--out": key = "out"
			"--snapshot-every": key = "snapshot_every"
			_:
				return {"ok": false, "error": "tham so khong hop le: " + a, "opts": opts}
		if i + 1 >= args.size():
			return {"ok": false, "error": "thieu gia tri cho " + a, "opts": opts}
		var v := args[i + 1]
		if key in ["seed", "night", "ticks", "snapshot_every"]:
			if not v.is_valid_int():
				return {"ok": false, "error": "%s phai la so nguyen: %s" % [a, v], "opts": opts}
			opts[key] = v.to_int()
		else:
			opts[key] = v
		seen[key] = true
		i += 2
	for r in ["seed", "ticks", "out"]:
		if not seen.has(r):
			return {"ok": false, "error": "thieu tham so bat buoc --" + r, "opts": opts}
	if opts["night"] < 1 or opts["night"] > 3:
		return {"ok": false, "error": "--night phai la 1, 2 hoac 3", "opts": opts}
	if opts["ticks"] < 0:
		return {"ok": false, "error": "--ticks phai >= 0", "opts": opts}
	if opts["snapshot_every"] < 1:
		return {"ok": false, "error": "--snapshot-every phai >= 1", "opts": opts}
	if opts["out"] == "":
		return {"ok": false, "error": "--out rong", "opts": opts}
	return {"ok": true, "error": "", "opts": opts}

## Vong lap thuan: tra Array cac dong JSONL. decoder co the null.
static func simulate(sim, decoder, ticks: int, snapshot_every: int) -> Array:
	var lines: Array = []
	if sim.has_method("begin"):
		sim.begin()
	var st: SimState = sim.state
	lines.append(Codec.snapshot_line(st))
	var k := 0
	while k < ticks and st.status == "playing":
		var frame: Dictionary = default_frame() if decoder == null else decoder.next(k)
		var events: Array = sim.step(frame)
		for ev in events:
			lines.append(Codec.event_line(k + 1, ev))
		k += 1
		if k % snapshot_every == 0:
			lines.append(Codec.snapshot_line(st))
	lines.append(Codec.end_line(k, st.status, st.score))
	return lines

static func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"ok": false, "error": "khong doc duoc file: " + path}
	var js := JSON.new()
	var data = js.data if js.parse(f.get_as_text()) == OK else null
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "JSON khong hop le (can object): " + path}
	return {"ok": true, "data": data}

## Tao Sim; ho tro Sim co hoac khong co tham so night.
static func make_sim(seed: int, night: int):
	if not ResourceLoader.exists("res://src/core/sim.gd"):
		var stub := StubSim.new(seed)
		stub.state.night = night
		return stub
	var script = load("res://src/core/sim.gd")
	if script == null or not script.can_instantiate():
		return null
	var argc := 1
	for m in script.get_script_method_list():
		if m["name"] == "_init":
			argc = m["args"].size()
	var sim
	if argc >= 2:
		sim = script.new(seed, night)
	else:
		sim = script.new(seed)
	if sim == null or not sim.has_method("step") or sim.get("state") == null:
		return null
	if sim.state.night != night:
		sim.state.night = night
		sim.state.time_left_initial = GameConfig.night_duration_s(night)
	return sim

func _fail(code: int, msg: String) -> void:
	printerr(msg)
	quit(code)

func _init() -> void:
	var pr := parse_args(OS.get_cmdline_user_args())
	if not pr["ok"]:
		_fail(1, "loi: " + pr["error"])
		return
	var o: Dictionary = pr["opts"]
	var sim = make_sim(o["seed"], o["night"])
	if sim == null:
		_fail(1, "loi: khong nap duoc res://src/core/sim.gd (loi bien dich)")
		return
	if o["scenario"] != "":
		var r := _read_json(o["scenario"])
		if not r["ok"]:
			_fail(2, "loi scenario: " + r["error"])
			return
		var res := Loader.apply(sim.state, r["data"])
		if not res["ok"]:
			_fail(2, "loi scenario: " + res["error"])
			return
	var decoder = null
	if o["inputs"] != "":
		var r2 := _read_json(o["inputs"])
		if not r2["ok"]:
			_fail(2, "loi inputs: " + r2["error"])
			return
		if ResourceLoader.exists("res://src/core/input_decoder.gd"):
			decoder = load("res://src/core/input_decoder.gd").new()
			var pres: Dictionary = decoder.load_data(r2["data"])
			if not pres["ok"]:
				_fail(2, "loi inputs: " + str(pres["error"]))
				return
		elif typeof(r2["data"].get("frames")) != TYPE_ARRAY:
			_fail(2, "loi inputs: thieu mang frames")
			return
	var lines := simulate(sim, decoder, o["ticks"], o["snapshot_every"])
	var out := FileAccess.open(o["out"], FileAccess.WRITE)
	if out == null:
		_fail(1, "loi: khong ghi duoc --out " + o["out"])
		return
	out.store_string("\n".join(PackedStringArray(lines)) + "\n")
	out.close()
	quit(0)
