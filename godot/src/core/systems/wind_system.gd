extends RefCounted
## WindSystem (P2-B6): gio manh Dem 3. Goi 1 lan/tick (truoc player_system buoc 3).
## state.wind: {active, dir_deg, ticks_left, next_ticks, warn_ticks} + them (ASSUMPTION):
##   warning:bool (warn_ticks>0), push:Vector3 (m/s, XZ; ZERO khi khong active). Huong: deg tu +X nguoc chieu kim dong ho
##   trong mat phang XZ: push = (cos, 0, sin) * WIND_PUSH_MPS. player_system cong push*DT vao vi tri moi tick.
## Lich: start-to-start moi WIND_EVERY_TICKS; canh bao WIND_WARN_TICKS truoc; keo dai WIND_DURATION_TICKS.
## Gio bat dau o lan step thu 1800 (next_ticks dem 1800 -> 0). Huong lay tu rng_wind (1 lan/dot gio).

static func _reset(w: Dictionary) -> void:
	w["active"] = false
	w["ticks_left"] = 0
	w["warn_ticks"] = 0
	w["warning"] = false
	w["push"] = Vector3.ZERO

static func step(state: SimState, _input: Dictionary, _events: Array) -> void:
	if state.paused or state.status != "playing":
		return
	if state.wind.is_empty():
		state.wind = SimState.make_default_wind()
	var w: Dictionary = state.wind
	if not w.has("push"):
		_reset(w)
	if not (GameConfig.has_wind(state.night) and state.wind_enabled):
		_reset(w)
		return
	if bool(w["active"]):
		w["ticks_left"] = int(w["ticks_left"]) - 1
		if int(w["ticks_left"]) <= 0:
			w["active"] = false
			w["ticks_left"] = 0
			w["push"] = Vector3.ZERO
	w["next_ticks"] = int(w["next_ticks"]) - 1
	if int(w["next_ticks"]) <= 0:
		w["active"] = true
		w["ticks_left"] = GameConfig.WIND_DURATION_TICKS
		w["dir_deg"] = state.rng_wind.next_float() * 360.0
		w["next_ticks"] = GameConfig.WIND_EVERY_TICKS
	if bool(w["active"]):
		var a: float = deg_to_rad(float(w["dir_deg"]))
		w["push"] = Vector3(cos(a), 0.0, sin(a)) * GameConfig.WIND_PUSH_MPS
		w["warn_ticks"] = 0
	else:
		w["push"] = Vector3.ZERO
		var nt: int = int(w["next_ticks"])
		w["warn_ticks"] = nt if nt <= GameConfig.WIND_WARN_TICKS else 0
	w["warning"] = int(w["warn_ticks"]) > 0
