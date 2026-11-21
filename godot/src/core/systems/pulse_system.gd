class_name PulseSystem
extends RefCounted
## Toa Sang (buoc 7). Contract v1.1:
##  - can input.pulse (canh len), carried >= PULSE_COST, pulse_cd_ticks == 0, khong paused; neu khong: khong lam gi.
##  - tru PULSE_COST, dat pulse_cd_ticks = PULSE_COOLDOWN_TICKS.
##  - tam = chan May + (0, PULSE_CENTER_Y, 0); muc tieu chot tai tick nay: khoang cach 3D tu tam toi pos Bong Muc <= PULSE_RADIUS.
##  - moi muc tieu: state "stunned", state_ticks_left = PULSE_STUN_TICKS (lam moi neu dang choang),
##    knock_dir (XZ, ra xa tam; trung vi tri -> +X), knock_ticks_left = PULSE_KNOCK_TICKS.
##    Viec DI CHUYEN day lui (PULSE_PUSH_M / PULSE_KNOCK_TICKS moi tick, dung khi gap vat can) do shade_system lam o buoc 8.
##  - +SCORE_PER_STUN moi con moi lan (ke ca dang choang); v1.2: con dang "drain" -> tong +SCORE_PER_STUN_DRAIN (15).
##    Con bi choang roi drain: target_lantern_id = "", drain_ticks = 0. Khong giet.
##  - event pulse{stunned_ids} luon phat (co the rong).
## Gio Lac (drifter): drifter_system tu doc state.extras["pulse_tick"] (== state.tick khi pulse xay ra tick nay, else -1)
##  va state.extras["pulse_center"] (Vector3) roi tu xu ly; khong cong diem.

const _Shade = preload("res://src/core/systems/shade_system.gd")

static func step(state: SimState, input: Dictionary, events: Array) -> void:
	if state.status != "playing" or state.paused:
		return
	state.extras["pulse_tick"] = -1
	if not input.get("pulse", false):
		return
	var p: Dictionary = state.player
	if int(p["carried"]) < GameConfig.PULSE_COST or int(p["pulse_cd_ticks"]) > 0:
		return
	p["carried"] = int(p["carried"]) - GameConfig.PULSE_COST
	p["pulse_cd_ticks"] = GameConfig.PULSE_COOLDOWN_TICKS
	var ppos: Vector3 = p["pos"]
	var center := ppos + Vector3(0.0, GameConfig.PULSE_CENTER_Y, 0.0)
	state.extras["pulse_center"] = center
	state.extras["pulse_tick"] = state.tick
	# chot muc tieu truoc khi sua bat ky con nao
	var ids: Array = []
	for i in _Shade.order(state.shades):
		var s: Dictionary = state.shades[i]
		var spos: Vector3 = s["pos"]
		if spos.distance_to(center) > GameConfig.PULSE_RADIUS + 1e-4:
			continue
		var d := Vector2(spos.x - center.x, spos.z - center.z)
		var dir := Vector2(1.0, 0.0) if d.length() < 1e-6 else d.normalized()
		state.score += GameConfig.SCORE_PER_STUN_DRAIN if s["state"] == "drain" else GameConfig.SCORE_PER_STUN
		s["target_lantern_id"] = ""
		s["drain_ticks"] = 0
		s["state"] = "stunned"
		s["state_ticks_left"] = GameConfig.PULSE_STUN_TICKS
		s["knock_dir"] = dir
		s["knock_ticks_left"] = GameConfig.PULSE_KNOCK_TICKS
		s["_fresh"] = true   # shade_system khong tru tick choang trong tick nay
		ids.append(s["id"])
	events.append({"name": "pulse", "data": {"stunned_ids": ids}})
