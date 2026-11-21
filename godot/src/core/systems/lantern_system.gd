extends RefCounted
## LanternSystem v3 (P3-B1, contract v1.2 / TICKET-03 muc 1).
## Dau tinh bang so nguyen "fuel units" (1 unit = 1/60 fuel; day = GameConfig.FUEL_MAX_UNITS = 6000).
##
## Buoc 2b - tick_fuel(state, events) (sim.gd goi ngay sau buoc 2):
##   moi den dang sang: tru FUEL_DECAY_UNITS_PER_TICK (1) + FUEL_DRAIN_UNITS_PER_TICK (5) x so Bong Muc
##   state "drain" co target_lantern_id = den do. Moi con hut: drain_ticks += 1; drain_ticks % 60 == 0 ->
##   event fuel_drain{lantern_id, shade_id, fuel} (fuel sau khi tru) [GIA DINH Q2].
##   fuel_units <= 0 -> tat: lit=false, deposited=0, fuel_units=0, ever_lit=true, event lantern_out{lantern_id}.
## Buoc 5 - _interact(state, input, events):
##   chi xet den "nhan duoc": chua sang, hoac sang va chua day dau. Gan nhat (XZ <= INTERACT_RADIUS), hoa -> id nho.
##   - den chua sang: nap min(carried, cost - deposited), cost = RELIGHT_COST (5) neu ever_lit, else LANTERN_COST (10);
##     event deposit; du cost -> sang, fuel = 100, successful_lights += 1,
##     lan dau: +SCORE_PER_LANTERN, lantern_lit{relight:false}; thap lai: +SCORE_PER_RELIGHT, relit_count += 1, relight:true.
##   - den dang sang chua day: used = min(carried, ceil((6000 - units) / 600)), units = min(6000, units + 600*used),
##     event refuel{lantern_id, amount, fuel} (khong phat deposit) [GIA DINH Q3].
##   Moi mote nap (ca 3 truong hop): +SCORE_PER_MOTE (5).
## Vung an toan: chi den SimState.has_safe_zone (sang va fuel >= 30). Day Bong Muc ra mep + khong gay sat thuong do
##   ShadeSystem lam (buoc 8); vi vay cham dau len >= 30 tu dong kich hoat lai co che day ra (ticket muc 2) [GIA DINH Q4].

const _ORDER_EPS := 1e-6

static func in_safe_zone(state: SimState, pos: Vector3) -> bool:
	for l in state.lanterns:
		if SimState.has_safe_zone(l) and Vector2(pos.x - l["pos"].x, pos.z - l["pos"].z).length() < GameConfig.SAFE_RADIUS - 1e-4:
			return true
	return false

## Den co nhan duoc mote khong (chua sang, hoac sang nhung chua day dau).
static func accepts(l: Dictionary) -> bool:
	return not l["lit"] or int(l.get("fuel_units", 0)) < GameConfig.FUEL_MAX_UNITS

## So mote can de thap den chua sang.
static func light_cost(l: Dictionary) -> int:
	return GameConfig.RELIGHT_COST if l.get("ever_lit", false) else GameConfig.LANTERN_COST

