extends SceneTree
## GODOT --headless --path godot --script res://src/adapters/headless/headless_runner.gd -- <args>
## Args: --seed N --ticks N --out FILE [--night 1] [--scenario F] [--inputs F] [--snapshot-every N=10]
## Exit: 0 ok; 1 tham so/loi chung; 2 file scenario/inputs hong.
##
## Giao dien Sim (viet boi agent khac, runner chi dua vao day):
##   res://src/core/sim.gd : `Sim.new(seed:int)`; `.state: SimState`;
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
	return {"move": Vector2.ZERO, "cam_yaw_deg": 0.0, "jump": false, "interact": false, "pulse": false}

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

func _fail(code: int, msg: String) -> void:
	printerr(msg)
	quit(code)

func _init() -> void:
	var pr := parse_args(OS.get_cmdline_user_args())
	if not pr["ok"]:
		_fail(1, "loi: " + pr["error"])
		return
	var o: Dictionary = pr["opts"]
	var sim
	if ResourceLoader.exists("res://src/core/sim.gd"):
		sim = load("res://src/core/sim.gd").new(o["seed"])
	else:
		sim = StubSim.new(o["seed"])
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
