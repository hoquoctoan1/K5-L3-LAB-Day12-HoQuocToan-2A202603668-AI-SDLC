extends RefCounted

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing":
		return
	var p: Dictionary = state.player
	var kept: Array = []
	for m in state.motes:
		if int(p["carried"]) < GameConfig.CARRY_CAPACITY:
			var d := Vector2(m["pos"].x - p["pos"].x, m["pos"].z - p["pos"].z).length()
			if d <= GameConfig.PICKUP_RADIUS + 1e-4:  # Vector3 la float32
				p["carried"] = int(p["carried"]) + 1
				state.score += GameConfig.SCORE_PER_MOTE
				events.append({"name": "mote_picked", "data": {"carried": p["carried"]}})
				continue
		kept.append(m)
	state.motes = kept
