extends RefCounted
## LifecycleSystem v3 (buoc 11, P3-B3, contract v1.2 / TICKET-03 muc 3 + 5). Chay sau moi step KHONG paused;
## Sim da tang state.steps o buoc 2 nen state.steps = so sim tick DA hoan tat, tinh ca tick nay.
## Thu tu (ticket): 1) flames <= 0 -> lost/no_flames (ngay lap tuc, ke ca tick binh minh - luon uu tien)
##                  2) het gio (binh minh): so den DANG sang (sau buoc 2b cua tick cuoi) >= win_threshold(tong den)
##                     -> won/dawn_survived, nguoc lai lost/dawn.
## Khong con thang som: thap du den KHONG ket thuc Dem (v1.1 all_lit da bi THAY THE).
## Thuong binh minh (chi khi thang, 1 lan): moi den dang sang +50 + floor(fuel); moi Ngon Lua +50. Bo thuong thoi gian.
## Tong tick cua Dem: GameConfig.night_duration_ticks(night) (14400/16200/18000); scenario doi time_left_s
## thi = ceil(time_left_initial * 60). game_over phat dung 1 lan.

static func ticks_total(state: SimState) -> int:
	if is_equal_approx(state.time_left_initial, GameConfig.night_duration_s(state.night)):
		return GameConfig.night_duration_ticks(state.night)
	return int(ceil(state.time_left_initial * float(GameConfig.TICK_RATE) - 1e-6))

## So tick con lai sau tick hien tai (state.steps da gom tick nay).
static func ticks_left(state: SimState) -> int:
	return maxi(0, ticks_total(state) - state.steps)

static func lit_count(state: SimState) -> int:
	var n := 0
	for l in state.lanterns:
		if l["lit"]:
			n += 1
	return n

## Du dieu kien thang luc binh minh (chua tinh Ngon Lua).
static func enough_lit(state: SimState) -> bool:
	if state.lanterns.is_empty():
		return false
	return lit_count(state) >= GameConfig.win_threshold(state.lanterns.size())

## floor(fuel) bang so nguyen: fuel_units / 60.
static func win_bonus(state: SimState) -> int:
	var b := GameConfig.SCORE_PER_FLAME_LEFT * int(state.player["flames"])
	for l in state.lanterns:
		if l["lit"]:
			b += GameConfig.SCORE_PER_LIT_LANTERN_DAWN + int(int(l.get("fuel_units", 0)) / GameConfig.FUEL_UNITS_PER_FUEL)
	return b

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	if int(state.player["flames"]) <= 0:
		state.status = "lost"
		state.loss_reason = "no_flames"
		events.append({"name": "game_over", "data": {"result": "lost", "reason": "no_flames"}})
	elif ticks_total(state) - state.steps <= 0:
		if enough_lit(state):
			state.status = "won"
			state.loss_reason = ""
			state.score += win_bonus(state)
			events.append({"name": "game_over", "data": {"result": "won", "reason": "dawn_survived"}})
		else:
			state.status = "lost"
			state.loss_reason = "dawn"
			events.append({"name": "game_over", "data": {"result": "lost", "reason": "dawn"}})
