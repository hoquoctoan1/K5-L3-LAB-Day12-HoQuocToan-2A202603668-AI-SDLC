extends RefCounted
## E2E trong process: Sim that + InputDecoder that + Runner.simulate (v1.1, 3 Dem).

const SimC = preload("res://src/core/sim.gd")
const Dec = preload("res://src/core/input_decoder.gd")
const Runner = preload("res://src/adapters/headless/headless_runner.gd")
const Loader = preload("res://src/adapters/headless/scenario_loader.gd")

func _run(seed: int, scen: Dictionary, inputs: Dictionary, ticks: int, every: int, night: int = 1) -> Array:
	var sim = SimC.new(seed, night)
	if not scen.is_empty():
		var r: Dictionary = Loader.apply(sim.state, scen)
		if not r["ok"]:
			printerr("scenario loi: ", r["error"])
	var dec = null
	if not inputs.is_empty():
		dec = Dec.new()
		dec.load_data(inputs)
	return Runner.simulate(sim, dec, ticks, every)

static func _parse(lines: Array) -> Array:
	var out: Array = []
	for l in lines:
		out.append(JSON.parse_string(l))
	return out

static func _events(rows: Array, name: String = "") -> Array:
	var out: Array = []
	for r in rows:
		if r["type"] == "event" and (name == "" or r["name"] == name):
			out.append(r)
	return out

static func _snap(rows: Array, tick: int) -> Dictionary:
	for r in rows:
		if r["type"] == "snapshot" and int(r["tick"]) == tick:
			return r
	return {}

static func _txt(lines: Array) -> String:
	return "\n".join(PackedStringArray(lines))

func run(t: TS) -> void:
	_phase1(t)
	_nights(t)
	_pause(t)
	_fall(t)
	_jump_pad(t)
	_night3_full(t)

func _phase1(t: TS) -> void:
	var inputs := {"frames": [{"tick": 0, "move": [0, 1]}, {"tick": 30, "interact": true}, {"tick": 31, "interact": false}, {"tick": 60, "pulse": true}]}
	var l1 := _run(3, {}, inputs, 600, 10)
	var l2 := _run(3, {}, inputs, 600, 10)
	t.eq(_txt(l1), _txt(l2), "2 lan chay giong het")
	t.ok((l1[l1.size() - 1] as String).begins_with('{"type":"end"'), "end cuoi cung")
	t.ok((l1[0] as String).contains('"tick":0'), "snapshot tick 0")
	var l3 := _run(4, {}, inputs, 600, 10)
	t.ok(_txt(l1) != _txt(l3), "seed khac => khac")
	t.ok((l1[1] as String) == '{"type":"event","tick":1,"name":"night_start","data":{"night":1}}', "night_start dong event dau")

	# hand scenario
	var sc := {"player": {"pos": [0, 0, 0], "carried": GameConfig.LANTERN_COST}, "random_motes": false, "random_shades": false,
		"lanterns": [{"id": "L1", "pos": [0, 0, 1], "deposited": 0}]}
	var h := _run(1, sc, {"frames": [{"tick": 0, "interact": true}]}, 3, 1)
	var txt := _txt(h)
	t.ok(txt.contains('{"type":"event","tick":1,"name":"deposit","data":{"lantern_id":"L1","amount":%d,"deposited":%d}}' % [GameConfig.LANTERN_COST, GameConfig.LANTERN_COST]), "deposit tick1")
	t.ok(txt.contains('"tick":1,"name":"lantern_lit"'), "lit tick1")

	# dawn: time_left_s 1 -> end ticks 60 lost, event tick 60
	var dw := _run(1, {"random_motes": false, "random_shades": false, "time_left_s": 1}, {}, 600, 10)
	t.eq(dw[dw.size() - 1], '{"type":"end","ticks":60,"state":"lost","score":0}', "end dawn")
	t.ok(_txt(dw).contains('"tick":60,"name":"game_over","data":{"result":"lost","reason":"dawn"}'), "game_over dawn tick 60")
	# --ticks 0
	var z := _run(1, {}, {}, 0, 10)
	t.eq(z.size(), 2, "ticks 0 => snapshot + end")

