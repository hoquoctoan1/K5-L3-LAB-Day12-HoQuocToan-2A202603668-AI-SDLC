extends RefCounted
## Validate + ap scenario (contract muc D) len SimState. Khong phat event, khong cong diem.
## Quy uoc: motes ids "m<next_mote_id>.." ; shades khong id -> "S<next_shade_id>.." (id "S<n>" tuong minh
## nang next_shade_id len n+1); shade mac dinh state "chase", stun_left 0.

const SHADE_STATES := ["spawning", "wander", "chase", "recoil", "stunned"]
const DRIFTER_STATES := ["idle", "chase", "flee", "removed"]
const PLAYER_TICK_KEYS := ["invuln_ticks", "dash_cd_ticks", "pulse_cd_ticks", "charm_ticks"]

static func _nonneg_int(v) -> bool:
	return _is_int(v) and v >= 0

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
	for k in ["random_drifters", "wind_enabled"]:
		if d.has(k) and typeof(d[k]) != TYPE_BOOL:
			return "%s phai la bool" % k
	if d.has("drifters"):
		if typeof(d["drifters"]) != TYPE_ARRAY:
			return "drifters phai la mang"
		for x in d["drifters"]:
			if typeof(x) != TYPE_DICTIONARY or _vec3(x.get("pos")) == null:
				return "drifter phai la object co pos [x,y,z]"
			if x.has("id") and typeof(x["id"]) != TYPE_STRING:
				return "drifter.id phai la chuoi"
			if x.has("state") and not (typeof(x["state"]) == TYPE_STRING and x["state"] in DRIFTER_STATES):
				return "drifter.state khong hop le"
			if x.has("stolen") and not _nonneg_int(x["stolen"]):
				return "drifter.stolen phai la so nguyen >= 0"
	if d.has("charms"):
		if typeof(d["charms"]) != TYPE_ARRAY:
			return "charms phai la mang"
		for x in d["charms"]:
			if typeof(x) != TYPE_DICTIONARY or _vec3(x.get("pos")) == null:
				return "charm phai la object co pos [x,y,z]"
			if x.has("id") and typeof(x["id"]) != TYPE_STRING:
				return "charm.id phai la chuoi"
			if x.has("available") and typeof(x["available"]) != TYPE_BOOL:
				return "charm.available phai la bool"
			if x.has("respawn_ticks") and not _nonneg_int(x["respawn_ticks"]):
				return "charm.respawn_ticks phai la so nguyen >= 0"
	if d.has("player"):
		var p = d["player"]
		if typeof(p) != TYPE_DICTIONARY:
			return "player phai la object"
		if p.has("pos") and _vec3(p["pos"]) == null:
			return "player.pos phai la [x,y,z]"
		for k in ["carried", "flames"]:
			if p.has(k) and not (_is_int(p[k]) and p[k] >= 0):
				return "player.%s phai la so nguyen >= 0" % k
		for k in PLAYER_TICK_KEYS:
			if p.has(k) and not _nonneg_int(p[k]):
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
			if s.has("state") and not (s["state"] in SHADE_STATES):
				return "shade.state khong hop le: " + s["state"]
			if s.has("state_ticks_left") and not _nonneg_int(s["state_ticks_left"]):
				return "shade.state_ticks_left phai la so nguyen >= 0"
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
		for k in PLAYER_TICK_KEYS:
			if p.has(k):
				state.player[k] = int(p[k])
	if d.has("random_motes"):
		state.random_motes = d["random_motes"]
	if d.has("random_shades"):
		state.random_shades = d["random_shades"]
	if d.has("random_drifters"):
		state.random_drifters = d["random_drifters"]
	if d.has("wind_enabled"):
		state.wind_enabled = d["wind_enabled"]
	if d.has("drifters"):
		state.drifters = []
		for x in d["drifters"]:
			var did: String
			if x.has("id"):
				did = x["id"]
				if did.begins_with("D") and did.substr(1).is_valid_int():
					state.next_drifter_id = maxi(state.next_drifter_id, did.substr(1).to_int() + 1)
			else:
				did = "D%d" % state.next_drifter_id
				state.next_drifter_id += 1
			var dd := SimState.make_drifter(did, _vec3(x["pos"]), x.get("state", "idle"))
			dd["stolen"] = int(x.get("stolen", 0))
			dd["has_stolen"] = dd["stolen"] > 0
			state.drifters.append(dd)
	if d.has("charms"):
		state.charms = []
		state.extras["charms_init"] = true  # mang scenario thay the mac dinh, ke ca mang rong
		for x in d["charms"]:
			var cid: String
			if x.has("id"):
				cid = x["id"]
				if cid.begins_with("C") and cid.substr(1).is_valid_int():
					state.next_charm_id = maxi(state.next_charm_id, cid.substr(1).to_int() + 1)
			else:
				cid = "C%d" % state.next_charm_id
				state.next_charm_id += 1
			var cc := SimState.make_charm(cid, _vec3(x["pos"]))
			cc["available"] = bool(x.get("available", true))
			cc["respawn_ticks"] = int(x.get("respawn_ticks", 0))
			state.charms.append(cc)
	if d.has("motes"):
		state.motes = []
		for m in d["motes"]:
			state.motes.append(SimState.make_mote("m%d" % state.next_mote_id, _vec3(m)))
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
			var sd := SimState.make_shade(id, _vec3(s["pos"]), s.get("state", "chase"))
			sd["state_ticks_left"] = int(s.get("state_ticks_left", 0))
			state.shades.append(sd)
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
