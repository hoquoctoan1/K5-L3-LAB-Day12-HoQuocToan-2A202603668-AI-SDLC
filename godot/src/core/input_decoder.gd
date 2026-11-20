class_name InputDecoder
extends RefCounted
## Giai ma inputs JSON -> FrameInput theo tick. Thuan, khong dung Node/Input.
## FrameInput v2: {move, cam_yaw_deg, jump, interact, pulse, dash, pause} (nut = canh len).
## Dung: var r := InputDecoder.parse(data); var d := InputDecoder.new(); d.load_data(data)
## roi goi d.next(0), d.next(1), ... theo thu tu.

const BUTTONS := ["jump", "interact", "pulse", "dash", "pause"]

var _frames: Array = []
var _idx := 0
var _move := Vector2.ZERO
var _yaw := 0.0
var _held := {"jump": false, "interact": false, "pulse": false, "dash": false, "pause": false}
var _last_tick := -1

static func _is_num(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT

## Tra ve {ok:bool, error:String}
static func parse(data) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "inputs phai la object"}
	if not data.has("frames") or typeof(data["frames"]) != TYPE_ARRAY:
		return {"ok": false, "error": "thieu frames[]"}
	var prev := -1
	var i := 0
	for fr in data["frames"]:
		var p := "frames[%d]" % i
		i += 1
		if typeof(fr) != TYPE_DICTIONARY:
			return {"ok": false, "error": p + " phai la object"}
		if not fr.has("tick"):
			return {"ok": false, "error": p + " thieu tick"}
		var tk = fr["tick"]
		var is_int: bool = typeof(tk) == TYPE_INT or (typeof(tk) == TYPE_FLOAT and tk == floor(tk))
		if not is_int:
			return {"ok": false, "error": p + ".tick phai la so nguyen"}
		if int(tk) < 0 or int(tk) <= prev:
			return {"ok": false, "error": p + ".tick phai tang nghiem ngat"}
		prev = int(tk)
		if fr.has("move"):
			var m = fr["move"]
			if typeof(m) != TYPE_ARRAY or m.size() != 2 or not _is_num(m[0]) or not _is_num(m[1]):
				return {"ok": false, "error": p + ".move phai la [x,z] so"}
			if absf(float(m[0])) > 1.0 or absf(float(m[1])) > 1.0:
				return {"ok": false, "error": p + ".move ngoai [-1,1]"}
		if fr.has("cam_yaw_deg") and not _is_num(fr["cam_yaw_deg"]):
			return {"ok": false, "error": p + ".cam_yaw_deg phai la so"}
		for b in BUTTONS:
			if fr.has(b) and typeof(fr[b]) != TYPE_BOOL:
				return {"ok": false, "error": p + "." + b + " phai la bool"}
	return {"ok": true, "error": ""}

## Nap frames (da validate). Tra ve ket qua parse; neu loi, decoder giu trang thai idle.
func load_data(data) -> Dictionary:
	reset()
	var r := parse(data)
	if r["ok"]:
		_frames = data["frames"]
	return r

func reset() -> void:
	_frames = []
	_idx = 0
	_move = Vector2.ZERO
	_yaw = 0.0
	_held = {"jump": false, "interact": false, "pulse": false, "dash": false, "pause": false}
	_last_tick = -1

## Goi lan luot tick 0,1,2,...
func next(tick: int) -> Dictionary:
	var edges := {"jump": false, "interact": false, "pulse": false, "dash": false, "pause": false}
	while _idx < _frames.size() and int(_frames[_idx]["tick"]) <= tick:
		var fr: Dictionary = _frames[_idx]
		_idx += 1
		if fr.has("move"):
			_move = Vector2(float(fr["move"][0]), float(fr["move"][1]))
		if fr.has("cam_yaw_deg"):
			_yaw = float(fr["cam_yaw_deg"])
		for b in BUTTONS:
			if fr.has(b):
				var nv: bool = fr[b]
				if nv and not _held[b]:
					edges[b] = true
				_held[b] = nv
	var th := deg_to_rad(_yaw)
	var c := cos(th)
	var s := sin(th)
	var w := Vector2(_move.x * c + _move.y * s, -_move.x * s + _move.y * c)
	if w.length() > 1.0:
		w = w.normalized()
	return {"move": w, "cam_yaw_deg": _yaw, "jump": edges["jump"], "interact": edges["interact"], "pulse": edges["pulse"], "dash": edges["dash"], "pause": edges["pause"]}
