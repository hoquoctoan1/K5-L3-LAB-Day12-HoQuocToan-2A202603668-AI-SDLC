extends RefCounted

const ShadeSystem = preload("res://src/core/systems/shade_system.gd")
const SpawnSystem = preload("res://src/core/systems/spawn_system.gd")

func _mk() -> SimState:
	var s := SimState.new()
	s.random_motes = false
	s.random_shades = false
	s.player = SimState.make_default_player()
	return s

func _shade(id: String, pos: Vector3, st: String = "chase", sl: float = 0.0) -> Dictionary:
	return {"id": id, "pos": pos, "state": st, "stun_left": sl}

func run(t: TS) -> void:
	# chase
	var s := _mk()
	s.shades.append(_shade("S1", Vector3(10, 2, 0)))
	var ev := []
	ShadeSystem.step(s, {}, ev)
	t.near(s.shades[0]["pos"].x, 10.0 - GameConfig.SHADE_SPEED * GameConfig.DT, "chase giam x")
	t.near(s.shades[0]["pos"].y, 2.0, "giu y")
	# hit + invuln + drop
	s = _mk()
	s.player["carried"] = 5
	s.shades.append(_shade("S1", Vector3(0.5, 0, 0)))
	ev = []
	ShadeSystem.step(s, {}, ev)
	t.eq(s.player["flames"], GameConfig.FLAMES - 1, "mat 1 flame")
	t.eq(s.player["carried"], 3, "drop floor(5*0.5)=2")
	t.eq(ev.size(), 1, "1 event")
	t.eq(ev[0]["data"]["dropped"], 2, "event dropped")
	t.eq(ev[0]["data"]["by"], "shade", "event by")
	t.near(s.player["invuln_left"], GameConfig.INVULN_S, "invuln")
	for i in range(30):
		ShadeSystem.step(s, {}, ev)
	t.eq(s.player["flames"], GameConfig.FLAMES - 1, "khong hit lien tiep trong invuln")
	# only one hit per tick, to 0 flames
	s = _mk()
	s.shades.append(_shade("S1", Vector3(0.3, 0, 0)))
	s.shades.append(_shade("S2", Vector3(-0.3, 0, 0)))
	ev = []
	ShadeSystem.step(s, {}, ev)
	t.eq(s.player["flames"], GameConfig.FLAMES - 1, "1 hit moi tick")
	for k in range(GameConfig.FLAMES - 1):
		s.player["invuln_left"] = 0.0
		ShadeSystem.step(s, {}, ev)
	t.eq(s.player["flames"], 0, "ve 0 flames")
	t.eq(s.status, "playing", "khong dat status")
	# stunned
	s = _mk()
	s.shades.append(_shade("S1", Vector3(0.5, 0, 0), "stunned", 3.0))
	ev = []
	ShadeSystem.step(s, {}, ev)
	t.eq(ev.size(), 0, "stunned khong hit")
	t.near(s.shades[0]["pos"].x, 0.5, "stunned khong di chuyen")
	var n := int(ceil(3.0 / GameConfig.DT)) + 2
	for i in range(n):
		ShadeSystem.step(s, {}, ev)
		if s.shades[0]["state"] == "chase":
			break
	t.eq(s.shades[0]["state"], "chase", "het stun -> chase")
	t.near(s.shades[0]["stun_left"], 0.0, "stun_left=0")
	# safe radius
	s = _mk()
	s.lanterns.append({"id": "L1", "pos": Vector3(10, 0, 0), "lit": true, "deposited": 5})
	s.lanterns.append({"id": "L2", "pos": Vector3(-10, 0, 0), "lit": false, "deposited": 0})
	s.player["pos"] = Vector3(10, 0, 0)
	s.shades.append(_shade("S1", Vector3(30, 0, 0)))
	var bad := 0
	for i in range(1200):
		ShadeSystem.step(s, {}, ev)
		var q: Vector3 = s.shades[0]["pos"]
		if Vector2(q.x - 10, q.z).length() < GameConfig.SAFE_RADIUS - 0.0001:
			bad += 1
	t.eq(bad, 0, "shade khong vao safe radius")
	# no-op when not playing
	s = _mk()
	s.status = "won"
	s.shades.append(_shade("S1", Vector3(10, 0, 0)))
	ShadeSystem.step(s, {}, [])
	t.near(s.shades[0]["pos"].x, 10.0, "no-op khi het game")
	# spawn deterministic / max / flags
	var a := _mk()
	var b := _mk()
	a.random_shades = true
	b.random_shades = true
	a.rng = Rng.new(7)
	b.rng = Rng.new(7)
	var ea := []
	var eb := []
	for i in range(1300):
		SpawnSystem.step(a, {}, ea)
		SpawnSystem.step(b, {}, eb)
	t.eq(a.shades.size(), 1, "spawn sau 20s")
	t.eq(ea.size(), 1, "event shade_spawned")
	t.eq(ea[0]["name"], "shade_spawned", "ten event")
	t.eq(ea[0]["data"]["id"], "S1", "id S1")
	t.eq(a.next_shade_id, 2, "next_shade_id")
	t.eq(a.shades[0]["state"], "chase", "state chase")
	t.eq(a.shades[0]["pos"], b.shades[0]["pos"], "spawn tat dinh theo seed")
	t.ok(Vector2(a.shades[0]["pos"].x, a.shades[0]["pos"].z).length() >= 15.0, ">=15m tu player")
	var m := _mk()
	m.random_shades = true
	for i in range(GameConfig.MAX_SHADES):
		m.shades.append(_shade("X" + str(i), Vector3(1, 0, 1), "stunned", 99999.0))
	for i in range(1300):
		SpawnSystem.step(m, {}, [])
	t.eq(m.shades.size(), GameConfig.MAX_SHADES, "ton trong MAX_SHADES")
	var f := _mk()
	for i in range(1300):
		SpawnSystem.step(f, {}, [])
	t.eq(f.shades.size(), 0, "flag false -> khong shade")
	t.eq(f.motes.size(), 0, "flag false -> khong mote")
	# mote respawn
	var r := _mk()
	r.random_motes = true
	r.rng = Rng.new(3)
	SpawnSystem.step(r, {}, [])
	t.eq(r.motes.size(), 1, "mote respawn")
	t.eq(r.mote_respawn_ticks_left, GameConfig.MOTE_RESPAWN_TICKS, "reset timer")
	# populate_initial
	var p := SimState.new()
	p.rng = Rng.new(5)
	SpawnSystem.populate_initial(p)
	t.eq(p.motes.size(), GameConfig.INITIAL_MOTES, "initial motes")
	t.eq(p.shades.size(), GameConfig.INITIAL_SHADES, "initial shades")
	t.eq(p.lanterns.size(), 5, "5 lanterns")
	t.near(p.lanterns[0]["pos"].z, GameConfig.LANTERN_RING_RADIUS, "L1 z=25")
	t.near(p.lanterns[0]["pos"].x, 0.0, "L1 x=0")
	t.near(p.lanterns[1]["pos"].length(), GameConfig.LANTERN_RING_RADIUS, "ring radius")
	t.eq(p.next_shade_id, GameConfig.INITIAL_SHADES + 1, "next_shade_id")
	var p2 := SimState.new()
	p2.rng = Rng.new(5)
	SpawnSystem.populate_initial(p2)
	t.eq(p.shades[0]["pos"], p2.shades[0]["pos"], "populate tat dinh")
	var p3 := SimState.new()
	p3.random_motes = false
	p3.random_shades = false
	SpawnSystem.populate_initial(p3)
	t.eq(p3.motes.size() + p3.shades.size(), 0, "populate theo flag")
