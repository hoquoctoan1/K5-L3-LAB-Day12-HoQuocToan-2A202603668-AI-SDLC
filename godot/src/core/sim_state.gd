class_name SimState
extends RefCounted
## Trang thai mo phong v2 (contract v1.2). DONG BANG boi A0-P2, mo rong boi A0-P3: chi A0 sua file nay.
## Chi tiet + danh dau ASSUMPTION: godot/src/core/interfaces_v2.md.
## Truong "LEGACY" chi de he thong Phase 1 con chay; owner xoa khi viet lai (xem interfaces_v2.md).

# --- thoi gian ---
var tick: int = 0                 # tang MOI Sim.step, ke ca luc paused
var steps: int = 0                # = sim_tick: chi tang khi KHONG paused
var sim_ticks: int:               # alias cua steps
	get: return steps
	set(v): steps = v
var paused: bool = false
var night: int = 1                # 1..3
var status: String = "playing"    # playing | won | lost  (snapshot them "paused")
var loss_reason: String = ""      # no_flames | dawn | "" (thang: dawn_survived, xem lifecycle)
var time_left_initial: float = 300.0
var score: int = 0

## player (khoa v2):
##  pos Vector3, vel Vector3, grounded bool, facing Vector2 (XZ, don vi; mac dinh +Z=(0,1)),
##  flames int, carried int, invuln_ticks int, dash_cd_ticks int, dash_ticks_left int,
##  dash_dir Vector2, pulse_cd_ticks int, charm_ticks int, fall_wait_ticks int (>0 = dang cho hoi sinh),
##  launched bool (dang bay do bục nhảy: giu van toc toi khi cham dat),
##  successful_lights int (v1.2: so lan thap thanh cong trong Dem, ke ca thap lai; den dat san bang scenario KHONG tinh)
## LEGACY (Phase 1): vy, on_ground, invuln_left (s), pulse_cd_left (s)
var player: Dictionary = {}
## lanterns: [{id "L1".., pos Vector3, lit bool, deposited int, safe_timer int,
##   v1.2: fuel_units int (1 unit = 1/60 fuel; 0..GameConfig.FUEL_MAX_UNITS; den tat = 0),
##         ever_lit bool (da tung sang), relit_count int (so lan thap lai)}]
var lanterns: Array = []
## motes: [{id "m1".., pos Vector3, kind "random"|"dropped", ttl_ticks int (-1 = vo han), point_index int (-1 = khong co)}]
var motes: Array = []
## shades: [{id "S1".., pos Vector3, state "spawning|wander|chase|recoil|stunned|drain", state_ticks_left int,
##   knock_dir Vector2, knock_ticks_left int, recoil_dir Vector2, safe_push_ticks int,
##   v1.2: target_lantern_id String ("" = khong co), drain_ticks int (so tick da hut lien tuc, cho fuel_drain moi 60 tick),
##   LEGACY stun_left float (s)}]
var shades: Array = []
## drifters: [{id "D1".., pos Vector3, state "idle|chase|flee|removed", stolen int, has_stolen bool,
##   flee_ticks_left int, flee_dir Vector2, drop_after_ticks int}]
var drifters: Array = []
## charms: [{id "C1".., pos Vector3, available bool, respawn_ticks int}]
var charms: Array = []
## wind: {active bool, dir_deg float, ticks_left int (con lai khi active), next_ticks int (den lan gio ke), warn_ticks int (>0 = dang bao truoc)}
var wind: Dictionary = {}
## map: MapData (xem interfaces_v2.md). {} = Phase-1 fallback: dao tron ban kinh GameConfig.ISLAND_RADIUS, y=0.
var map: Dictionary = {}
## Tuy chon: Callable(x: float, z: float, from_y: float) -> float do module map (P2-B1) gan.
var map_height_fn: Callable = Callable()

var random_motes: bool = true
var random_shades: bool = true
var random_drifters: bool = true
var wind_enabled: bool = true
var next_mote_id: int = 1
var next_shade_id: int = 1
var next_drifter_id: int = 1
var next_charm_id: int = 1
var spawn_timer_s: float = 0.0           # LEGACY (spawn shade Phase 1)
var mote_respawn_ticks_left: int = 0
## dem tick cho lich spawn v2 (do B5/B6/B3 dung; dem theo sim_ticks, dung khi paused)
var shade_spawn_ticks_left: int = GameConfig.SHADE_FIRST_SPAWN_TICK
var shade_first_spawned: bool = false
var shade_island_cursor: int = 0
var drifter_spawn_ticks_left: int = GameConfig.DRIFTER_SPAWN_EVERY_TICKS
## "Rng chinh" duoc seed tu --seed. Phase 1 dung rng cho mote/shade. v2: dung stream rieng ben duoi.
var rng: Rng = Rng.new(0)
var rng_mote: Rng = Rng.new(0)
var rng_shade: Rng = Rng.new(0)
var rng_drifter: Rng = Rng.new(0)
var rng_wind: Rng = Rng.new(0)
## Cho tam theo he thong (tat dinh, khong vao snapshot).
var extras: Dictionary = {}

const STREAM_SALTS := {"mote": 0x1001, "shade": 0x2002, "drifter": 0x3003, "wind": 0x4004}

func time_left_s() -> float:
	return maxf(0.0, time_left_initial - float(steps) * GameConfig.DT)

