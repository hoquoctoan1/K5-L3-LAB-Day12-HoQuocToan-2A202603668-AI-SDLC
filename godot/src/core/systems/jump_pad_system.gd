extends RefCounted
## Bục nhảy (sau di chuyen, buoc 3). Chan cham bục khi dang dung dat -> bat: vy + van toc ngang
## giu toi khi cham dat (PlayerSystem dung p["launch_vel"] khi p["launched"]).

const MapGeometry = preload("res://src/core/maps/map_geometry.gd")

static func step(state: SimState, _input: Dictionary, _events: Array) -> void:
	if state.paused or state.status != "playing" or state.map.is_empty() or not state.map.has("jump_pads"):
		return
	var p: Dictionary = state.player
	if p["launched"] or int(p["fall_wait_ticks"]) > 0 or not p["grounded"]:
		return
	var i := MapGeometry.jump_pad_at(state.map, p["pos"])
	if i < 0:
		return
	var pd: Dictionary = state.map["jump_pads"][i]
	var d: Vector3 = pd["direction"]
	var lv := Vector2(d.x, d.z).normalized() * float(pd["launch_horizontal"])
	var vel: Vector3 = p["vel"]
	vel = Vector3(lv.x, float(pd["launch_vy"]), lv.y)
	p["vel"] = vel
	p["launch_vel"] = lv
	p["launched"] = true
	p["grounded"] = false
	p["on_ground"] = false
	p["vy"] = vel.y
