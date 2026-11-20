extends RefCounted
## LanternSystem (P2-B34): tuong tac den (buoc 5) + vung an toan (buoc 6).
## Vung an toan: GameConfig.SAFE_RADIUS (6 m) quanh den DA SANG.
##  - shade_system dung `LanternSystem.in_safe_zone(state, pos)` de CHAN shade di vao (khong cho buoc vao).
##  - shade dang o trong vung (den vua sang / spawn trong vung) bi day ra mep trong toi da
##    GameConfig.SAFE_PUSH_MAX_TICKS tick; trong luc do shade["safe_push_ticks"] > 0 => shade KHONG gay sat thuong
##    (shade_system phai kiem tra `safe_push_ticks > 0` truoc khi hit). Het day thi safe_push_ticks = 0.
## Tien do nap dở nho trong lantern["deposited"]. So den moi dem do map (lantern_positions) quyet dinh.

static func in_safe_zone(state: SimState, pos: Vector3) -> bool:
	for l in state.lanterns:
		if l["lit"] and Vector2(pos.x - l["pos"].x, pos.z - l["pos"].z).length() < GameConfig.SAFE_RADIUS - 1e-4:
			return true
	return false

static func step(state: SimState, input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	_interact(state, input, events)
	_safe_zone(state)

static func _interact(state: SimState, input: Dictionary, events: Array) -> void:
	if not input.get("interact", false):
		return
	var p: Dictionary = state.player
	if int(p["carried"]) <= 0 or int(p.get("fall_wait_ticks", 0)) > 0:
		return
	var best: Dictionary = {}
	var best_d := INF
	for l in state.lanterns:
		if l["lit"]:
			continue
		var d := Vector2(l["pos"].x - p["pos"].x, l["pos"].z - p["pos"].z).length()
		if d > GameConfig.INTERACT_RADIUS + 1e-4:
			continue
		if best.is_empty() or d < best_d - 1e-6 or (absf(d - best_d) <= 1e-6 and str(l["id"]) < str(best["id"])):
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

static func _safe_zone(state: SimState) -> void:
	var R: float = GameConfig.SAFE_RADIUS
	for s in state.shades:
		var inside_l: Dictionary = {}
		var inside_d := INF
		for l in state.lanterns:
			if not l["lit"]:
				continue
			var d := Vector2(s["pos"].x - l["pos"].x, s["pos"].z - l["pos"].z).length()
			if d < R - 1e-4 and d < inside_d:
				inside_l = l
				inside_d = d
		if inside_l.is_empty():
			s["safe_push_ticks"] = 0
			continue
		if int(s.get("safe_push_ticks", 0)) <= 0:
			s["safe_push_ticks"] = GameConfig.SAFE_PUSH_MAX_TICKS
		var ticks: int = int(s["safe_push_ticks"])
		var dir := Vector2(s["pos"].x - inside_l["pos"].x, s["pos"].z - inside_l["pos"].z)
		dir = dir.normalized() if dir.length() > 1e-6 else Vector2(1.0, 0.0)
		var new_d: float = R if ticks <= 1 else inside_d + (R - inside_d) / float(ticks)
		s["pos"] = Vector3(inside_l["pos"].x + dir.x * new_d, s["pos"].y, inside_l["pos"].z + dir.y * new_d)
		s["safe_push_ticks"] = ticks - 1
