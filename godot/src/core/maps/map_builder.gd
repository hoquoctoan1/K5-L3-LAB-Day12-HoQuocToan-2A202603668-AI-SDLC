extends RefCounted
## MapBuilder.build(night) -> MapData (Dictionary). Thuan, tat dinh. Xem MAPS.md.
## Goc: x = cx + r*cos(a), z = cz + r*sin(a) (a tinh bang do tu +X; xem MAPS.md).

const VOID_Y := -10.0

static func polar(center: Vector3, r: float, deg: float, y: float) -> Vector3:
	var a := deg_to_rad(deg)
	return Vector3(snappedf(center.x + r * cos(a), 0.000001), y, snappedf(center.z + r * sin(a), 0.000001))

static func ring(center: Vector3, r: float, count: int, start_deg: float, step_deg: float, y: float) -> Array:
	var out: Array = []
	for i in count:
		out.append(polar(center, r, start_deg + step_deg * i, y))
	return out

static func _lanterns(coords: Array) -> Array:
	var out: Array = []
	for i in coords.size():
		var c: Array = coords[i]
		out.append({"id": "L%d" % (i + 1), "pos": Vector3(c[0], c[1], c[2])})
	return out

static func build(night: int) -> Dictionary:
	var o := Vector3.ZERO
	var m := {
		"night": night, "name": "", "void_y": VOID_Y,
		"islands": [], "tiers": [], "ramps": [], "bridge": {}, "jump_pads": [],
		"bell_tower": {}, "start": {"pos": Vector3.ZERO, "facing": Vector3(0, 0, 1)},
		"lanterns": [], "mote_points": [], "shade_spawn_points": [], "charm_positions": [],
	}
	match night:
		1:
			m["name"] = "Dao Ben"
			m["islands"] = [{"id": "A", "center": o, "radius": 40.0}]
			m["tiers"] = [{"tier": 0, "y": 0.0, "kind": "island"}]
			m["lanterns"] = _lanterns([[0, 0, 25], [23.8, 0, 7.7], [14.7, 0, -20.2], [-14.7, 0, -20.2], [-23.8, 0, 7.7]])
			m["mote_points"] = ring(o, 12, 8, 0, 45, 0) + ring(o, 33, 16, 0, 22.5, 0)
			m["shade_spawn_points"] = ring(o, 37, 12, 15, 30, 0)
		2:
			var ca := Vector3(0, 0, 0)
			var cb := Vector3(70, 0, 0)
			m["name"] = "Dao Cau"
			m["islands"] = [{"id": "A", "center": ca, "radius": 28.0}, {"id": "B", "center": cb, "radius": 28.0}]
			m["tiers"] = [{"tier": 0, "y": 0.0, "kind": "island"}]
			m["bridge"] = {"x_min": 26.0, "x_max": 44.0, "z_half": 2.0, "y": 0.0, "railing": false}
			m["jump_pads"] = [
				{"pos": Vector3(20, 0, 18), "radius": 1.0, "launch_vy": 14.0, "launch_horizontal": 24.0,
					"direction": Vector3(50, 0, -18).normalized(), "lands_on": "B"},
				{"pos": Vector3(50, 0, -18), "radius": 1.0, "launch_vy": 14.0, "launch_horizontal": 24.0,
					"direction": Vector3(-50, 0, 18).normalized(), "lands_on": "A"},
			]
			m["lanterns"] = _lanterns([[0, 0, 20], [17, 0, -10], [-17, 0, -10], [70, 0, 20], [87, 0, -10], [53, 0, -10]])
			for c in [ca, cb]:
				m["mote_points"] += ring(c, 10, 4, 0, 90, 0) + ring(c, 22, 8, 0, 45, 0)
				m["shade_spawn_points"] += ring(c, 26, 8, 22.5, 45, 0)
			m["charm_positions"] = [Vector3(35, 0, 0)]
		3:
			m["name"] = "Dao Chuong"
			m["islands"] = [{"id": "A", "center": o, "radius": 45.0}]
			m["tiers"] = [
				{"tier": 0, "y": 0.0, "kind": "island"},
				{"tier": 1, "y": 3.0, "kind": "annulus", "r_min": 12.0, "r_max": 24.0, "z_positive_only": true},
				{"tier": 2, "y": 6.0, "kind": "disc", "r_min": 0.0, "r_max": 8.0, "z_positive_only": false},
			]
			for deg in [30.0, 150.0]:
				var a := deg_to_rad(deg)
				m["ramps"].append({"angle_deg": deg, "width": 3.0, "foot_r": 30.0, "foot_y": 0.0,
					"top_r": 24.0, "top_y": 3.0, "dir": Vector3(snappedf(cos(a), 0.000001), 0, snappedf(sin(a), 0.000001))})
			m["jump_pads"] = [{"pos": Vector3(0, 3, 13), "radius": 1.0, "launch_vy": 12.0, "launch_horizontal": 8.0,
				"direction": Vector3(0, 0, -1), "lands_on": "tier2"}]
			m["bell_tower"] = {"center": Vector3(0, 6, 0), "radius": 2.0, "height": 8.0, "climbable": false}
			m["lanterns"] = _lanterns([[0, 6, 6], [18, 3, 10], [-18, 3, 10], [35, 0, -10], [-35, 0, -10], [20, 0, -35], [-20, 0, -35]])
			m["mote_points"] = ring(o, 34, 18, 0, 20, 0) + ring(o, 18, 8, 20, 20, 3) \
				+ [polar(o, 5, 45, 6), polar(o, 5, 135, 6), polar(o, 5, 225, 6), polar(o, 5, 315, 6)]
			m["shade_spawn_points"] = ring(o, 43, 16, 0, 22.5, 0)
			m["charm_positions"] = [Vector3(30, 0, 25), Vector3(-30, 0, 25)]
		_:
			push_error("MapBuilder: night khong hop le %d" % night)
	return m
