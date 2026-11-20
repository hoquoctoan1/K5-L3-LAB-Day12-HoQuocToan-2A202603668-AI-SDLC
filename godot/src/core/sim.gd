extends RefCounted
## Sim: ghep cac system theo thu tu co dinh. Thuan, tat dinh.
## Thiet ke khoi tao: _init chi tao lanterns (khong mote/shade, khong dung rng).
## begin() (idempotent, tu goi o step() dau tien; runner goi sau khi ap scenario) moi sinh
## mote/shade ngau nhien: chi sinh khi random_* = true VA danh sach tuong ung dang rong
## (scenario co liet ke thi giu nguyen). Vi vay random_*=false => dung danh sach scenario.
## Rng chi bi tieu thu o begin()/step(), nen ket qua chi phu thuoc seed + scenario + inputs.

const PlayerSys = preload("res://src/core/systems/player_system.gd")
const MoteSys = preload("res://src/core/systems/mote_system.gd")
const LanternSys = preload("res://src/core/systems/lantern_system.gd")
const PulseSys = preload("res://src/core/systems/pulse_system.gd")
const ShadeSys = preload("res://src/core/systems/shade_system.gd")
const SpawnSys = preload("res://src/core/systems/spawn_system.gd")
const LifecycleSys = preload("res://src/core/systems/lifecycle_system.gd")

var state: SimState
var seed_value: int = 0
var begun: bool = false

func _init(seed: int = 0) -> void:
	reset(seed)

## Dua ve trang thai ban dau (de replay). Scenario phai ap lai sau reset.
func reset(seed: int = -1) -> void:
	if seed >= 0:
		seed_value = seed
	state = SimState.new()
	state.rng = Rng.new(seed_value)
	state.player = SimState.make_default_player()
	state.time_left_initial = GameConfig.NIGHT1_DURATION_S
	begun = false
	var r := state.random_motes
	var s := state.random_shades
	state.random_motes = false
	state.random_shades = false
	SpawnSys.populate_initial(state)   # chi lanterns
	state.random_motes = r
	state.random_shades = s

func begin() -> void:
	if begun:
		return
	begun = true
	var rm := state.random_motes
	var rs := state.random_shades
	state.random_motes = rm and state.motes.is_empty()
	state.random_shades = rs and state.shades.is_empty()
	SpawnSys.populate_initial(state)
	state.random_motes = rm
	state.random_shades = rs

func step(frame: Dictionary) -> Array:
	begin()
	var events: Array = []
	if state.status != "playing":
		return events
	PlayerSys.step(state, frame, events)
	MoteSys.step(state, frame, events)
	LanternSys.step(state, frame, events)
	PulseSys.step(state, frame, events)
	ShadeSys.step(state, frame, events)
	SpawnSys.step(state, frame, events)
	LifecycleSys.step(state, frame, events)
	state.steps += 1
	state.tick = state.steps
	for ev in events:
		ev["tick"] = state.tick
	return events
