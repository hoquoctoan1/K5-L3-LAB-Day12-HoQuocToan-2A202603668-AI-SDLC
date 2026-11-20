extends RefCounted
## E2E trong process: Sim that + InputDecoder that + Runner.simulate.

const SimC = preload("res://src/core/sim.gd")
const Dec = preload("res://src/core/input_decoder.gd")
const Runner = preload("res://src/adapters/headless/headless_runner.gd")
const Loader = preload("res://src/adapters/headless/scenario_loader.gd")

func _run(seed: int, scen: Dictionary, inputs: Dictionary, ticks: int, every: int) -> Array:
	var sim = SimC.new(seed)
	if not scen.is_empty():
		Loader.apply(sim.state, scen)
	var dec = null
	if not inputs.is_empty():
		dec = Dec.new()
		dec.load_data(inputs)
	return Runner.simulate(sim, dec, ticks, every)

func run(t: TS) -> void:
	var inputs := {"frames": [{"tick": 0, "move": [0, 1]}, {"tick": 30, "interact": true}, {"tick": 31, "interact": false}, {"tick": 60, "pulse": true}]}
	var l1 := _run(3, {}, inputs, 600, 10)
	var l2 := _run(3, {}, inputs, 600, 10)
	t.eq("\n".join(PackedStringArray(l1)), "\n".join(PackedStringArray(l2)), "2 lan chay giong het")
	t.ok((l1[l1.size() - 1] as String).begins_with('{"type":"end"'), "end cuoi cung")
	t.ok((l1[0] as String).contains('"tick":0'), "snapshot tick 0")
	var l3 := _run(4, {}, inputs, 600, 10)
	t.ok("\n".join(PackedStringArray(l1)) != "\n".join(PackedStringArray(l3)), "seed khac => khac")

	# hand scenario
	var sc := {"player": {"pos": [0, 0, 0], "carried": GameConfig.LANTERN_COST}, "random_motes": false, "random_shades": false,
		"lanterns": [{"id": "L1", "pos": [0, 0, 1], "deposited": 0}]}
	var h := _run(1, sc, {"frames": [{"tick": 0, "interact": true}]}, 3, 1)
	var txt := "\n".join(PackedStringArray(h))
	t.ok(txt.contains('{"type":"event","tick":1,"name":"deposit","data":{"lantern_id":"L1","amount":%d,"deposited":%d}}' % [GameConfig.LANTERN_COST, GameConfig.LANTERN_COST]), "deposit tick1")
	t.ok(txt.contains('"tick":1,"name":"lantern_lit"'), "lit tick1")

	# dawn: time_left_s 1 -> end ticks 60 lost, event tick 60
	var dw := _run(1, {"random_motes": false, "random_shades": false, "time_left_s": 1}, {}, 600, 10)
	var end: String = dw[dw.size() - 1]
	t.eq(end, '{"type":"end","ticks":60,"state":"lost","score":0}', "end dawn")
	t.ok("\n".join(PackedStringArray(dw)).contains('"tick":60,"name":"game_over","data":{"result":"lost","reason":"dawn"}'), "game_over dawn tick 60")
	# --ticks 0
	var z := _run(1, {}, {}, 0, 10)
	t.eq(z.size(), 2, "ticks 0 => snapshot + end")
