extends RefCounted
## Validate + ap scenario (contract muc D) len SimState. Khong phat event, khong cong diem.
## Quy uoc: motes ids "m<next_mote_id>.." ; shades khong id -> "S<next_shade_id>.." (id "S<n>" tuong minh
## nang next_shade_id len n+1); shade mac dinh state "chase", stun_left 0.

static func _is_num(v) -> bool:
	return typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT

static func _is_int(v) -> bool:
	return typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and v == floorf(v))

static func _vec3(v) -> Variant:
	if typeof(v) != TYPE_ARRAY or v.size() != 3:
		return null
	for x in v:
		if not _is_num(x):
			return null
	return Vector3(float(v[0]), float(v[1]), float(v[2]))

static func validate(state: SimState, d) -> String:
	if typeof(d) != TYPE_DICTIONARY:
		return "scenario phai la object"
	if d.has("player"):
		var p = d["player"]
		if typeof(p) != TYPE_DICTIONARY:
			return "player phai la object"
		if p.has("pos") and _vec3(p["pos"]) == null:
			return "player.pos phai la [x,y,z]"
		for k in ["carried", "flames"]:
			if p.has(k) and not (_is_int(p[k]) and p[k] >= 0):
				return "player.%s phai la so nguyen >= 0" % k
	for k in ["random_motes", "random_shades"]:
		if d.has(k) and typeof(d[k]) != TYPE_BOOL:
			return "%s phai la bool" % k
	if d.has("motes"):
		if typeof(d["motes"]) != TYPE_ARRAY:
			return "motes phai la mang"
		for m in d["motes"]:
			if _vec3(m) == null:
				return "mote phai la [x,y,z]"
	if d.has("shades"):
		if typeof(d["shades"]) != TYPE_ARRAY:
			return "shades phai la mang"
		for s in d["shades"]:
			if typeof(s) != TYPE_DICTIONARY or _vec3(s.get("pos")) == null:
				return "shade phai la object co pos [x,y,z]"
			if s.has("id") and typeof(s["id"]) != TYPE_STRING:
				return "shade.id phai la chuoi"
			if s.has("state") and typeof(s["state"]) != TYPE_STRING:
				return "shade.state phai la chuoi"
	if d.has("lanterns"):
		if typeof(d["lanterns"]) != TYPE_ARRAY:
			return "lanterns phai la mang"
		for l in d["lanterns"]:
			if typeof(l) != TYPE_DICTIONARY or typeof(l.get("id")) != TYPE_STRING:
				return "lantern phai la object co id"
			var found := false
			for sl in state.lanterns:
				if sl["id"] == l["id"]:
					found = true
			if not found:
				return "lantern id khong ton tai: " + l["id"]
			if l.has("pos") and _vec3(l["pos"]) == null:
				return "lantern.pos phai la [x,y,z]"
			if l.has("deposited") and not (_is_int(l["deposited"]) and l["deposited"] >= 0):
				return "lantern.deposited phai la so nguyen >= 0"
			if l.has("lit") and typeof(l["lit"]) != TYPE_BOOL:
				return "lantern.lit phai la bool"
	if d.has("time_left_s") and not (_is_num(d["time_left_s"]) and d["time_left_s"] >= 0):
		return "time_left_s phai la so >= 0"
	return ""

## Tra ve {ok:bool, error:String}. Loi => state khong bi sua.
static func apply(state: SimState, d) -> Dictionary:
	var err := validate(state, d)
	if err != "":
		return {"ok": false, "error": err}
	if d.has("player"):
		var p: Dictionary = d["player"]
		if p.has("pos"):
			state.player["pos"] = _vec3(p["pos"])
		if p.has("carried"):
			state.player["carried"] = int(p["carried"])
		if p.has("flames"):
			state.player["flames"] = int(p["flames"])
	if d.has("random_motes"):
		state.random_motes = d["random_motes"]
	if d.has("random_shades"):
		state.random_shades = d["random_shades"]
	if d.has("motes"):
		state.motes = []
		for m in d["motes"]:
			state.motes.append({"id": "m%d" % state.next_mote_id, "pos": _vec3(m)})
			state.next_mote_id += 1
	if d.has("shades"):
		state.shades = []
		for s in d["shades"]:
			var id: String
			if s.has("id"):
				id = s["id"]
				if id.begins_with("S") and id.substr(1).is_valid_int():
					state.next_shade_id = maxi(state.next_shade_id, id.substr(1).to_int() + 1)
			else:
				id = "S%d" % state.next_shade_id
				state.next_shade_id += 1
			state.shades.append({"id": id, "pos": _vec3(s["pos"]),
				"state": s.get("state", "chase"), "stun_left": 0.0})
	if d.has("lanterns"):
		for l in d["lanterns"]:
			for sl in state.lanterns:
				if sl["id"] == l["id"]:
					if l.has("pos"):
						sl["pos"] = _vec3(l["pos"])
					if l.has("deposited"):
						sl["deposited"] = int(l["deposited"])
					if l.has("lit"):
						sl["lit"] = l["lit"]
	if d.has("time_left_s"):
		state.time_left_initial = float(d["time_left_s"])
	return {"ok": true, "error": ""}