## Moi Dem chay vai nghin tick qua runner.
func _nights(t: TS) -> void:
	var inputs := {"frames": [{"tick": 0, "move": [0, 1]}, {"tick": 200, "move": [1, 0]}, {"tick": 400, "move": [0, -1]},
		{"tick": 600, "move": [-1, 0]}, {"tick": 800, "move": [0, 0]}]}
	for n in [1, 2, 3]:
		# khong shade ngau nhien: song het 3000 tick
		var rows := _parse(_run(5, {"random_shades": false}, inputs, 3000, 10, n))
		var end: Dictionary = rows[rows.size() - 1]
		t.eq(end["type"], "end", "end night %d" % n)
		t.eq(int(end["ticks"]), 3000, "3000 tick night %d" % n)
		t.eq(end["state"], "playing", "playing night %d" % n)
		var s0: Dictionary = rows[0]
		t.eq(int(s0["night"]), n, "snapshot night %d" % n)
		t.eq(s0["lanterns"].size(), GameConfig.lantern_count(n), "so den snapshot night %d" % n)
		t.eq(int(s0["motes_active"]), GameConfig.INITIAL_MOTES, "20 mote tick 0 night %d" % n)
		t.near(float(s0["time_left_s"]), GameConfig.night_duration_s(n), "time_left tick 0 night %d" % n)
		var ev0: Array = _events(rows)
		t.ok(not ev0.is_empty() and ev0[0]["name"] == "night_start" and int(ev0[0]["tick"]) == 1, "night_start tick 1 night %d" % n)
		t.eq(_events(rows, "night_start").size(), 1, "1 night_start night %d" % n)
		var s3000 := _snap(rows, 3000)
		t.eq(int(s3000["sim_tick"]), 3000, "sim_tick 3000 night %d" % n)
		t.near(float(s3000["time_left_s"]), GameConfig.night_duration_s(n) - 50.0, "time_left 3000 night %d" % n)
		# mote hoi sinh moi 240 tick (len toi 30 neu khong nhat)
		t.ok(int(s3000["motes_active"]) > GameConfig.INITIAL_MOTES - 10, "mote hoi sinh night %d" % n)
		var s1210 := _snap(rows, 1210)
		if GameConfig.has_drifters(n):
			t.ok(s1210["drifters"].size() >= 1, "drifter sinh tick 1200 night %d" % n)
			t.eq(_snap(rows, 1190)["drifters"].size(), 0, "chua drifter truoc 1200 night %d" % n)
		else:
			t.eq(s1210["drifters"].size(), 0, "khong drifter Dem 1")
		var wind_on := false
		for r in rows:
			if r["type"] == "snapshot" and r["wind"]["active"]:
				wind_on = true
		t.eq(wind_on, GameConfig.has_wind(n), "gio manh chi Dem 3 (night %d)" % n)
		if n == 3:
			t.ok(not _snap(rows, 1790)["wind"]["active"] and _snap(rows, 1800)["wind"]["active"] and not _snap(rows, 2110)["wind"]["active"], "gio tick 1800..2099")
		t.eq(_snap(rows, 2000)["charms"].size(), [0, 0, 1, 2][n], "charm night %d" % n)
		# co shade ngau nhien: 2 con tai tick 300, tat dinh
		var a := _run(6, {}, inputs, 1500, 10, n)
		var b := _run(6, {}, inputs, 1500, 10, n)
		t.eq(_txt(a), _txt(b), "tat dinh voi shade night %d" % n)
		var ra := _parse(a)
		var sp := _events(ra, "shade_spawned")
		t.ok(sp.size() >= 2 and int(sp[0]["tick"]) == 300 and int(sp[1]["tick"]) == 300, "2 shade tick 300 night %d" % n)
		t.eq(sp[0]["data"]["id"], "S1", "S1 night %d" % n)

func _pause(t: TS) -> void:
	var inputs := {"frames": [{"tick": 0, "move": [0, 1]}, {"tick": 10, "pause": true}, {"tick": 11, "pause": false},
		{"tick": 50, "pause": true}, {"tick": 51, "pause": false}]}
	var rows := _parse(_run(1, {"random_shades": false}, inputs, 100, 10))
	var ps := _events(rows, "paused")
	var rs := _events(rows, "resumed")
	t.eq(ps.size(), 1, "1 paused")
	t.eq(rs.size(), 1, "1 resumed")
	t.eq(int(ps[0]["tick"]), 11, "paused tick 11")
	t.eq(int(rs[0]["tick"]), 51, "resumed tick 51")
	t.eq(ps[0]["data"], {}, "paused {}")
	var s20 := _snap(rows, 20)
	t.eq(s20["state"], "paused", "snapshot paused")
	t.eq(int(s20["sim_tick"]), 10, "sim_tick dung o 10")
	t.near(float(s20["time_left_s"]), 240.0 - 10.0 / 60.0, "time dung (v1.2: Dem 1 = 240 s)")
	t.eq(_snap(rows, 40)["player"]["pos"], s20["player"]["pos"], "khong di chuyen khi paused")
	var s100 := _snap(rows, 100)
	t.eq(s100["state"], "playing", "playing lai")
	t.eq(int(s100["sim_tick"]), 100 - 40, "sim_tick = tick - 40 tick paused")
	t.near(float(s100["player"]["pos"][2]), 60.0 * GameConfig.PLAYER_SPEED / 60.0, "di 60 sim tick", 0.01)
	t.eq(int(rows[rows.size() - 1]["ticks"]), 100,"end ticks = so step (ke ca paused)")

