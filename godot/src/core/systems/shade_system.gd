class_name ShadeSystem
extends RefCounted
## Shade: duoi nguoi choi, tranh vung an toan cua den da sang, gay sat thuong.

static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## Day vi tri ra ngoai SAFE_RADIUS cua moi den sang, roi kep trong dao (tat dinh).
static func constrain(pos: Vector3, lanterns: Array) -> Vector3:
	var p := _flat(pos)
	for _i in range(3):
		for l in lanterns:
			if not l.get("lit", false):
				continue
			var c := _flat(l["pos"])
			var d := p - c
			var dl := d.length()
			if dl < GameConfig.SAFE_RADIUS:
				var dir := Vector2(1.0, 0.0) if dl < 0.000001 else d / dl
				p = c + dir * GameConfig.SAFE_RADIUS
		if p.length() > GameConfig.ISLAND_RADIUS:
			p = p.normalized() * GameConfig.ISLAND_RADIUS
	return Vector3(p.x, pos.y, p.y)

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing":
		return
	var player: Dictionary = state.player
	var pp := _flat(player["pos"])
	var hit_done := false
	for s in state.shades:
		if s["state"] == "stunned":
			s["stun_left"] = float(s["stun_left"]) - GameConfig.DT
			if s["stun_left"] <= 0.0:
				s["state"] = "chase"
				s["stun_left"] = 0.0
			continue
		var sp := _flat(s["pos"])
		var to := pp - sp
		var dist := to.length()
		var step_len := GameConfig.SHADE_SPEED * GameConfig.DT
		if dist > 0.000001:
			sp += to / dist * minf(step_len, dist)
		var old_y: float = s["pos"].y
		s["pos"] = constrain(Vector3(sp.x, old_y, sp.y), state.lanterns)
		if hit_done or float(player["invuln_left"]) > 0.0:
			continue
		if _flat(s["pos"]).distance_to(pp) <= GameConfig.SHADE_HIT_RADIUS:
			hit_done = true
			player["flames"] = int(player["flames"]) - 1
			player["invuln_left"] = GameConfig.INVULN_S
			var dropped := int(floor(float(player["carried"]) * GameConfig.HIT_DROP_RATIO))
			player["carried"] = int(player["carried"]) - dropped
			events.append({"name": "player_hit", "data": {"by": "shade", "flames": player["flames"], "dropped": dropped}})
