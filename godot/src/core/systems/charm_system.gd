extends RefCounted
## CharmSystem (P2-B6): Bua Gio. step = buoc 2 (hoi bua) roi buoc 4 (nhat). Goi 1 lan/tick.
## state.charms [{id,pos,available,respawn_ticks}]. Khoi tao lazy tu map.charm_positions neu rong
## (extras["charms_init"] tranh tao lai; scenario co charms[] thi giu nguyen).
## KHONG giam player.charm_ticks trong step (de player_system/sim giam o buoc 2); co decrement_player_charm() neu can.

static func init_charms(state: SimState) -> void:
	state.extras["charms_init"] = true
	if not state.charms.is_empty():
		return
	for p in state.map.get("charm_positions", []):
		state.charms.append(SimState.make_charm("C%d" % state.next_charm_id, p))
		state.next_charm_id += 1

static func decrement_player_charm(state: SimState) -> void:
	state.player["charm_ticks"] = maxi(0, int(state.player["charm_ticks"]) - 1)

static func step(state: SimState, _input: Dictionary, events: Array) -> void:
	if state.paused or state.status != "playing":
		return
	if not state.extras.has("charms_init"):
		init_charms(state)
	for c in state.charms:
		if not bool(c["available"]):
			c["respawn_ticks"] = maxi(0, int(c["respawn_ticks"]) - 1)
			if int(c["respawn_ticks"]) == 0:
				c["available"] = true
	var p: Dictionary = state.player
	if int(p.get("fall_wait_ticks", 0)) > 0:
		return
	for c in state.charms:
		if not bool(c["available"]):
			continue
		var d: Vector3 = c["pos"] - p["pos"]
		if Vector2(d.x, d.z).length() <= GameConfig.PICKUP_RADIUS and absf(d.y) <= GameConfig.PICKUP_MAX_DY:
			c["available"] = false
			c["respawn_ticks"] = GameConfig.CHARM_RESPAWN_TICKS
			p["charm_ticks"] = GameConfig.CHARM_DURATION_TICKS
			events.append({"name": "charm_picked", "data": {"charm_id": c["id"], "charm_ticks": GameConfig.CHARM_DURATION_TICKS}})
