extends RefCounted

const Shade = preload("res://src/core/systems/shade_system.gd")
const Spawn = preload("res://src/core/systems/spawn_system.gd")
const MapBuilder = preload("res://src/core/maps/map_builder.gd")

var _drops: Array = []

func _stub(_state, center, count, ttl) -> void:
	_drops.append({"center": center, "count": count, "ttl": ttl})

func _mk(night: int = 1) -> SimState:
	var s := SimState.new()
	s.night = night
	s.map = MapBuilder.build(night)
	s.random_motes = false
	s.random_shades = false
	s.seed_streams(7)
	s.player = SimState.make_default_player()
	return s

func _sh(id: String, pos: Vector3, st: String = "chase") -> Dictionary:
	return SimState.make_shade(id, pos, st)

func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func run(t: TS) -> void:
	var sp := GameConfig.shade_speed(1) * GameConfig.DT
	# chase
	var s := _mk()
	s.shades.append(_sh("S1", Vector3(10, 0, 0)))
	Shade.step(s, {}, [])
	t.near(s.shades[0]["pos"].x, 10.0 - sp, "chase giam x")
	# detect / lose interest
	s = _mk()
	s.shades.append(_sh("S1", Vector3(12.0, 0, 0), "wander"))
	s.shades.append(_sh("S2", Vector3(12.5, 0, 0), "wander"))
	s.shades.append(_sh("S3", Vector3(18.0, 0, 0), "chase"))
	s.shades.append(_sh("S4", Vector3(18.5, 0, 0), "chase"))
	Shade.step(s, {}, [])
	t.eq(s.shades[0]["state"], "chase", "detect 12 -> chase")
	t.eq(s.shades[1]["state"], "wander", "12.5 van wander")
	t.eq(s.shades[2]["state"], "chase", "18 van chase")
	t.eq(s.shades[3]["state"], "wander", "18.5 -> wander")
	# wander: di <= nua toc do, tat dinh, o trong dao
	var a := _mk()
	var b := _mk()
	a.shades.append(_sh("S1", Vector3(25, 0, 25), "wander"))
	b.shades.append(_sh("S1", Vector3(25, 0, 25), "wander"))
	a.player["pos"] = Vector3(-30, 0, -30)
	b.player["pos"] = Vector3(-30, 0, -30)
	var moved := 0.0
	for i in range(2000):
		var before: Vector3 = a.shades[0]["pos"]
		Shade.step(a, {}, [])
		Shade.step(b, {}, [])
		moved = maxf(moved, _xz(a.shades[0]["pos"]).distance_to(_xz(before)))
		t.ok(_xz(a.shades[0]["pos"]).length() <= 40.0 + 0.0001, "wander trong dao")
	t.ok(moved <= sp + 0.0001, "wander khong nhanh hon shade_speed")
	t.eq(a.shades[0]["pos"], b.shades[0]["pos"], "wander tat dinh theo seed")
	# spawning: khong di chuyen / khong cham, sau SPAWNING_TICKS -> wander
	s = _mk()
	s.shades.append(_sh("S1", Vector3(0.5, 0, 0), "spawning"))
	s.shades[0]["state_ticks_left"] = Shade.SPAWNING_TICKS
	var ev := []
	for i in range(Shade.SPAWNING_TICKS - 1):
		Shade.step(s, {}, ev)
	t.eq(s.shades[0]["state"], "spawning", "van spawning")
	t.eq(ev.size(), 0, "spawning khong cham")
	Shade.step(s, {}, ev)
	t.ok(s.shades[0]["state"] != "spawning", "het spawning")
	# cham: bien XZ 1.0 va dy 1.5
	s = _mk()
	s.shades.append(_sh("S1", Vector3(1.0 + sp + 0.01, 0, 0)))
	ev = []
	Shade.step(s, {}, ev)
	t.eq(ev.size(), 0, "XZ 1.01 khong cham")
	s = _mk()
	s.shades.append(_sh("S1", Vector3(1.0 + sp - 0.01, 0, 0)))
	Shade.step(s, {}, ev)
	t.eq(ev.size(), 1, "XZ 0.99 cham")
	s = _mk()
	s.player["pos"] = Vector3(0, 1.5, 0)
	s.shades.append(_sh("S1", Vector3(0.5, 0, 0)))
	ev = []
	Shade.step(s, {}, ev)
	t.eq(ev.size(), 1, "dy 1.5 cham")
	s = _mk()
	s.player["pos"] = Vector3(0, 1.6, 0)
	s.shades.append(_sh("S1", Vector3(0.5, 0, 0)))
	ev = []
	Shade.step(s, {}, ev)
	t.eq(ev.size(), 0, "dy 1.6 khong cham")
	# hit: flames, drop floor(carried/2), invuln, recoil, event, 1 flame/tick
	Shade.drop_fn = Callable(self, "_stub")
	_drops.clear()
	s = _mk()
	s.player["carried"] = 5
	s.player["pos"] = Vector3(1, 0, 1)
	s.shades.append(_sh("S1", Vector3(1.5, 0, 1)))
	s.shades.append(_sh("S2", Vector3(0.5, 0, 1)))
	ev = []
	Shade.step(s, {}, ev)
	t.eq(s.player["flames"], GameConfig.FLAMES - 1, "mat 1 flame")
	t.eq(s.player["carried"], 3, "floor(5/2)=2 roi")
	t.eq(s.player["invuln_ticks"], 90, "invuln 90")
	t.eq(ev.size(), 1, "1 flame moi tick")
	t.eq(ev[0]["name"], "player_hit", "event")
	t.eq(ev[0]["data"], {"by": "shade", "flames": GameConfig.FLAMES - 1, "dropped": 2}, "du lieu event")
	t.eq(_drops.size(), 1, "goi drop_motes 1 lan")
	t.eq(_drops[0]["count"], 2, "drop count")
	t.eq(_drops[0]["ttl"], 480, "drop ttl 480")
	t.eq(s.shades[0]["state"], "recoil", "S1 (id nho) cham truoc -> recoil")
	t.eq(s.shades[1]["state"], "chase", "S2 khong cham")
	# invuln: khong cham them
	for i in range(30):
		Shade.step(s, {}, ev)
	t.eq(s.player["flames"], GameConfig.FLAMES - 1, "invuln: khong mat them")
	# recoil 2 m / 60 tick
	s = _mk()
	s.shades.append(_sh("S1", Vector3(0.5, 0, 0)))
	Shade.step(s, {}, [])
	var p0: Vector3 = s.shades[0]["pos"]
	for i in range(59):
		Shade.step(s, {}, [])
	t.eq(s.shades[0]["state"], "recoil", "recoil dang dien ra")
	Shade.step(s, {}, [])
	t.near(_xz(s.shades[0]["pos"]).distance_to(_xz(p0)), 2.0, "recoil 2 m")
	t.ok(s.shades[0]["state"] != "recoil", "het recoil sau 60 tick")
	# khong drop khi carried = 1
	_drops.clear()
	s = _mk()
	s.player["carried"] = 1
	s.shades.append(_sh("S1", Vector3(0.5, 0, 0)))
	Shade.step(s, {}, [])
	t.eq(_drops.size(), 0, "carried 1 -> khong drop")
	t.eq(s.player["carried"], 1, "carried giu nguyen")
	Shade.drop_fn = Callable()
	# stunned / fall_wait / paused / status: khong cham
	for mode in ["stunned", "fall", "paused", "won"]:
		s = _mk()
		s.shades.append(_sh("S1", Vector3(0.5, 0, 0), "stunned" if mode == "stunned" else "chase"))
		s.shades[0]["state_ticks_left"] = 100
		if mode == "fall":
			s.player["fall_wait_ticks"] = 10
		elif mode == "paused":
			s.paused = true
		elif mode == "won":
			s.status = "won"
		ev = []
		Shade.step(s, {}, ev)
		t.eq(ev.size(), 0, "khong cham: " + mode)
		if mode != "fall":
			t.near(s.shades[0]["pos"].x, 0.5, "dung yen: " + mode)
	# vung an toan: khong bao gio vao
	s = _mk()
	s.lanterns.append({"id": "L1", "pos": Vector3(10, 0, 0), "lit": true, "deposited": 10, "safe_timer": 0, "fuel_units": GameConfig.FUEL_MAX_UNITS, "ever_lit": true, "relit_count": 0})
	s.lanterns.append({"id": "L2", "pos": Vector3(-10, 0, 0), "lit": false, "deposited": 0, "safe_timer": 0, "fuel_units": 0, "ever_lit": false, "relit_count": 0})
	s.player["pos"] = Vector3(10, 0, 0)
	s.shades.append(_sh("S1", Vector3(30, 0, 0)))
	var bad := 0
	for i in range(1200):
		Shade.step(s, {}, [])
		if _xz(s.shades[0]["pos"]).distance_to(Vector2(10, 0)) < GameConfig.SAFE_RADIUS - 0.0001:
			bad += 1
	t.eq(bad, 0, "khong vao vung an toan")
	# ben trong khi den sang: bi day ra <= 30 tick, khong sat thuong
	s = _mk()
	s.lanterns.append({"id": "L1", "pos": Vector3(10, 0, 0), "lit": true, "deposited": 10, "safe_timer": 0, "fuel_units": GameConfig.FUEL_MAX_UNITS, "ever_lit": true, "relit_count": 0})
	s.player["pos"] = Vector3(11, 0, 0)
	s.shades.append(_sh("S1", Vector3(11.5, 0, 0)))
	ev = []
	for i in range(GameConfig.SAFE_PUSH_MAX_TICKS):
		Shade.step(s, {}, ev)
	t.eq(ev.size(), 0, "bi day: khong sat thuong")
	t.ok(_xz(s.shades[0]["pos"]).distance_to(Vector2(10, 0)) >= GameConfig.SAFE_RADIUS - 0.0001, "ra khoi vung <= 30 tick")
	# thu tu id tang dan
	t.eq(Shade.order([{"id": "S10"}, {"id": "S2"}, {"id": "S1"}]), [2, 1, 0], "order theo so")

	# ---- spawn shade ----
	s = _mk()
	s.random_shades = true
	for i in range(299):
		Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 0, "chua sinh truoc 300")
	ev = []
	Spawn.step(s, {}, ev)
	t.eq(s.shades.size(), 2, "2 con tai 300")
	t.eq([ev[0]["data"]["id"], ev[1]["data"]["id"]], ["S1", "S2"], "id S1,S2")
	t.eq(ev[0]["name"], "shade_spawned", "event")
	t.eq(s.shades[0]["state"], "spawning", "spawning")
	for i in range(479):
		Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 2, "chua den interval 480")
	Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 3, "+1 sau 480")
	t.eq(s.shades[2]["id"], "S3", "id S3")
	# khoang cach >= 15 m tu nguoi choi, moi diem la diem sinh cua ban do
	s = _mk()
	s.random_shades = true
	s.player["pos"] = Vector3(37.0 * cos(deg_to_rad(15)), 0, 37.0 * sin(deg_to_rad(15)))
	for i in range(4000):
		Spawn.step(s, {}, [])
	t.ok(s.shades.size() > 0, "co sinh")
	var far_ok := true
	for sh in s.shades:
		if _xz(sh["pos"]).distance_to(_xz(s.player["pos"])) < 15.0 - 0.0001:
			far_ok = false
	t.ok(far_ok, ">= 15 m tu May")
	# max alive theo Dem
	for night in [1, 2, 3]:
		s = _mk(night)
		s.random_shades = true
		s.player["pos"] = Vector3(0, 0, 0)
		for i in range(8000):
			Spawn.step(s, {}, [])
		t.eq(s.shades.size(), GameConfig.max_shades(night), "max_alive Dem %d" % night)
	# khong diem hop le -> bo luot, dat lai bo dem
	s = _mk()
	s.random_shades = true
	s.map["shade_spawn_points"] = [Vector3(0, 0, 0)]
	ev = []
	for i in range(300):
		Spawn.step(s, {}, ev)
	t.eq(s.shades.size(), 0, "khong diem -> bo luot")
	t.eq(ev.size(), 0, "khong event")
	t.eq(s.shade_spawn_ticks_left, 480, "dat lai interval")
	# khong diem trong vung an toan
	s = _mk()
	s.random_shades = true
	s.map["shade_spawn_points"] = [Vector3(37, 0, 0)]
	s.lanterns.append({"id": "L1", "pos": Vector3(35, 0, 0), "lit": true, "deposited": 10, "safe_timer": 0, "fuel_units": GameConfig.FUEL_MAX_UNITS, "ever_lit": true, "relit_count": 0})
	s.player["pos"] = Vector3(-30, 0, 0)
	for i in range(300):
		Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 0, "diem trong vung an toan bi loai")
	# Dem 2: luan phien dao, khoang interval 420
	s = _mk(2)
	s.random_shades = true
	s.player["pos"] = Vector3(0, 0, 0)
	for i in range(300):
		Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 2, "Dem 2: 2 con tai 300")
	t.ok(s.shades[0]["pos"].x < 35.0 and s.shades[1]["pos"].x > 35.0, "Dem 2: moi dao 1 con")
	for i in range(419):
		Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 2, "Dem 2: chua den 420")
	Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 3, "Dem 2: +1 sau 420")
	# flag false
	s = _mk()
	for i in range(1300):
		Spawn.step(s, {}, [])
	t.eq(s.shades.size() + s.motes.size(), 0, "flag false -> khong sinh")
	# paused / thuc the moi chi tuong tac tu tick sau: spawn sau Shade.step => khong cham
	s = _mk()
	s.random_shades = true
	s.shade_spawn_ticks_left = 1
	s.map["shade_spawn_points"] = [Vector3(0.5, 0, 0)]
	s.player["pos"] = Vector3(0.5, 0, 0)
	s.map["shade_spawn_points"] = [Vector3(16, 0, 0)]
	Spawn.step(s, {}, [])
	t.eq(s.shades.size(), 2, "sinh khi dem ve 0 (2 con dau)")
	s.paused = true
	var before_left: int = s.shade_spawn_ticks_left
	Spawn.step(s, {}, [])
	t.eq(s.shade_spawn_ticks_left, before_left, "paused: bo dem dung yen")
	# tat dinh
	var d1 := _mk()
	var d2 := _mk()
	d1.random_shades = true
	d2.random_shades = true
	for i in range(3000):
		Spawn.step(d1, {}, [])
		Spawn.step(d2, {}, [])
	var same := d1.shades.size() == d2.shades.size()
	for i in mini(d1.shades.size(), d2.shades.size()):
		same = same and d1.shades[i]["pos"] == d2.shades[i]["pos"]
	t.ok(same, "sinh shade tat dinh")

	# ---- mote ----
	s = SimState.new()
	s.seed_streams(5)
	Spawn.populate_initial(s)
	t.eq(s.motes.size(), 20, "20 mote ban dau")
	var seen := {}
	for m in s.motes:
		seen[m["point_index"]] = true
		t.eq(m["kind"], "random", "kind random")
	t.eq(seen.size(), 20, "20 diem rieng biet")
	t.eq(s.lanterns.size(), 5, "5 den tu map")
	t.near(s.lanterns[0]["pos"].z, 25.0, "L1 z=25")
	t.eq(s.motes[0]["id"], "m1", "id m1")
	t.eq(s.next_mote_id, 21, "next_mote_id")
	var s2 := SimState.new()
	s2.seed_streams(5)
	Spawn.populate_initial(s2)
	t.eq(s.motes[3]["pos"], s2.motes[3]["pos"], "populate tat dinh")
	var s3 := SimState.new()
	s3.random_motes = false
	s3.random_shades = false
	Spawn.populate_initial(s3)
	t.eq(s3.motes.size() + s3.shades.size(), 0, "populate theo flag")
	t.eq(s3.lanterns.size(), 5, "den van tao khi flag false")
	# hoi sinh 240
	s = _mk()
	s.random_motes = true
	for i in range(239):
		Spawn.step(s, {}, [])
	t.eq(s.motes.size(), 0, "chua hoi sinh truoc 240")
	Spawn.step(s, {}, [])
	t.eq(s.motes.size(), 1, "hoi sinh tai 240")
	t.eq(s.motes[0]["kind"], "random", "kind random")
	t.eq(s.motes[0]["id"], "m1", "id m1")
	for i in range(239):
		Spawn.step(s, {}, [])
	t.eq(s.motes.size(), 1, "chua den 480")
	Spawn.step(s, {}, [])
	t.eq(s.motes.size(), 2, "moi 240")
	# tran 30
	s = _mk(3)
	s.random_motes = true
	for i in range(30):
		s.motes.append(SimState.make_mote("x%d" % i, Vector3(100 + i, 0, 0), "dropped", 480))
	for i in range(500):
		Spawn.step(s, {}, [])
	t.eq(s.motes.size(), 30, "tran 30")
	# het diem trong -> bo luot
	s = _mk()
	s.random_motes = true
	for p in s.map["mote_points"]:
		s.motes.append(SimState.make_mote("x%d" % s.motes.size(), p, "random"))
	for i in range(500):
		Spawn.step(s, {}, [])
	t.eq(s.motes.size(), 24, "het diem trong -> bo luot")
	t.eq(s.mote_respawn_ticks_left, GameConfig.MOTE_RESPAWN_TICKS - 20, "bo dem van chay")
