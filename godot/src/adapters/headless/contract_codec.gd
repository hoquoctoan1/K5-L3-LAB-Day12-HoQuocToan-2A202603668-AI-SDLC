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

static func _secs(ticks) -> String:
	return fmt_num(float(int(ticks)) / 60.0)

## Giay tu truong tick; neu Sim cu (Phase 1) chi co truong LEGACY tinh bang giay thi dung no.
static func _ptk(p: Dictionary, key: String, legacy_s: String) -> String:
	if p.has(key) and int(p[key]) > 0:
		return _secs(p[key])
	if p.has(legacy_s) and float(p[legacy_s]) > 0.0:
		return fmt_num(float(p[legacy_s]))
	return "0.0"

## Snapshot v1.2 (thu tu key theo interfaces_v2.md muc 6 + 11, [ASSUMPTION] ve thu tu).
## v1.2: lantern them fuel (1 chu so thap phan, den tat 0.0), ever_lit, relit_count; player them capacity.
## state = "paused" khi s.paused va status playing. ttl_s cua mote ttl_ticks<0 = -1.0.
static func snapshot_line(s: SimState) -> String:
	var p: Dictionary = s.player
	var ls: PackedStringArray = []
	for l in s.lanterns:
		ls.append('{"id":%s,"pos":%s,"lit":%s,"deposited":%d,"fuel":%s,"ever_lit":%s,"relit_count":%d}' % [
			enc(l["id"]), vec(l["pos"]), enc(l["lit"]), int(l["deposited"]),
			fmt_num(SimState.fuel_out(l)), enc(bool(l.get("ever_lit", false))), int(l.get("relit_count", 0))])
	var sh: PackedStringArray = []
	for d in s.shades:
		sh.append('{"id":%s,"pos":%s,"state":%s}' % [enc(d["id"]), vec(d["pos"]), enc(d["state"])])
	var mo: PackedStringArray = []
	for m in s.motes:
		var ttl: int = int(m.get("ttl_ticks", -1))
		mo.append('{"id":%s,"pos":%s,"kind":%s,"ttl_s":%s}' % [
			enc(m["id"]), vec(m["pos"]), enc(m.get("kind", "random")),
			("-1.0" if ttl < 0 else _secs(ttl))])
	var dr: PackedStringArray = []
	for d in s.drifters:
		dr.append('{"id":%s,"pos":%s,"state":%s,"stolen":%d}' % [
			enc(d["id"]), vec(d["pos"]), enc(d.get("state", "idle")), int(d.get("stolen", 0))])
	var ch: PackedStringArray = []
	for c in s.charms:
		ch.append('{"id":%s,"available":%s,"respawn_s":%s}' % [
			enc(c["id"]), enc(bool(c.get("available", true))), _secs(c.get("respawn_ticks", 0))])
	var st_name: String = "paused" if (s.paused and s.status == "playing") else s.status
	var w: Dictionary = s.wind
	var head: String = '{"type":"snapshot","tick":%d,"sim_tick":%d,"state":%s,"time_left_s":%s,"score":%d,"night":%d,"wind":{"active":%s,"dir_deg":%s},' % [
		s.tick, s.steps, enc(st_name), fmt_num(s.time_left_s()), s.score, s.night,
		enc(bool(w.get("active", false))), fmt_num(float(w.get("dir_deg", 0.0)))]
	var pl: String = '"player":{"pos":%s,"vel":%s,"grounded":%s,"invuln":%s,"dash_cd_s":%s,"pulse_cd_s":%s,"charm_s":%s,"flames":%d,"carried":%d,"capacity":%d},' % [
		vec(p["pos"]), vec(p.get("vel", Vector3.ZERO)), enc(bool(p.get("grounded", true))),
		_ptk(p, "invuln_ticks", "invuln_left"), _secs(p.get("dash_cd_ticks", 0)),
		_ptk(p, "pulse_cd_ticks", "pulse_cd_left"), _secs(p.get("charm_ticks", 0)),
		int(p["flames"]), int(p["carried"]), SimState.capacity_of(p)]
	var tail: String = '"lanterns":[%s],"shades":[%s],"motes_active":%d,"motes":[%s],"drifters":[%s],"charms":[%s]}' % [
		",".join(ls), ",".join(sh), s.motes.size(), ",".join(mo), ",".join(dr), ",".join(ch)]
	return head + pl + tail

## ev = {"name":String,"data":Dictionary}
static func event_line(tick: int, ev: Dictionary) -> String:
	return '{"type":"event","tick":%d,"name":%s,"data":%s}' % [
		tick, enc(ev["name"]), enc(ev.get("data", {}))]

static func end_line(ticks: int, status: String, score: int) -> String:
	return '{"type":"end","ticks":%d,"state":%s,"score":%d}' % [ticks, enc(status), score]
