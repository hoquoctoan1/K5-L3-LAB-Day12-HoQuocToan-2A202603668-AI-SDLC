extends RefCounted
## Chay cuoi moi Sim step, truoc khi Sim tang steps. Thang > no_flames > dawn.

static func _ticks_total(state: SimState) -> int:
	return int(ceil(state.time_left_initial * 60.0 - 1e-6))

## Thoi gian con lai sau khi hoan tat step hien tai (steps+1).
static func time_left_after(state: SimState) -> float:
	return state.time_left_initial - float(state.steps + 1) / 60.0

static func _all_lit(state: SimState) -> bool:
	if state.lanterns.is_empty():
		return false
	var n := 0
	for l in state.lanterns:
		if l["lit"]:
			n += 1
	return n >= GameConfig.LANTERN_COUNT_NIGHT1 or n == state.lanterns.size()

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing":
		return
	var remaining_ticks: int = _ticks_total(state) - (state.steps + 1)
	if _all_lit(state):
		state.status = "won"
		state.loss_reason = ""
		var secs := int(floor(maxf(0.0, float(remaining_ticks) / 60.0)))
		state.score += GameConfig.SCORE_PER_FLAME_LEFT * int(state.player["flames"]) \
			+ GameConfig.SCORE_PER_SECOND_LEFT * secs
		events.append({"name": "game_over", "data": {"result": "won", "reason": "all_lit"}})
	elif int(state.player["flames"]) <= 0:
		state.status = "lost"
		state.loss_reason = "no_flames"
		events.append({"name": "game_over", "data": {"result": "lost", "reason": "no_flames"}})
	elif remaining_ticks <= 0:
		state.status = "lost"
		state.loss_reason = "dawn"
		events.append({"name": "game_over", "data": {"result": "lost", "reason": "dawn"}})
