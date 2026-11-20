class_name PlayerSystem
extends RefCounted
## Di chuyen, nhay, trong luc, gioi han dao, giam timer invuln/pulse_cd.
## input.move (Vector2) -> x = pos.x, y = pos.z.

static func step(state: SimState, input: Dictionary, events: Array) -> void:
	if state.status != "playing":
		return
	var dt := GameConfig.DT
	var p: Dictionary = state.player
	var pos: Vector3 = p["pos"]
	var mv: Vector2 = input.get("move", Vector2.ZERO)
	pos.x += mv.x * GameConfig.PLAYER_SPEED * dt
	pos.z += mv.y * GameConfig.PLAYER_SPEED * dt

	if input.get("jump", false) and p["on_ground"]:
		p["vy"] = GameConfig.JUMP_SPEED
		p["on_ground"] = false

	if not p["on_ground"]:
		p["vy"] = float(p["vy"]) - GameConfig.GRAVITY * dt
		pos.y += float(p["vy"]) * dt
		if pos.y <= 0.0:
			pos.y = 0.0
			p["vy"] = 0.0
			p["on_ground"] = true

	var h := Vector2(pos.x, pos.z)
	if h.length() > GameConfig.ISLAND_RADIUS:
		h = h.normalized() * GameConfig.ISLAND_RADIUS
		pos.x = h.x
		pos.z = h.y

	p["pos"] = pos
	p["invuln_left"] = maxf(0.0, float(p["invuln_left"]) - dt)
	p["pulse_cd_left"] = maxf(0.0, float(p["pulse_cd_left"]) - dt)
