extends RefCounted
## Sim v2 (contract v1.1, P2-C1): ghep cac system theo 12 buoc tick cua TICKET-02. Thuan, tat dinh.
##
## API (headless_runner / scenario_loader / main.gd dua vao):
##   Sim.new(seed:int = 0, night:int = 1)  -> state co map Dem `night`, lanterns (scenario_loader can lantern id).
##   .state: SimState
##   .begin()      idempotent; tu goi o step() dau. Sinh 20 mote ngau nhien (neu random_motes va motes rong),
##                 khoi tao charm tu map (neu charms rong). Shade KHONG sinh o begin (2 con tai tick 300).
##   .step(frame) -> Array[{name,data,tick}]   (tick = state.tick sau khi tang)
##   .reset(seed:int = -1, night:int = -1)     ve trang thai ban dau (giu seed/night cu neu -1).
## Event `night_start{night}` la event DAU TIEN cua step dau tien (ke ca khi step do la pause).
##
## Thu tu 1 step (interfaces_v2.md muc 8):
##  1  input: pause (canh len) xu ly truoc. Dang chay + pause -> paused=true, event paused, DUNG tai day.
##     Dang paused + pause -> paused=false, event resumed, chay tiep buoc 2..11 trong CUNG step.
##     Dang paused, khong pause -> dung. Khi dung: state.tick van +1; steps/thoi gian/bo dem/spawn/TTL/rng dung yen.
##  2  bo dem: state.steps += 1 (thoi gian). Cac bo dem con lai do chinh system so huu giam (1 lan/tick):
##       wind (WindSystem), player invuln/dash_cd/pulse_cd/charm/fall_wait/dash_ticks (PlayerSystem),
##       mote TTL (MoteSystem), charm respawn (CharmSystem), shade stun/recoil/spawning/knock/safe_push (ShadeSystem),
##       drifter flee/drop (DrifterSystem). CharmSystem.decrement_player_charm KHONG goi (PlayerSystem da giam).
##  3  WindSystem -> PlayerSystem (chay/nhay/luot/gio + kiem tra roi) -> JumpPadSystem
##  4  MoteSystem (nhat) -> CharmSystem (nhat)
##  5  LanternSystem._interact
##  6  vung an toan: do ShadeSystem lam (day ra toi da 30 tick + safe_push_ticks chan hit). LanternSystem._safe_zone
##     KHONG goi vi trung lap (giam safe_push_ticks 2 lan/tick) - xem docs/notes/requests.md R9.
##  7  PulseSystem
##  8-9 DrifterSystem (di chuyen + CUOP, roi tu sinh drifter = buoc 10 cua no) -> ShadeSystem (di chuyen + HIT).
##     Tuong duong 8,8,9,9: di chuyen drifter/shade doc lap nhau; cuop xay ra truoc hit (ticket).
##  10 SpawnSystem (shade + mote theo lich). The moi chi tuong tac tu tick sau (shade "spawning", mote nhat o buoc 4).
##  11 LifecycleSystem (no_flames > all_lit > dawn)
##  12 snapshot: viec cua headless_runner.

const MapBuilder = preload("res://src/core/maps/map_builder.gd")
const MapGeometry = preload("res://src/core/maps/map_geometry.gd")
const PlayerSys = preload("res://src/core/systems/player_system.gd")
const JumpPadSys = preload("res://src/core/systems/jump_pad_system.gd")
const WindSys = preload("res://src/core/systems/wind_system.gd")
const MoteSys = preload("res://src/core/systems/mote_system.gd")
const CharmSys = preload("res://src/core/systems/charm_system.gd")
const LanternSys = preload("res://src/core/systems/lantern_system.gd")
const PulseSys = preload("res://src/core/systems/pulse_system.gd")
const ShadeSys = preload("res://src/core/systems/shade_system.gd")
const DrifterSys = preload("res://src/core/systems/drifter_system.gd")
const SpawnSys = preload("res://src/core/systems/spawn_system.gd")
const LifecycleSys = preload("res://src/core/systems/lifecycle_system.gd")

var state: SimState
var seed_value: int = 0
var night: int = 1
var begun: bool = false
var night_started: bool = false

func _init(seed: int = 0, night_: int = 1) -> void:
	night = clampi(night_, 1, 3)
	reset(seed)

## Ham do cao cho SimState.height_at (drifter dung) theo map that (Dem 2 co 2 dao + cau).
## Lambda tao trong ham static => khong giu tham chieu toi Sim/SimState (tranh vong tham chieu).
static func _height_fn(m: Dictionary) -> Callable:
	return func(x: float, z: float, from_y: float) -> float:
		var h := MapGeometry.ground_height(m, x, z, from_y)
		return SimState.VOID_Y if is_nan(h) else h

## Dua ve trang thai ban dau (replay). Scenario phai ap lai sau reset.
func reset(seed: int = -1, night_: int = -1) -> void:
	if seed >= 0:
		seed_value = seed
	if night_ >= 1 and night_ <= 3:
		night = night_
	state = SimState.new()
	state.night = night
	state.seed_streams(seed_value)
	state.player = SimState.make_default_player()
	state.wind = SimState.make_default_wind()
	state.time_left_initial = GameConfig.night_duration_s(night)
	state.map = MapBuilder.build(night)
	state.map_height_fn = _height_fn(state.map)
	if state.map.has("start"):
		state.player["pos"] = state.map["start"]["pos"]
	begun = false
	night_started = false
	# chi lanterns (khong tieu thu rng)
	var r := state.random_motes
	state.random_motes = false
	SpawnSys.populate_initial(state)
	state.random_motes = r

func begin() -> void:
	if begun:
		return
	begun = true
	var rm := state.random_motes
	state.random_motes = rm and state.motes.is_empty()
	SpawnSys.populate_initial(state)
	state.random_motes = rm
	if not state.extras.has("charms_init"):
		CharmSys.init_charms(state)

func step(frame: Dictionary) -> Array:
	begin()
	var events: Array = []
	if state.status != "playing":
		return events
	state.tick += 1
	if not night_started:
		night_started = true
		events.append({"name": "night_start", "data": {"night": state.night}})
	# 1. input: pause truoc
	if frame.get("pause", false):
		if state.paused:
			state.paused = false
			events.append({"name": "resumed", "data": {}})
		else:
			state.paused = true
			events.append({"name": "paused", "data": {}})
			return _stamp(events)
	elif state.paused:
		return _stamp(events)
	# 2. thoi gian (cac bo dem khac: trong system so huu, xem dau file)
	state.steps += 1
	# 3. di chuyen May
	WindSys.step(state, frame, events)
	PlayerSys.step(state, frame, events)
	JumpPadSys.step(state, frame, events)
	# 4. nhat mote, bua
	MoteSys.step(state, frame, events)
	CharmSys.step(state, frame, events)
	# 5. den  (6. vung an toan: ShadeSystem)
	LanternSys._interact(state, frame, events)
	# 7. Toa Sang
	PulseSys.step(state, frame, events)
	# 8-9. di chuyen + cham: Gio Lac cuop truoc, Bong Muc hit sau
	DrifterSys.step(state, frame, events)
	ShadeSys.step(state, frame, events)
	# 10. sinh theo lich
	SpawnSys.step(state, frame, events)
	# 11. thang/thua
	LifecycleSys.step(state, frame, events)
	return _stamp(events)

func _stamp(events: Array) -> Array:
	for ev in events:
		ev["tick"] = state.tick
	return events
