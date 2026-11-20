extends RefCounted

static func step(state: SimState, input: Dictionary, events: Array) -> void:
	if state.status != "playing":
		return
	if not input.get("interact", false):
		return
	var p: Dictionary = state.player
	if int(p["carried"]) <= 0:
		return
	var best: Dictionary = {}
	var best_d := INF
	for l in state.lanterns:
		if l["lit"]:
			continue
		var d := Vector2(l["pos"].x - p["pos"].x, l["pos"].z - p["pos"].z).length()
		if d > GameConfig.INTERACT_RADIUS + 1e-4:
			continue
		if d < best_d or (d == best_d and str(l["id"]) < str(best["id"])):
			best = l
			best_d = d
	if best.is_empty():
		return
	var amount := mini(int(p["carried"]), GameConfig.LANTERN_COST - int(best["deposited"]))
	if amount > 0:
		p["carried"] = int(p["carried"]) - amount
		best["deposited"] = int(best["deposited"]) + amount
		events.append({"name": "deposit", "data": {"lantern_id": best["id"], "amount": amount, "deposited": best["deposited"]}})
	if int(best["deposited"]) >= GameConfig.LANTERN_COST and not best["lit"]:
		best["lit"] = true
		state.score += GameConfig.SCORE_PER_LANTERN
		events.append({"name": "lantern_lit", "data": {"lantern_id": best["id"]}})
