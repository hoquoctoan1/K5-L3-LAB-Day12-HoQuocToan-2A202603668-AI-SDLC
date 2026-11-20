extends RefCounted

const MB = preload("res://src/core/maps/map_builder.gd")
const MG = preload("res://src/core/maps/map_geometry.gd")

func _has(arr: Array, v: Vector3) -> bool:
	for p in arr:
		if (p as Vector3).distance_to(v) < 0.001:
			return true
	return false

func run(t: TS) -> void:
	var m1 := MB.build(1)
	var m2 := MB.build(2)
	var m3 := MB.build(3)
	t.eq(m1["mote_points"].size(), 24, "n1 mote")
	t.eq(m2["mote_points"].size(), 24, "n2 mote")
	t.eq(m3["mote_points"].size(), 30, "n3 mote")
	t.eq(m1["shade_spawn_points"].size(), 12, "n1 shade")
	t.eq(m2["shade_spawn_points"].size(), 16, "n2 shade")
	t.eq(m3["shade_spawn_points"].size(), 16, "n3 shade")
	t.eq(m1["lanterns"].size(), 5, "n1 lanterns")
	t.eq(m2["lanterns"].size(), 6, "n2 lanterns")
	t.eq(m3["lanterns"].size(), 7, "n3 lanterns")
	t.eq(m1["lanterns"][1]["pos"], Vector3(23.8, 0, 7.7), "n1 L2")
	t.eq(m3["lanterns"][0]["pos"], Vector3(0, 6, 6), "n3 L1")
	t.eq(m3["lanterns"][6]["id"], "L7", "L7 id")
	t.eq(m1["start"]["facing"], Vector3(0, 0, 1), "facing")
	t.eq(MG.facing_start(m2), Vector3(0, 0, 1), "facing_start")
	t.ok(_has(m1["mote_points"], Vector3(12, 0, 0)) and _has(m1["mote_points"], Vector3(0, 0, 33)), "n1 mote ring pts")
	t.ok(_has(m1["shade_spawn_points"], MB.polar(Vector3.ZERO, 37, 15, 0)), "n1 shade 15deg")
	for l in m1["lanterns"]:
		t.near(Vector2(l["pos"].x, l["pos"].z).length(), 25.0, "L r25", 0.1)
	t.ok(_has(m2["mote_points"], Vector3(70, 0, 22)) and _has(m2["mote_points"], Vector3(60, 0, 0)), "n2 B motes")
	t.ok(_has(m2["shade_spawn_points"], MB.polar(Vector3(70, 0, 0), 26, 22.5, 0)), "n2 B shade")
	t.eq(m2["charm_positions"], [Vector3(35, 0, 0)], "n2 charm")
	t.eq(m3["charm_positions"].size(), 2, "n3 charms")
	var on_t1 := 0
	var on_t2 := 0
	for p in m3["mote_points"]:
		if is_equal_approx(p.y, 3.0):
			on_t1 += 1
			t.near(MG.ground_height(m3, p.x, p.z, p.y), 3.0, "t1 mote ground")
		elif is_equal_approx(p.y, 6.0):
			on_t2 += 1
			t.near(MG.ground_height(m3, p.x, p.z, p.y), 6.0, "t2 mote ground")
	t.eq(on_t1, 8, "t1 motes")
	t.eq(on_t2, 4, "t2 motes")
	t.near(MG.ground_height(m1, 39.9, 0, 0), 0.0, "n1 inside")
	t.ok(is_nan(MG.ground_height(m1, 40.5, 0, 0)), "n1 void")
	t.ok(MG.inside_island(m1, Vector3(10, 0, 10)) and not MG.inside_island(m1, Vector3(50, 0, 0)), "inside_island")
	t.near(MG.ground_height(m2, 35, 0, 0), 0.0, "bridge mid")
	t.near(MG.ground_height(m2, 35, 1.9, 0), 0.0, "bridge edge in")
	t.ok(is_nan(MG.ground_height(m2, 35, 2.1, 0)), "bridge side = void")
	t.ok(is_nan(MG.ground_height(m2, 35, -3, 0)), "bridge side - void")
	t.ok(is_nan(MG.ground_height(m2, 35, 10, 0)), "gap void")
	t.eq(MG.closest_island_index(m2, Vector3(60, 0, 0)), 1, "closest B")
	t.eq(MG.jump_pad_at(m2, Vector3(20.5, 0, 18)), 0, "pad0")
	t.eq(MG.jump_pad_at(m2, Vector3(50, 0, -18)), 1, "pad1")
	t.eq(MG.jump_pad_at(m2, Vector3(0, 0, 0)), -1, "no pad")
	t.eq(MG.jump_pad_at(m2, Vector3(20, 5, 18)), -1, "pad needs feet near")
	t.ok(m2["jump_pads"][0]["direction"].x > 0, "pad toward B")
	t.ok(m2["bridge"]["railing"] == false, "no railing")
	t.near(MG.ground_height(m3, 40, 0, 0), 0.0, "n3 t0")
	t.near(MG.ground_height(m3, 0, 18, 3), 3.0, "t1 on")
	t.near(MG.ground_height(m3, 0, 18, 10), 3.0, "t1 on from above")
	t.near(MG.ground_height(m3, 0, -18, 3), 0.0, "z<0 no t1 -> t0")
	t.near(MG.ground_height(m3, 0, 25, 3), 0.0, "off t1 outer edge -> t0")
	t.near(MG.ground_height(m3, 0, 10.5, 3), 0.0, "t1 inner edge -> t0")
	t.near(MG.ground_height(m3, 0, 5, 6), 6.0, "t2")
	t.near(MG.ground_height(m3, 0, 9, 6), 0.0, "off t2 -> t0")
	t.near(MG.ground_height(m3, 0, 20, 0), 0.0, "cannot climb t1 wall from t0")
	var d := Vector2(cos(deg_to_rad(30)), sin(deg_to_rad(30)))
	t.near(MG.ground_height(m3, d.x * 27, d.y * 27, 1.5), 1.5, "ramp mid")
	t.near(MG.ground_height(m3, d.x * 30, d.y * 30, 0), 0.0, "ramp foot")
	t.near(MG.ground_height(m3, d.x * 24, d.y * 24, 3), 3.0, "ramp top")
	t.near(MG.ground_height(m3, d.x * 27 - d.y * 2.0, d.y * 27 + d.x * 2.0, 1.5), 0.0, "off ramp side -> t0")
	t.eq(m3["ramps"].size(), 2, "2 ramps")
	t.eq(MG.jump_pad_at(m3, Vector3(0, 3, 13)), 0, "n3 pad")
	t.eq(m3["jump_pads"][0]["direction"], Vector3(0, 0, -1), "n3 pad dir")
	t.ok(MG.blocked_by_obstacle(m3, Vector3(-4, 6, 0), Vector3(4, 6, 0)), "tower blocks")
	t.ok(not MG.blocked_by_obstacle(m3, Vector3(-4, 6, 3), Vector3(4, 6, 3)), "tower miss")
	t.ok(not MG.blocked_by_obstacle(m3, Vector3(-4, 15, 0), Vector3(4, 15, 0)), "over tower")
	t.ok(not MG.blocked_by_obstacle(m1, Vector3(-4, 0, 0), Vector3(4, 0, 0)), "n1 none")
	t.ok(not MG.is_walkable(m3, Vector3(0, 6, 1)), "tower not walkable")
	t.ok(MG.is_walkable(m3, Vector3(0, 6, 5)), "t2 walkable")
	t.ok(not MG.is_walkable(m1, Vector3(60, 0, 0)), "void not walkable")
	t.eq(MG.free_mote_points(m1, []).size(), 24, "all free")
	t.eq(MG.free_mote_points(m1, [{"pos": m1["mote_points"][3]}, m1["mote_points"][0]]).size(), 22, "2 taken")
	t.ok(MB.build(3) == MB.build(3), "deterministic")
