class_name ShadeSystem
extends RefCounted
## Bong Muc (buoc 8 di chuyen + buoc 9 cham), contract v1.2 (P3-B2, TICKET-03 muc 2).
## v1.2: vung an toan chi quanh den SimState.has_safe_zone (sang, fuel >= 30).
##  wander: nham den sang fuel < 30 gan nhat (XZ tu Bong Muc, hoa -> id nho); khong co -> den TAT gan nhat
##   (Q1 = A); khong co nua -> di ngau nhien nhu v1.1. Di toi muc tieu voi toc do wander. target_lantern_id = muc tieu.
##  wander -> drain khi XZ <= DRAIN_RANGE_M (2 m) toi den yeu muc tieu: dung yen; dau bi tru o buoc 2b (lantern_system).
##  drain -> chase (May XZ <= 6 m) | wander (den tat, fuel >= 30, hoac XZ > 2 m) | stunned (pulse_system).
##  Het choang -> wander (TICKET-03 muc 2, thay cho "chase neu <= 18" cua v1.1). drain KHONG gay sat thuong [GIA DINH Q7].
## Trang thai: spawning (SPAWNING_TICKS=30, khong di chuyen/khong cham) -> wander <-> chase; recoil; stunned.
## wander: di bo ngau nhien (rng_shade), toc do = shade_speed * WANDER_SPEED_FACTOR (0.5) [ASSUMPTION].
## wander->chase khi XZ toi May <= 12; chase->wander khi > 18. Het stunned/recoil: chase neu <= 18 else wander.
## Truong shade them (lazy): wander_dir Vector2, wander_ticks int, _fresh bool (pulse vua tao).
## Thu tu xu ly: tang dan theo hau to so cua id (S1,S2,..; id khong co so = 0, hoa theo thu tu mang).
## Sinh trong tick nay chi tuong tac tu tick sau (spawn_system chay sau).
## Rot mote khi bi hit: MoteSystem.drop_motes(state, center, count, ttl) (mote_system.gd, owner khac).
##  Test co the gan ShadeSystem.drop_fn = Callable(state, center, count, ttl).

const _MapGeo = preload("res://src/core/maps/map_geometry.gd")
const _MoteSys = preload("res://src/core/systems/mote_system.gd")

const SPAWNING_TICKS: int = 30
const WANDER_SPEED_FACTOR: float = 0.5
const SAFE_EPS: float = 0.001
## Hook rot mote (de test chen stub). Callable(state, center: Vector3, count: int, ttl: int).
static var drop_fn: Callable = Callable()

static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

static func order(arr: Array) -> Array:
	var keyed: Array = []
	for i in arr.size():
		var id := str(arr[i].get("id", ""))
		var n := int(id.substr(1)) if id.length() > 1 and id.substr(1).is_valid_int() else 0
		keyed.append([n, i])
	keyed.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out: Array = []
	for k in keyed:
		out.append(k[1])
	return out

## Cao do mat dat tai pos (NAN neu ngoai dao). state.map rong => dao tron Dem hien tai, y=0.
static func ground_y(state: SimState, pos: Vector3) -> float:
	if state.map.is_empty():
		return 0.0 if _flat(pos).length() <= GameConfig.island_radius(state.night) + 1e-4 else NAN
	return _MapGeo.ground_height(state.map, pos.x, pos.z, pos.y)

static func can_stand(state: SimState, pos: Vector3) -> bool:
	var gy := ground_y(state, pos)
	if is_nan(gy):
		return false
	if not state.map.is_empty() and _MapGeo.blocked_at(state.map, Vector3(pos.x, gy, pos.z)):
		return false
	return true

## Tam den sang gan nhat ma p (XZ) dang nam trong vung an toan, else null.
static func _zone_of(state: SimState, p: Vector2) -> Variant:
	var best: Variant = null
	var best_d := INF
	for l in state.lanterns:
		if not SimState.has_safe_zone(l):
			continue
		var c := _flat(l["pos"])
		var d := p.distance_to(c)
		if d < GameConfig.SAFE_RADIUS - SAFE_EPS and d < best_d:
			best_d = d
			best = c
	return best

## Day p ra ngoai moi vung an toan (toi da 4 vong).
static func _push_out(state: SimState, p: Vector2) -> Vector2:
	for _i in range(4):
		var c: Variant = _zone_of(state, p)
		if c == null:
			break
		var d: Vector2 = p - c
		var dir := Vector2(1.0, 0.0) if d.length() < 1e-6 else d.normalized()
		p = c + dir * (GameConfig.SAFE_RADIUS + SAFE_EPS)
	return p

