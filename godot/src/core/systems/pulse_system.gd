class_name PulseSystem
extends RefCounted
## Xung (pulse): tieu carried, lam choang va day lui shade trong ban kinh.
## Quyet dinh: moi shade trong ban kinh deu duoc tinh (ke ca shade dang stunned,
## stun duoc khoi dong lai) va cong SCORE_PER_STUN.

static func step(state: SimState, input: Dictionary, events: Array) -> void:
	if state.status != "playing":
		return
	if not input.get("pulse", false):
		return
	var p: Dictionary = state.player
	if int(p["carried"]) < GameConfig.PULSE_COST or float(p["pulse_cd_left"]) > 0.0:
		return
	p["carried"] = int(p["carried"]) - GameConfig.PULSE_COST
	p["pulse_cd_left"] = GameConfig.PULSE_COOLDOWN_S
	var ppos: Vector3 = p["pos"]
	var ids: Array = []
	for s in state.shades:
		var spos: Vector3 = s["pos"]
		var d := Vector2(spos.x - ppos.x, spos.z - ppos.z)
		if d.length() > GameConfig.PULSE_RADIUS:
			continue
		var dir := Vector2(1.0, 0.0) if d.length() < 0.000001 else d.normalized()
		var np := Vector2(spos.x, spos.z) + dir * GameConfig.PULSE_PUSH_M
		if np.length() > GameConfig.ISLAND_RADIUS:
			np = np.normalized() * GameConfig.ISLAND_RADIUS
		s["pos"] = Vector3(np.x, spos.y, np.y)
		s["state"] = "stunned"
		s["stun_left"] = GameConfig.PULSE_STUN_S
		state.score += GameConfig.SCORE_PER_STUN
		ids.append(s["id"])
	events.append({"name": "pulse", "data": {"stunned_ids": ids}})