## Tao cac stream phu tu seed (tat dinh): seed_stream = Rng(seed ^ salt).next_u32().
func seed_streams(seed_value: int) -> void:
	rng = Rng.new(seed_value)
	rng_mote = Rng.new(Rng.new(seed_value ^ STREAM_SALTS["mote"]).next_u32())
	rng_shade = Rng.new(Rng.new(seed_value ^ STREAM_SALTS["shade"]).next_u32())
	rng_drifter = Rng.new(Rng.new(seed_value ^ STREAM_SALTS["drifter"]).next_u32())
	rng_wind = Rng.new(Rng.new(seed_value ^ STREAM_SALTS["wind"]).next_u32())

## Do cao nen tai (x,z). VOID (= roi) khi ngoai moi dao/doc/cau. from_y: chon be mat cao nhat <= from_y + 0.5.
const VOID_Y: float = -1.0e9
func height_at(x: float, z: float, from_y: float = 1.0e9) -> float:
	if map_height_fn.is_valid():
		return float(map_height_fn.call(x, z, from_y))
	if Vector2(x, z).length() <= GameConfig.island_radius(night) + 1e-4:
		return 0.0
	return VOID_Y

## --- helper v1.2 (nhien lieu, suc chua) ---
## Suc chua hien tai = 10 + 2 * successful_lights, toi da 20.
static func capacity_of(player_: Dictionary) -> int:
	return mini(GameConfig.CAPACITY_MAX,
		GameConfig.CARRY_CAPACITY + GameConfig.CAPACITY_PER_LIGHT * int(player_.get("successful_lights", 0)))

func capacity() -> int:
	return capacity_of(player)

## Nhien lieu (don vi fuel, so thuc) cua den; den tat = 0.
static func fuel_of(lantern: Dictionary) -> float:
	if not lantern.get("lit", false):
		return 0.0
	return float(int(lantern.get("fuel_units", 0))) / float(GameConfig.FUEL_UNITS_PER_FUEL)

## Den sang va fuel < 30 (mat vung an toan, Bong Muc wander nham toi). Dung 30 KHONG yeu.
static func is_low_fuel(lantern: Dictionary) -> bool:
	return lantern.get("lit", false) and int(lantern.get("fuel_units", 0)) < GameConfig.LOW_FUEL_UNITS

## Den co vung an toan: dang sang va fuel >= 30.
static func has_safe_zone(lantern: Dictionary) -> bool:
	return lantern.get("lit", false) and int(lantern.get("fuel_units", 0)) >= GameConfig.LOW_FUEL_UNITS

## Xuat fuel 1 chu so thap phan [GIA DINH Q6]: round_half_up(units / 6) / 10, bang so nguyen. Den tat = 0.0.
static func fuel_out(lantern: Dictionary) -> float:
	if not lantern.get("lit", false):
		return 0.0
	var tenths: int = int((int(lantern.get("fuel_units", 0)) * 10 + 30) / 60)
	return float(tenths) / 10.0

static func make_default_wind() -> Dictionary:
	return {"active": false, "dir_deg": 0.0, "ticks_left": 0,
		"next_ticks": GameConfig.WIND_EVERY_TICKS, "warn_ticks": 0}

static func make_default_player() -> Dictionary:
	return {
		"pos": Vector3.ZERO, "vel": Vector3.ZERO, "grounded": true,
		"facing": Vector2(0.0, 1.0), "flames": GameConfig.FLAMES, "carried": 0,
		"invuln_ticks": 0, "dash_cd_ticks": 0, "dash_ticks_left": 0, "dash_dir": Vector2(0.0, 1.0),
		"pulse_cd_ticks": 0, "charm_ticks": 0, "fall_wait_ticks": 0, "launched": false,
		"successful_lights": 0,
		# LEGACY Phase 1
		"vy": 0.0, "on_ground": true, "invuln_left": 0.0, "pulse_cd_left": 0.0,
	}

static func make_mote(id: String, pos: Vector3, kind: String = "random", ttl_ticks: int = -1, point_index: int = -1) -> Dictionary:
	return {"id": id, "pos": pos, "kind": kind, "ttl_ticks": ttl_ticks, "point_index": point_index}

static func make_shade(id: String, pos: Vector3, state: String = "chase") -> Dictionary:
	return {"id": id, "pos": pos, "state": state, "state_ticks_left": 0,
		"knock_dir": Vector2.ZERO, "knock_ticks_left": 0, "recoil_dir": Vector2.ZERO,
		"safe_push_ticks": 0, "target_lantern_id": "", "drain_ticks": 0, "stun_left": 0.0}

static func make_drifter(id: String, pos: Vector3, state: String = "idle") -> Dictionary:
	return {"id": id, "pos": pos, "state": state, "stolen": 0, "has_stolen": false,
		"flee_ticks_left": 0, "flee_dir": Vector2.ZERO, "drop_after_ticks": 0}

static func make_charm(id: String, pos: Vector3) -> Dictionary:
	return {"id": id, "pos": pos, "available": true, "respawn_ticks": 0}

static func make_lantern(id: String, pos: Vector3) -> Dictionary:
	return {"id": id, "pos": pos, "lit": false, "deposited": 0, "safe_timer": 0,
		"fuel_units": 0, "ever_lit": false, "relit_count": 0}