## Chi dung cho test don vi cu: buoc 5 + vung an toan (Sim KHONG goi step()).
static func step(state: SimState, input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	_interact(state, input, events)
	_safe_zone(state)

## Buoc 2b: hao dau + bi hut, roi tat den het dau.
static func tick_fuel(state: SimState, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	var order: Array = _shade_order(state)
	for l in state.lanterns:
		if not l["lit"]:
			continue
		var units: int = int(l.get("fuel_units", 0)) - GameConfig.FUEL_DECAY_UNITS_PER_TICK
		var drainers: Array = []
		for i in order:
			var s: Dictionary = state.shades[i]
			if str(s.get("state", "")) == "drain" and str(s.get("target_lantern_id", "")) == str(l["id"]):
				drainers.append(s)
		units -= GameConfig.FUEL_DRAIN_UNITS_PER_TICK * drainers.size()
		l["fuel_units"] = maxi(0, units)
		for s in drainers:
			s["drain_ticks"] = int(s.get("drain_ticks", 0)) + 1
			if int(s["drain_ticks"]) % GameConfig.FUEL_DRAIN_EVENT_EVERY_TICKS == 0:
				events.append({"name": "fuel_drain", "data": {"lantern_id": l["id"], "shade_id": s["id"], "fuel": SimState.fuel_out(l)}})
		if units <= 0:
			l["lit"] = false
			l["deposited"] = 0
			l["fuel_units"] = 0
			l["ever_lit"] = true
			events.append({"name": "lantern_out", "data": {"lantern_id": l["id"]}})

## Buoc 5: tuong tac den.
static func _interact(state: SimState, input: Dictionary, events: Array) -> void:
	if not input.get("interact", false):
		return
	var p: Dictionary = state.player
	if int(p["carried"]) <= 0 or int(p.get("fall_wait_ticks", 0)) > 0:
		return
	var best: Dictionary = {}
	var best_d := INF
	for l in state.lanterns:
		if not accepts(l):
			continue
		var d := Vector2(l["pos"].x - p["pos"].x, l["pos"].z - p["pos"].z).length()
		if d > GameConfig.INTERACT_RADIUS + 1e-4:
			continue
		if best.is_empty() or d < best_d - _ORDER_EPS or (absf(d - best_d) <= _ORDER_EPS and str(l["id"]) < str(best["id"])):
			best = l
			best_d = d
	if best.is_empty():
		return
	if best["lit"]:
		_refuel(state, best, events)
	else:
		_deposit(state, best, events)

static func _refuel(state: SimState, l: Dictionary, events: Array) -> void:
	var p: Dictionary = state.player
	var missing: int = GameConfig.FUEL_MAX_UNITS - int(l.get("fuel_units", 0))
	var need: int = int((missing + GameConfig.FUEL_UNITS_PER_MOTE - 1) / GameConfig.FUEL_UNITS_PER_MOTE)
	var used: int = mini(int(p["carried"]), need)
	if used <= 0:
		return
	p["carried"] = int(p["carried"]) - used
	l["fuel_units"] = mini(GameConfig.FUEL_MAX_UNITS, int(l["fuel_units"]) + GameConfig.FUEL_UNITS_PER_MOTE * used)
	state.score += GameConfig.SCORE_PER_MOTE * used
	events.append({"name": "refuel", "data": {"lantern_id": l["id"], "amount": used, "fuel": SimState.fuel_out(l)}})

static func _deposit(state: SimState, l: Dictionary, events: Array) -> void:
	var p: Dictionary = state.player
	var cost: int = light_cost(l)
	var amount := mini(int(p["carried"]), maxi(0, cost - int(l["deposited"])))
	if amount > 0:
		p["carried"] = int(p["carried"]) - amount
		l["deposited"] = int(l["deposited"]) + amount
		state.score += GameConfig.SCORE_PER_MOTE * amount
		events.append({"name": "deposit", "data": {"lantern_id": l["id"], "amount": amount, "deposited": l["deposited"]}})
	if int(l["deposited"]) < cost:
		return
	var relight: bool = l.get("ever_lit", false)
	l["lit"] = true
	l["fuel_units"] = GameConfig.FUEL_MAX_UNITS
	l["ever_lit"] = true
	p["successful_lights"] = int(p.get("successful_lights", 0)) + 1
	if relight:
		l["relit_count"] = int(l.get("relit_count", 0)) + 1
		state.score += GameConfig.SCORE_PER_RELIGHT
	else:
		state.score += GameConfig.SCORE_PER_LANTERN
	events.append({"name": "lantern_lit", "data": {"lantern_id": l["id"], "relight": relight}})

## Thu tu xu ly Bong Muc: tang dan theo hau to so cua id (giong ShadeSystem.order, khong preload de tranh vong).
static func _shade_order(state: SimState) -> Array:
	var keyed: Array = []
	for i in state.shades.size():
		var id := str(state.shades[i].get("id", ""))
		var n := int(id.substr(1)) if id.length() > 1 and id.substr(1).is_valid_int() else 0
		keyed.append([n, i])
	keyed.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out: Array = []
	for k in keyed:
		out.append(k[1])
	return out

## Chi dung cho test don vi cu (Sim dung vung an toan cua ShadeSystem). Chi den co vung an toan (fuel >= 30).
static func _safe_zone(state: SimState) -> void:
	var R: float = GameConfig.SAFE_RADIUS
	for s in state.shades:
		var inside_l: Dictionary = {}
		var inside_d := INF
		for l in state.lanterns:
			if not SimState.has_safe_zone(l):
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
