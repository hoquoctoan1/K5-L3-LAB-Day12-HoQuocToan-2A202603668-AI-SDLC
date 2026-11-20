extends RefCounted

const Charm = preload("res://src/core/systems/charm_system.gd")

func _mk() -> SimState:
	var s := SimState.new()
	s.night = 2
	s.player = SimState.make_default_player()
	s.map = {"charm_positions": [Vector3(35, 0, 0), Vector3(-30, 0, 25)]}
	return s

func run(t: TS) -> void:
	var s := _mk()
	var ev := []
	Charm.step(s, {}, ev)
	t.eq(s.charms.size(), 2, "khoi tao tu map")
	t.eq([s.charms[0]["id"], s.charms[1]["id"]], ["C1", "C2"], "ids")
	t.ok(s.charms[0]["available"], "available")
	t.eq(ev.size(), 0, "xa: khong nhat")
	s.player["pos"] = Vector3(35, 1.6, 0)
	Charm.step(s, {}, ev)
	t.eq(ev.size(), 0, "dy 1.6: khong nhat")
	s.player["pos"] = Vector3(36.01, 0, 0)
	Charm.step(s, {}, ev)
	t.eq(ev.size(), 0, "XZ 1.01: khong nhat")
	s.player["fall_wait_ticks"] = 10
	s.player["pos"] = Vector3(35, 0, 0)
	Charm.step(s, {}, ev)
	t.eq(ev.size(), 0, "fall wait: khong nhat")
	s.player["fall_wait_ticks"] = 0
	s.player["pos"] = Vector3(36.0, 1.5, 0)
	Charm.step(s, {}, ev)
	t.eq(ev.size(), 1, "bien 1.0/1.5 nhat duoc")
	t.eq(ev[0], {"name": "charm_picked", "data": {"charm_id": "C1", "charm_ticks": 600}}, "event")
	t.eq(s.player["charm_ticks"], 600, "charm_ticks 600")
	t.ok(not s.charms[0]["available"], "unavailable")
	t.eq(s.charms[0]["respawn_ticks"], 2700, "respawn 2700")
	Charm.step(s, {}, ev)
	t.eq(ev.size(), 1, "khong nhat lai")
	t.eq(s.charms[0]["respawn_ticks"], 2699, "dem giam")
	s.player["pos"] = Vector3(0, 0, 0)
	for i in range(2698):
		Charm.step(s, {}, ev)
	t.ok(not s.charms[0]["available"], "chua hoi o tick 2699")
	Charm.step(s, {}, ev)
	t.ok(s.charms[0]["available"], "hoi o tick 2700")
	t.eq(s.charms[0]["respawn_ticks"], 0, "respawn 0")
	s.player["charm_ticks"] = 100
	s.player["pos"] = Vector3(35, 0, 0)
	Charm.step(s, {}, ev)
	t.eq(s.player["charm_ticks"], 600, "refresh 600")
	var rt: int = s.charms[0]["respawn_ticks"]
	s.paused = true
	var n := ev.size()
	Charm.step(s, {}, ev)
	t.eq(s.charms[0]["respawn_ticks"], rt, "paused: dem dung yen")
	t.eq(ev.size(), n, "paused: khong event")
	var s2 := _mk()
	s2.charms = [SimState.make_charm("C9", Vector3(1, 0, 1))]
	Charm.step(s2, {}, [])
	t.eq(s2.charms.size(), 1, "scenario charms thay mac dinh")
