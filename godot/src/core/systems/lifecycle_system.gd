extends RefCounted
## LifecycleSystem v2 (buoc 11, P2-C1). Chay sau moi step KHONG paused; Sim da tang state.steps o buoc 2,
## nen state.steps = so sim tick DA hoan tat tinh ca tick nay.
## Thu tu (ticket win_lose): 1) flames <= 0 -> lost/no_flames (luon uu tien)
##                           2) moi den sang -> won/all_lit (ke ca dung tick het gio)
##                           3) het gio -> lost/dawn.
## Bonus thang (1 lan): floor(giay con lai) * SCORE_PER_SECOND_LEFT(2) + SCORE_PER_FLAME_LEFT(50) * flames.
## Tong tick cua Dem: GameConfig.night_duration_ticks(night) (18000/19800/21600); scenario doi time_left_s
## thi = ceil(time_left_initial * 60). game_over phat dung 1 lan (status het "playing" thi khong lam gi).
## Diem per_mote (10) cong luc NHAT (mote_system), quyet dinh Product Owner (requests R1) - khong o day.

static func ticks_total(state: SimState) -> int:
	if is_equal_approx(state.time_left_initial, GameConfig.night_duration_s(state.night)):
		return GameConfig.night_duration_ticks(state.night)
	return int(ceil(state.time_left_initial * float(GameConfig.TICK_RATE) - 1e-6))

## So tick con lai sau tick hien tai (state.steps da gom tick nay).
static func ticks_left(state: SimState) -> int:
	return maxi(0, ticks_total(state) - state.steps)

static func all_lit(state: SimState) -> bool:
	if state.lanterns.is_empty():
		return false
	for l in state.lanterns:
		if not l["lit"]:
			return false
	return true

static func win_bonus(state: SimState) -> int:
	var secs := int(floor(float(ticks_left(state)) / float(GameConfig.TICK_RATE)))
	return GameConfig.SCORE_PER_SECOND_LEFT * secs + GameConfig.SCORE_PER_FLAME_LEFT * int(state.player["flames"])

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	if int(state.player["flames"]) <= 0:
		state.status = "lost"
		state.loss_reason = "no_flames"
		events.append({"name": "game_over", "data": {"result": "lost", "reason": "no_flames"}})
	elif all_lit(state):
		state.status = "won"
		state.loss_reason = ""
		state.score += win_bonus(state)
		events.append({"name": "game_over", "data": {"result": "won", "reason": "all_lit"}})
	elif ticks_total(state) - state.steps <= 0:
		state.status = "lost"
		state.loss_reason = "dawn"
		events.append({"name": "game_over", "data": {"result": "lost", "reason": "dawn"}})
