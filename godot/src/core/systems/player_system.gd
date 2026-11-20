class_name PlayerSystem
extends RefCounted
## Buoc 2-3 tick order: dem timer (tick), chay/nhay/luot/gio, roi khoi dao.
## input.move (Vector2): x = pos.x, y = pos.z. Xem interfaces_v2.md.

const MapGeometry = preload("res://src/core/maps/map_geometry.gd")
const STEP_DOWN := 0.5   # xuong doc/bac <= 0.5 m van dinh dat; lon hon thi roi (vach tang)

## Do cao be mat tai (x,z) cho chan o y_hint; NAN = khong co be mat (void).
static func ground_at(state: SimState, x: float, z: float, y_hint: float) -> float:
	if not state.map.is_empty() and state.map.has("islands"):
		return MapGeometry.ground_height(state.map, x, z, y_hint)
	var h := state.height_at(x, z, y_hint)
	return NAN if h < -1.0e8 else h

static func _blocked(state: SimState, pos: Vector3) -> bool:
	return not state.map.is_empty() and state.map.has("bell_tower") and MapGeometry.blocked_at(state.map, pos)

static func _start_pos(state: SimState) -> Vector3:
	if not state.map.is_empty() and state.map.has("start"):
		return state.map["start"]["pos"]
	return Vector3.ZERO

static func step(state: SimState, input: Dictionary, events: Array) -> void:
	if state.paused or state.status != "playing":
		return
	var dt := GameConfig.DT
	var p: Dictionary = state.player
	# --- buoc 2: bo dem (tick) ---
	for k in ["invuln_ticks", "dash_cd_ticks", "pulse_cd_ticks", "charm_ticks"]:
		p[k] = maxi(0, int(p[k]) - 1)

	var pos: Vector3 = p["pos"]
	# dang cho hoi sinh
	if int(p["fall_wait_ticks"]) > 0:
		p["fall_wait_ticks"] = int(p["fall_wait_ticks"]) - 1
		if int(p["fall_wait_ticks"]) == 0:
			_respawn(state)
		return
	if int(p["flames"]) <= 0 and pos.y < GameConfig.FALL_Y:
		return  # het lua: dung nguyen, lifecycle xu ly

	# --- buoc 3: di chuyen ---
	var vel: Vector3 = p["vel"]
	var mv: Vector2 = input.get("move", Vector2.ZERO)
	if mv.length() > 1.0:
		mv = mv.normalized()
	var charm := int(p["charm_ticks"]) > 0
	var speed := GameConfig.CHARM_RUN_SPEED if charm else GameConfig.PLAYER_SPEED
	if mv.length() > 1e-6:
		p["facing"] = mv.normalized()

	# lướt (canh len do InputDecoder)
	if input.get("dash", false) and int(p["dash_ticks_left"]) == 0 and (charm or int(p["dash_cd_ticks"]) == 0):
		var dd: Vector2 = mv.normalized() if mv.length() > 1e-6 else (p["facing"] as Vector2).normalized()
		p["dash_dir"] = dd
		p["dash_ticks_left"] = GameConfig.DASH_TICKS
		p["dash_cd_ticks"] = 0 if charm else GameConfig.DASH_COOLDOWN_TICKS
		events.append({"name": "dash", "data": {}})

	var hv := Vector2(vel.x, vel.z)
	if int(p["dash_ticks_left"]) > 0:
		hv = (p["dash_dir"] as Vector2) * GameConfig.DASH_SPEED
		p["dash_ticks_left"] = int(p["dash_ticks_left"]) - 1
	elif p["launched"]:
		hv = p.get("launch_vel", hv)
	elif mv.length() > 1e-6:
		hv = mv * speed
	else:
		var dec := speed * dt / GameConfig.PLAYER_ACCEL_STOP_S
		var l := hv.length()
		hv = Vector2.ZERO if l <= dec + 1e-6 else hv * ((l - dec) / l)

	# nhay (chi khi dung tren dat)
	if input.get("jump", false) and p["grounded"] and not p["launched"]:
		vel.y = GameConfig.JUMP_SPEED
		p["grounded"] = false

	var push := Vector2.ZERO
	var wd = state.wind.get("push", null) if not state.wind.is_empty() else null
	if wd is Vector2:
		push = wd
	elif wd is Vector3:
		push = Vector2(wd.x, wd.z)

	# ngang: thu day du, roi truot theo tung truc; vach tang / thap chuong chan
	var old := pos
	var disp := (hv + push) * dt
	var cand := [Vector3(old.x + disp.x, old.y, old.z + disp.y), Vector3(old.x + disp.x, old.y, old.z), Vector3(old.x, old.y, old.z + disp.y)]
	var moved := false
	for c in cand:
		if c == old:
			continue
		if _blocked(state, c):
			continue
		var top := ground_at(state, c.x, c.z, INF)
		if not is_nan(top) and top > old.y + MapGeometry.STEP_UP + 1e-6:
			continue  # vach dung
		pos = c
		moved = true
		break
	if not moved:
		hv = Vector2.ZERO if not p["launched"] else hv

	# doc
	var g := ground_at(state, pos.x, pos.z, old.y)
	if p["grounded"]:
		if not is_nan(g) and old.y - g <= STEP_DOWN + 1e-6:
			pos.y = g
			vel.y = 0.0
		else:
			p["grounded"] = false  # buoc ra khoi mep: bat dau roi
	if not p["grounded"]:
		vel.y -= GameConfig.GRAVITY * dt
		pos.y += vel.y * dt
		if not is_nan(g) and vel.y <= 0.0 and pos.y <= g:
			pos.y = g
			vel.y = 0.0
			p["grounded"] = true
			if p["launched"] and int(p["dash_ticks_left"]) == 0:
				hv = Vector2.ZERO
			p["launched"] = false

	vel.x = hv.x
	vel.z = hv.y
	p["vel"] = vel
	p["pos"] = pos
	p["on_ground"] = p["grounded"]   # LEGACY
	p["vy"] = vel.y                  # LEGACY

	# roi khoi dao: dung 1 lan (bo qua bat tu)
	if pos.y < GameConfig.FALL_Y:
		var lost := int(p["carried"])
		p["flames"] = maxi(0, int(p["flames"]) - 1)
		p["carried"] = 0
		p["dash_ticks_left"] = 0
		p["launched"] = false
		p["vel"] = Vector3.ZERO
		if int(p["flames"]) > 0:
			p["fall_wait_ticks"] = GameConfig.FALL_WAIT_TICKS
		events.append({"name": "player_hit", "data": {"by": "fall", "flames": int(p["flames"]), "dropped": 0, "lost": lost}})

static func _respawn(state: SimState) -> void:
	var p: Dictionary = state.player
	p["pos"] = _start_pos(state)
	p["vel"] = Vector3.ZERO
	p["grounded"] = true
	p["launched"] = false
	p["dash_ticks_left"] = 0
	p["invuln_ticks"] = GameConfig.FALL_RESPAWN_INVULN_TICKS
	p["on_ground"] = true
	p["vy"] = 0.0