## Di chuyen XZ bang delta: ton trong be mat di bo, vat can, vung an toan (chan o mep). true neu di chuyen.
static func _try_move(state: SimState, s: Dictionary, delta: Vector2) -> bool:
	var old: Vector3 = s["pos"]
	for cand in [delta, Vector2(delta.x, 0.0), Vector2(0.0, delta.y)]:
		if cand.length() < 1e-9:
			continue
		var np: Vector2 = _flat(old) + cand
		np = _push_out(state, np)
		var npos := Vector3(np.x, old.y, np.y)
		var gy := ground_y(state, npos)
		if is_nan(gy) or not can_stand(state, npos):
			continue
		if _flat(npos).distance_to(_flat(old)) < 1e-9:
			continue
		s["pos"] = Vector3(np.x, gy, np.y)
		return true
	return false

static func _free_state(dist: float) -> String:
	return "chase" if dist <= GameConfig.SHADE_LOSE_INTEREST_M else "wander"

static func _lantern_by_id(state: SimState, id: String) -> Dictionary:
	for l in state.lanterns:
		if str(l["id"]) == id:
			return l
	return {}

## Muc tieu cua Bong Muc wander: den yeu gan nhat, khong co thi den tat gan nhat, khong co nua -> {}.
static func pick_target(state: SimState, sp: Vector2) -> Dictionary:
	var best: Dictionary = {}
	for pass_ in [0, 1]:
		var best_d := INF
		for l in state.lanterns:
			var ok: bool = SimState.is_low_fuel(l) if pass_ == 0 else not l["lit"]
			if not ok:
				continue
			var d := sp.distance_to(_flat(l["pos"]))
			if best.is_empty() or d < best_d - 1e-6 or (absf(d - best_d) <= 1e-6 and str(l["id"]) < str(best["id"])):
				best = l
				best_d = d
		if not best.is_empty():
			return best
	return best

## Tinh muc tieu 1 lan/tick, cache vao s["_tg"] (khong vao snapshot).
static func _wander_target(state: SimState, s: Dictionary) -> Dictionary:
	var tg := pick_target(state, _flat(s["pos"]))
	s["_tg"] = tg
	return tg

static func _enter_wander(s: Dictionary) -> void:
	s["state"] = "wander"
	s["target_lantern_id"] = ""
	s["drain_ticks"] = 0

static func _update(state: SimState, s: Dictionary, pp: Vector2) -> void:
	var fresh: bool = s.get("_fresh", false)
	s["_fresh"] = false
	# day lui
	if int(s["knock_ticks_left"]) > 0:
		s["knock_ticks_left"] = int(s["knock_ticks_left"]) - 1
		var kd: Vector2 = s["knock_dir"]
		if not _try_move(state, s, kd * (GameConfig.PULSE_PUSH_M / float(GameConfig.PULSE_KNOCK_TICKS))):
			s["knock_ticks_left"] = 0   # gap vat can / mep dao: dung
	var dist := _flat(s["pos"]).distance_to(pp)
	var speed := GameConfig.shade_speed(state.night) * GameConfig.DT
	var inside: bool = _zone_of(state, _flat(s["pos"])) != null
	match s["state"]:
		"spawning":
			s["state_ticks_left"] = int(s["state_ticks_left"]) - 1
			if int(s["state_ticks_left"]) <= 0:
				s["state"] = "wander"
				s["state_ticks_left"] = 0
		"stunned":
			if not fresh:
				s["state_ticks_left"] = int(s["state_ticks_left"]) - 1
			if int(s["state_ticks_left"]) <= 0:
				s["state_ticks_left"] = 0
				_enter_wander(s)   # v1.2: het choang -> wander
		"drain":
			var tl := _lantern_by_id(state, str(s.get("target_lantern_id", "")))
			if dist <= GameConfig.DRAIN_CHASE_M:
				s["state"] = "chase"
				s["target_lantern_id"] = ""
				s["drain_ticks"] = 0
			elif tl.is_empty() or not SimState.is_low_fuel(tl) or _flat(s["pos"]).distance_to(_flat(tl["pos"])) > GameConfig.DRAIN_RANGE_M + 1e-4:
				_enter_wander(s)
		"recoil":
			if not inside:
				_try_move(state, s, s["recoil_dir"] * (GameConfig.SHADE_RECOIL_M / float(GameConfig.SHADE_RECOIL_TICKS)))
			s["state_ticks_left"] = int(s["state_ticks_left"]) - 1
			if int(s["state_ticks_left"]) <= 0:
				s["state_ticks_left"] = 0
				s["state"] = _free_state(dist)
		"wander", "chase":
			if s["state"] == "wander" and dist <= GameConfig.SHADE_DETECT_M:
				s["state"] = "chase"
			elif s["state"] == "chase" and dist > GameConfig.SHADE_LOSE_INTEREST_M:
				s["state"] = "wander"
			if s["state"] == "chase":
				s["target_lantern_id"] = ""
			if inside:
				pass
			elif s["state"] == "chase":
				var to: Vector2 = pp - _flat(s["pos"])
				var l := to.length()
				if l > 1e-6:
					_try_move(state, s, to / l * minf(speed, l))
			elif not _wander_target(state, s).is_empty():
				# v1.2: wander co muc tieu (den yeu, else den tat) -> di toi den
				var tg: Dictionary = s["_tg"]
				s["target_lantern_id"] = str(tg["id"])
				var to2: Vector2 = _flat(tg["pos"]) - _flat(s["pos"])
				var l2 := to2.length()
				var wspd := speed * WANDER_SPEED_FACTOR
				if l2 > GameConfig.DRAIN_RANGE_M:
					_try_move(state, s, to2 / l2 * minf(wspd, l2 - GameConfig.DRAIN_RANGE_M * 0.5))
				if SimState.is_low_fuel(tg) and _flat(s["pos"]).distance_to(_flat(tg["pos"])) <= GameConfig.DRAIN_RANGE_M + 1e-4:
					s["state"] = "drain"
					s["drain_ticks"] = 0
			else:
				s["target_lantern_id"] = ""
				if int(s.get("wander_ticks", 0)) <= 0:
					var a := state.rng_shade.next_float() * TAU
					s["wander_dir"] = Vector2(cos(a), sin(a))
					s["wander_ticks"] = 60 + state.rng_shade.next_int(61)
				s["wander_ticks"] = int(s["wander_ticks"]) - 1
				if not _try_move(state, s, s["wander_dir"] * (speed * WANDER_SPEED_FACTOR)):
					s["wander_ticks"] = 0
	# vung an toan: dang o trong (den vua sang) -> day ra, toi da SAFE_PUSH_MAX_TICKS tick
	var pos: Vector3 = s["pos"]
	var c: Variant = _zone_of(state, _flat(pos))
	if c == null:
		s["safe_push_ticks"] = 0
	else:
		if int(s["safe_push_ticks"]) <= 0:
			s["safe_push_ticks"] = GameConfig.SAFE_PUSH_MAX_TICKS
		var left := int(s["safe_push_ticks"])
		var d: Vector2 = _flat(pos) - c
		var dir := Vector2(1.0, 0.0) if d.length() < 1e-6 else d.normalized()
		var need := GameConfig.SAFE_RADIUS + SAFE_EPS - d.length()
		var mv := need if left <= 1 else need / float(left)
		var np: Vector2 = _flat(pos) + dir * mv
		var npos := Vector3(np.x, pos.y, np.y)
		if can_stand(state, npos):
			s["pos"] = Vector3(np.x, ground_y(state, npos), np.y)
		s["safe_push_ticks"] = left - 1
		if _zone_of(state, _flat(s["pos"])) == null:
			s["safe_push_ticks"] = 0

