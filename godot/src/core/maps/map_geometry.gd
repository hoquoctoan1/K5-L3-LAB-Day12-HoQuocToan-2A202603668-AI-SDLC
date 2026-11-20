extends RefCounted
## Truy van hinh hoc tren MapData (thuan, tat dinh). Xem MAPS.md.

const STEP_UP := 0.5  # be mat cao hon y_hint + STEP_UP la "vach" (khong leo duoc)

static func _xz_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

static func inside_island(map: Dictionary, pos: Vector3) -> bool:
	return closest_island_index(map, pos, true) >= 0

## Chi so dao gan nhat (theo XZ). only_inside: chi dao chua pos, else -1.
static func closest_island_index(map: Dictionary, pos: Vector3, only_inside: bool = false) -> int:
	var best := -1
	var best_d := INF
	var isl: Array = map["islands"]
	for i in isl.size():
		var d := _xz_dist(pos, isl[i]["center"])
		if only_inside and d > float(isl[i]["radius"]):
			continue
		if d < best_d:
			best_d = d
			best = i
	return best

static func ground_height(map: Dictionary, x: float, z: float, y_hint: float = INF) -> float:
	var p := Vector3(x, 0, z)
	var limit := INF
	if not is_nan(y_hint):
		limit = y_hint + STEP_UP
	var best := NAN
	var cands: Array = []
	if inside_island(map, p):
		cands.append(0.0)
	for t in map["tiers"]:
		if t["kind"] == "island":
			continue
		var r := Vector2(x, z).length()
		if r >= float(t["r_min"]) and r <= float(t["r_max"]) and (not t["z_positive_only"] or z > 0.0):
			cands.append(float(t["y"]))
	for rp in map["ramps"]:
		var d: Vector3 = rp["dir"]
		var along := x * d.x + z * d.z
		var side := absf(-x * d.z + z * d.x)
		if side <= float(rp["width"]) * 0.5 and along >= float(rp["top_r"]) and along <= float(rp["foot_r"]):
			var f := (float(rp["foot_r"]) - along) / (float(rp["foot_r"]) - float(rp["top_r"]))
			cands.append(float(rp["foot_y"]) + f * (float(rp["top_y"]) - float(rp["foot_y"])))
	var b: Dictionary = map["bridge"]
	if not b.is_empty() and x >= float(b["x_min"]) and x <= float(b["x_max"]) and absf(z) <= float(b["z_half"]):
		cands.append(float(b["y"]))
	for h in cands:
		if h <= limit and (is_nan(best) or h > best):
			best = h
	return best

static func blocked_at(map: Dictionary, pos: Vector3) -> bool:
	var bt: Dictionary = map["bell_tower"]
	if bt.is_empty():
		return false
	var c: Vector3 = bt["center"]
	return _xz_dist(pos, c) <= float(bt["radius"]) and pos.y < c.y + float(bt["height"]) and pos.y >= c.y - 0.5

static func is_walkable(map: Dictionary, pos: Vector3) -> bool:
	return not is_nan(ground_height(map, pos.x, pos.z, pos.y)) and not blocked_at(map, pos)

## Doan from->to (3D) cat tru chuong (XZ tron, Y trong [base, base+height]).
static func blocked_by_obstacle(map: Dictionary, from: Vector3, to: Vector3) -> bool:
	var bt: Dictionary = map["bell_tower"]
	if bt.is_empty():
		return false
	var c: Vector3 = bt["center"]
	var rad := float(bt["radius"])
	var y0: float = c.y
	var y1: float = c.y + float(bt["height"])
	if maxf(from.y, to.y) < y0 or minf(from.y, to.y) > y1:
		return false
	var p := Vector2(from.x - c.x, from.z - c.z)
	var d := Vector2(to.x - from.x, to.z - from.z)
	var a := d.dot(d)
	if a < 1e-12:
		return p.length() <= rad
	var tt := clampf(-p.dot(d) / a, 0.0, 1.0)
	return (p + d * tt).length() <= rad

## Chi so bay nhay ma pos dang dung tren (XZ <= radius, |dy| <= 1.0), -1 neu khong.
static func jump_pad_at(map: Dictionary, pos: Vector3) -> int:
	var pads: Array = map["jump_pads"]
	for i in pads.size():
		var pd: Dictionary = pads[i]
		if _xz_dist(pos, pd["pos"]) <= float(pd["radius"]) and absf(pos.y - pd["pos"].y) <= 1.0:
			return i
	return -1

## Chi so cac mote_points chua co mote (mote: Array Vector3 hoac Dictionary co "pos"; XZ<0.05 va |dy|<0.5 la chiem).
static func free_mote_points(map: Dictionary, motes: Array) -> Array:
	var occ: Array = []
	for m in motes:
		occ.append(m["pos"] if m is Dictionary else m)
	var out: Array = []
	var pts: Array = map["mote_points"]
	for i in pts.size():
		var taken := false
		for q in occ:
			if _xz_dist(pts[i], q) < 0.05 and absf(pts[i].y - q.y) < 0.5:
				taken = true
				break
		if not taken:
			out.append(i)
	return out

static func facing_start(map: Dictionary) -> Vector3:
	return map["start"]["facing"]
