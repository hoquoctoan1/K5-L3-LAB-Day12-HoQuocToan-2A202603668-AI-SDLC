extends RefCounted
## Ma hoa JSONL theo Test Contract muc E. Byte-on-dinh: so thuc lam tron 3 chu so
## ("%.3f", bo so 0 thua nhung giu >= 1 chu so le, -0 -> 0.0); khoa theo thu tu co dinh.

static func fmt_num(v: float) -> String:
	if is_nan(v) or is_inf(v):
		return "0.0"
	var s := "%.3f" % v
	while s.ends_with("0") and not s.ends_with(".0"):
		s = s.substr(0, s.length() - 1)
	if s == "-0.0":
		s = "0.0"
	return s

static func vec(v: Vector3) -> String:
	return "[%s,%s,%s]" % [fmt_num(v.x), fmt_num(v.y), fmt_num(v.z)]

## Ma hoa gia tri bat ky (Dictionary giu thu tu chen).
static func enc(v) -> String:
	match typeof(v):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if v else "false"
		TYPE_INT:
			return str(v)
		TYPE_FLOAT:
			return fmt_num(v)
		TYPE_STRING, TYPE_STRING_NAME:
			return JSON.stringify(str(v))
		TYPE_VECTOR3:
			return vec(v)
		TYPE_VECTOR2:
			return "[%s,%s]" % [fmt_num(v.x), fmt_num(v.y)]
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			var parts: PackedStringArray = []
			for x in v:
				parts.append(enc(x))
			return "[" + ",".join(parts) + "]"
		TYPE_DICTIONARY:
			var parts2: PackedStringArray = []
			for k in v.keys():
				parts2.append(JSON.stringify(str(k)) + ":" + enc(v[k]))
			return "{" + ",".join(parts2) + "}"
	return JSON.stringify(str(v))

static func snapshot_line(s: SimState) -> String:
	var p: Dictionary = s.player
	var ls: PackedStringArray = []
	for l in s.lanterns:
		ls.append('{"id":%s,"pos":%s,"lit":%s,"deposited":%d}' % [
			enc(l["id"]), vec(l["pos"]), enc(l["lit"]), int(l["deposited"])])
	var sh: PackedStringArray = []
	for d in s.shades:
		sh.append('{"id":%s,"pos":%s,"state":%s}' % [enc(d["id"]), vec(d["pos"]), enc(d["state"])])
	var mo: PackedStringArray = []
	for m in s.motes:
		mo.append('{"id":%s,"pos":%s}' % [enc(m["id"]), vec(m["pos"])])
	var head: String = '{"type":"snapshot","tick":%d,"sim_tick":%d,"state":%s,"time_left_s":%s,"score":%d,' % [
		s.tick, s.steps, enc(s.status), fmt_num(s.time_left_s()), s.score]
	var pl: String = '"player":{"pos":%s,"flames":%d,"carried":%d},' % [
		vec(p["pos"]), int(p["flames"]), int(p["carried"])]
	var tail: String = '"lanterns":[%s],"shades":[%s],"motes_active":%d,"motes":[%s]}' % [
		",".join(ls), ",".join(sh), s.motes.size(), ",".join(mo)]
	return head + pl + tail

## ev = {"name":String,"data":Dictionary}
static func event_line(tick: int, ev: Dictionary) -> String:
	return '{"type":"event","tick":%d,"name":%s,"data":%s}' % [
		tick, enc(ev["name"]), enc(ev.get("data", {}))]

static func end_line(ticks: int, status: String, score: int) -> String:
	return '{"type":"end","ticks":%d,"state":%s,"score":%d}' % [ticks, enc(status), score]