static func _drop(state: SimState, center: Vector3, count: int) -> void:
	if count <= 0:
		return
	if drop_fn.is_valid():
		drop_fn.call(state, center, count, GameConfig.DROPPED_MOTE_TTL_TICKS)
	else:
		var ms: Variant = _MoteSys
		if ms.has_method("drop_motes"):
			ms.call("drop_motes", state, center, count, GameConfig.DROPPED_MOTE_TTL_TICKS)
	# else: mote_system.drop_motes chua co -> mote roi bi mat (xem bao cao phu thuoc)

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	var player: Dictionary = state.player
	var pp := _flat(player["pos"])
	var idxs := order(state.shades)
	for i in idxs:
		_update(state, state.shades[i], pp)
	# cham (buoc 9)
	if int(player["invuln_ticks"]) > 0 or int(player["fall_wait_ticks"]) > 0:
		return
	var ppos: Vector3 = player["pos"]
	for i in idxs:
		var s: Dictionary = state.shades[i]
		if s["state"] != "wander" and s["state"] != "chase":
			continue
		if int(s["safe_push_ticks"]) > 0 or _zone_of(state, _flat(s["pos"])) != null:
			continue
		var spos: Vector3 = s["pos"]
		if _flat(spos).distance_to(pp) > GameConfig.SHADE_HIT_RADIUS + 1e-4:
			continue
		if absf(spos.y - ppos.y) > GameConfig.SHADE_TOUCH_MAX_DY + 1e-4:
			continue
		player["flames"] = int(player["flames"]) - 1
		player["invuln_ticks"] = GameConfig.INVULN_TICKS
		var dropped := int(floor(float(player["carried"]) * GameConfig.HIT_DROP_RATIO))
		player["carried"] = int(player["carried"]) - dropped
		_drop(state, ppos, dropped)
		var away := _flat(spos) - pp
		s["recoil_dir"] = Vector2(1.0, 0.0) if away.length() < 1e-6 else away.normalized()
		s["state"] = "recoil"
		s["state_ticks_left"] = GameConfig.SHADE_RECOIL_TICKS
		events.append({"name": "player_hit", "data": {"by": "shade", "flames": player["flames"], "dropped": dropped}})
		break   # toi da 1 Ngon Lua moi tick
