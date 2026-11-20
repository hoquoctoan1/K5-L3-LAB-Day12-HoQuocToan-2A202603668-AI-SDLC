extends RefCounted
const PS = preload("res://src/core/systems/player_system.gd")
const JP = preload("res://src/core/systems/jump_pad_system.gd")
const MapBuilder = preload("res://src/core/maps/map_builder.gd")

func _st(night: int, pos: Vector3) -> SimState:
	var s := SimState.new()
	s.night = night
	s.map = MapBuilder.build(night)
	s.player = SimState.make_default_player()
	s.player["pos"] = pos
	return s

func _tick(s: SimState, inp: Dictionary, ev: Array) -> void:
	PS.step(s, inp, ev)
	JP.step(s, inp, ev)

func _pad(i: int) -> Vector3:
	return Vector3(20, 0, 18) if i == 0 else Vector3(50, 0, -18)

func run(t: TS) -> void:
	var idle := {"move": Vector2.ZERO}
	for i in 2:
		var s := _st(2, _pad(i))
		var ev := []
		_tick(s, idle, ev)
		t.ok(s.player["launched"], "pad %d bat" % i)
		var n := 0
		while s.player["launched"] and n < 300:
			_tick(s, {"move": Vector2(-1, 0)}, ev)  # phim nguoc khong ghi de
			n += 1
		t.ok(absi(n - 84) <= 3, "bay ~1.4 s (tick %d)" % n)
		var isl: Dictionary = s.map["islands"][1 - i]
		var pp: Vector3 = s.player["pos"]
		var d := Vector2(pp.x - isl["center"].x, pp.z - isl["center"].z).length()
		t.ok(d < float(isl["radius"]), "dap trong dao dich pad %d (d=%f)" % [i, d])
		t.ok(s.player["grounded"], "da cham dat")
		t.eq(s.player["flames"], 3, "khong mat lua")
	# luot trong luc bay
	var s2 := _st(2, _pad(0))
	var ev2 := []
	_tick(s2, idle, ev2)
	_tick(s2, {"move": Vector2.ZERO, "dash": true}, ev2)
	t.ok(ev2.size() == 1 and ev2[0]["name"] == "dash", "luot duoc khi bay")
	# dem 3: buc -> tang 2
	var s3 := _st(3, Vector3(0, 3, 13))
	var ev3 := []
	_tick(s3, idle, ev3)
	var n3 := 0
	while s3.player["launched"] and n3 < 300:
		_tick(s3, idle, ev3)
		n3 += 1
	var p3: Vector3 = s3.player["pos"]
	t.near(p3.y, 6.0, "dem 3 dap tang 2", 0.01)
	t.ok(Vector2(p3.x, p3.z).length() < 8.0, "trong dia tang 2")
	# xa buc khong bat
	var s4 := _st(2, Vector3(5, 0, 5))
	_tick(s4, idle, [])
	t.ok(not s4.player["launched"], "xa buc khong bat")