## Roi khoi dao (Dem 1): mat 1 lua + toan bo mote, cho 60 tick, hoi sinh o diem xuat phat + bat tu 90 tick.
func _fall(t: TS) -> void:
	var sc := {"player": {"pos": [39, 0, 0], "carried": 4, "flames": 3}, "random_motes": false, "random_shades": false, "motes": [], "shades": []}
	var inputs := {"frames": [{"tick": 0, "move": [1, 0]}, {"tick": 20, "move": [0, 0]}]}
	var rows := _parse(_run(1, sc, inputs, 200, 1))
	var hits := _events(rows, "player_hit")
	t.eq(hits.size(), 1, "1 lan roi")
	if hits.size() != 1:
		return
	var H := int(hits[0]["tick"])
	t.eq(hits[0]["data"], {"by": "fall", "flames": 2.0, "dropped": 0.0, "lost": 4.0}, "player_hit fall data (JSON so => float)")
	t.ok(float(_snap(rows, H)["player"]["pos"][1]) < GameConfig.FALL_Y, "y < -10 luc roi")
	t.ok(float(_snap(rows, H - 1)["player"]["pos"][1]) >= GameConfig.FALL_Y, "chua roi tick truoc")
	t.ok(H > 40 and H < 90, "roi ~1 s sau khi ra khoi mep (H=%d)" % H)
	t.eq(int(_snap(rows, H)["player"]["carried"]), 0, "mat toan bo mote")
	t.ok(float(_snap(rows, H + 59)["player"]["pos"][1]) < GameConfig.FALL_Y, "dang cho hoi sinh tick H+59")
	var sr := _snap(rows, H + GameConfig.FALL_WAIT_TICKS)
	t.eq(sr["player"]["pos"], [0.0, 0.0, 0.0], "hoi sinh o (0,0,0) tick H+60")
	t.near(float(sr["player"]["invuln"]), 1.5, "bat tu 90 tick")
	t.eq(sr["player"]["vel"], [0.0, 0.0, 0.0], "van toc 0")
	t.eq(int(sr["player"]["flames"]), 2, "con 2 lua")
	t.eq(rows[rows.size() - 1]["state"], "playing", "van choi")
	# het lua khi roi: thua ngay (no_flames), khong hoi sinh
	sc["player"]["flames"] = 1
	rows = _parse(_run(1, sc, inputs, 200, 1))
	var ev := _events(rows)
	t.eq(ev.size(), 3, "night_start + player_hit + game_over")
	if ev.size() == 3:
		t.eq(ev[1]["name"], "player_hit", "hit")
		t.eq(ev[1]["data"]["flames"], 0.0, "flames 0")
		t.eq(ev[2]["data"], {"result": "lost", "reason": "no_flames"}, "thua no_flames")
		t.eq(int(ev[2]["tick"]), int(ev[1]["tick"]), "cung tick")
	t.eq(rows[rows.size() - 1]["state"], "lost", "end lost")

## Buc nhay Dem 2: tu (20,0,18) bay sang dao B, khong roi.
func _jump_pad(t: TS) -> void:
	var sc := {"player": {"pos": [20, 0, 18], "carried": 0, "flames": 3}, "random_motes": false, "random_shades": false,
		"random_drifters": false, "motes": [], "shades": [], "drifters": [], "charms": []}
	var rows := _parse(_run(1, sc, {}, 150, 1, 2))
	t.eq(_events(rows, "player_hit").size(), 0, "khong roi")
	var peak := 0.0
	var land := -1
	for r in rows:
		if r["type"] != "snapshot":
			continue
		peak = maxf(peak, float(r["player"]["pos"][1]))
		if land < 0 and int(r["tick"]) > 2 and r["player"]["grounded"]:
			land = int(r["tick"])
	t.ok(peak > 4.0 and peak < 5.5, "dinh ~ 14^2/40 = 4.9 m (got %f)" % peak)
	t.ok(land > 70 and land < 100, "dap sau ~1.4 s (tick %d)" % land)
	t.eq(_snap(rows, 30)["player"]["grounded"], false, "dang bay tick 30")
	var p: Array = _snap(rows, 150)["player"]["pos"]
	var dB := Vector2(float(p[0]) - 70.0, float(p[2])).length()
	t.ok(dB <= 28.0, "dap trong dao B (cach tam %f)" % dB)
	t.near(float(p[1]), 0.0, "tren mat dao")
	t.ok(_snap(rows, 150)["player"]["grounded"], "grounded")
	t.eq(_snap(rows, 150)["player"]["vel"], [0.0, 0.0, 0.0], "dung lai sau khi dap")

## Dem 3 day du 18000 tick (v1.2: 300 s; v1.1 la 21600) (shade toi da 10, gio, drifter): <= 30 s.
func _night3_full(t: TS) -> void:
	var t0 := Time.get_ticks_msec()
	var lines := _run(1, {"player": {"flames": 1000}}, {}, GameConfig.night_duration_ticks(3), 10, 3)
	var ms := Time.get_ticks_msec() - t0
	print("e2e night3 18000 ticks in-process: %d ms" % ms)
	t.eq(lines[lines.size() - 1], '{"type":"end","ticks":18000,"state":"lost","score":0}', "Dem 3 het gio o 18000")
	t.ok(_txt(lines).contains('"tick":18000,"name":"game_over","data":{"result":"lost","reason":"dawn"}'), "dawn tick 18000")
	t.ok(ms <= 30000, "18000 tick <= 30 s (%d ms)" % ms)
