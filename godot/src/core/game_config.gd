class_name GameConfig
extends RefCounted
## Nguon su that duy nhat cho tuning (Phase 3, contract v1.2, so chuan TICKET-03 tren nen TICKET-02).
## Phai khop game.contract.json (co test_config). Giu ten hang cu cua Phase 1 (alias).

const DT: float = 1.0 / 60.0
const TICK_RATE: int = 60
const CONTRACT_VERSION: String = "1.2"

# --- tuning cong khai trong contract ---
const PLAYER_SPEED: float = 6.0
const CARRY_CAPACITY: int = 10
const LANTERN_COST: int = 10
const LANTERN_COUNT_NIGHT1: int = 5
const PICKUP_RADIUS: float = 1.0          # XZ
const PICKUP_MAX_DY: float = 1.5          # |dy| toi da
const INTERACT_RADIUS: float = 2.0
const PULSE_COST: int = 3
const PULSE_RADIUS: float = 5.0           # 3D, tam = chan + PULSE_CENTER_Y
const PULSE_CENTER_Y: float = 0.8
const PULSE_COOLDOWN_TICKS: int = 180
const PULSE_COOLDOWN_S: float = 3.0
const PULSE_STUN_TICKS: int = 120
const PULSE_STUN_S: float = 2.0
const PULSE_KNOCK_TICKS: int = 15
const PULSE_PUSH_M: float = 4.0           # tong 4 m trong PULSE_KNOCK_TICKS tick
const NIGHT1_DURATION_S: float = 240.0      # v1.2 (TICKET-03 muc 3): 300 -> 240
const NIGHT2_DURATION_S: float = 270.0      # v1.2: 330 -> 270
const NIGHT3_DURATION_S: float = 300.0      # v1.2: 360 -> 300
const FLAMES: int = 3
const INVULN_TICKS: int = 90
const INVULN_S: float = 1.5
const HIT_DROP_RATIO: float = 0.5         # drop = floor(carried * ratio) = floor(carried/2)
const SAFE_RADIUS: float = 6.0
const SAFE_PUSH_MAX_TICKS: int = 30
const SHADE_SPEED: float = 4.0            # Dem 1 (alias); xem shade_speed(night)
const SHADE_SPEED_NIGHT1: float = 4.0
const SHADE_SPEED_NIGHT2: float = 4.0
const SHADE_SPEED_NIGHT3: float = 4.5
const SHADE_HIT_RADIUS: float = 1.0       # touch XZ
const SHADE_TOUCH_MAX_DY: float = 1.5
const SHADE_DETECT_M: float = 12.0
const SHADE_LOSE_INTEREST_M: float = 18.0
const SHADE_RECOIL_M: float = 2.0
const SHADE_RECOIL_TICKS: int = 60
const SHADE_SPAWN_MIN_PLAYER_DIST: float = 15.0
const FALL_ENABLED: bool = true           # ASSUMPTION: v1.1 co roi khoi dao (Phase 1 = false)
const FALL_Y: float = -10.0
const FALL_WAIT_TICKS: int = 60
const FALL_RESPAWN_INVULN_TICKS: int = 90

const DASH_SPEED: float = 14.0
const DASH_TICKS: int = 12
const DASH_DURATION_S: float = 0.2
const DASH_COOLDOWN_TICKS: int = 90
const DASH_COOLDOWN_S: float = 1.5

# --- nhien lieu den (v1.2, TICKET-03 muc 1-2) ---
# Don vi nguyen: 1 "fuel unit" = 1/60 fuel. Moi tinh toan dau dung so nguyen; chi lam tron khi xuat.
const FUEL_MAX: float = 100.0
const FUEL_DECAY_PER_S: float = 1.0
const FUEL_PER_MOTE: int = 10
const RELIGHT_COST: int = 5               # den ever_lit thap lai can 5 mote; den chua tung sang van LANTERN_COST
const WIN_RATIO: float = 0.6
const DRAIN_PER_S: float = 5.0            # moi Bong Muc dang drain; nhieu con cong don
const LOW_FUEL_THRESHOLD: float = 30.0    # fuel < 30: mat vung an toan, nhap nhay; dung 30 van con vung
const CAPACITY_MAX: int = 20
const CAPACITY_PER_LIGHT: int = 2         # suc chua = CARRY_CAPACITY + 2*successful_lights, toi da CAPACITY_MAX
const FUEL_UNITS_PER_FUEL: int = 60
const FUEL_MAX_UNITS: int = 6000                  # FUEL_MAX * 60
const FUEL_DECAY_UNITS_PER_TICK: int = 1          # 1.0/s = 1/60 fuel moi tick
const FUEL_DRAIN_UNITS_PER_TICK: int = 5          # 5/s = 5/60 fuel moi tick, moi con
const FUEL_UNITS_PER_MOTE: int = 600              # 10 fuel
const LOW_FUEL_UNITS: int = 1800                  # 30 fuel
const DRAIN_RANGE_M: float = 2.0          # XZ <= 2 m toi den muc tieu -> drain
const DRAIN_CHASE_M: float = 6.0          # dang drain, May vao trong 6 m -> chase
const FUEL_DRAIN_EVENT_EVERY_TICKS: int = 60   # [GIA DINH Q2] dem theo tung con tu luc vao drain

# --- diem (v1.2, TICKET-03 muc 5: THAY THE toan bo cong thuc cu) ---
const SCORE_PER_MOTE: int = 5             # moi mote NAP vao den (thap moi, thap lai, cham dau); KHONG cong khi nhat
const SCORE_PER_LANTERN: int = 100        # thap lan dau
const SCORE_PER_RELIGHT: int = 40         # thap lai
const SCORE_PER_STUN: int = 5             # moi Bong Muc trung Toa Sang
const SCORE_PER_STUN_DRAIN: int = 15      # tong diem neu con do dang drain ngay truoc khi trung
const SCORE_PER_LIT_LANTERN_DAWN: int = 50   # chi khi thang: moi den dang sang +50 + floor(fuel)
const SCORE_PER_FLAME_LEFT: int = 50      # chi khi thang
const SCORE_PER_SECOND_LEFT: int = 0      # LEGACY: thuong thoi gian da BO o v1.2; lifecycle (P3-B3) xoa cho dung

# --- hang so noi bo (khong thuoc contract) ---
const ISLAND_RADIUS_NIGHT1: float = 40.0
const ISLAND_RADIUS: float = ISLAND_RADIUS_NIGHT1   # alias Phase 1
const GRAVITY: float = 20.0               # do lon (gia toc ve -Y)
const JUMP_SPEED: float = 7.0
const PLAYER_ACCEL_STOP_S: float = 0.1
const LANTERN_RING_RADIUS: float = 25.0
const INITIAL_MOTES: int = 20
const MOTE_CAP: int = 30
const MOTE_RESPAWN_FIRST_TICKS: int = 240
const MOTE_RESPAWN_TICKS: int = 240
const DROPPED_MOTE_TTL_TICKS: int = 480
const DRIFTER_DROPPED_MOTE_TTL_TICKS: int = 120
const DROP_RING_MIN: float = 1.5
const DROP_RING_MAX: float = 2.5
const INITIAL_SHADES: int = 0             # ticket: 2 con tai tick 300 (spawn_system B5 xu ly)
const SHADE_FIRST_SPAWN_TICK: int = 300
const SHADE_FIRST_SPAWN_COUNT: int = 2
const SHADE_SPAWN_INTERVAL_S: float = 8.0   # Dem 1 (alias); xem shade_spawn_interval_ticks(night)
const MAX_SHADES: int = 6                   # Dem 1 (alias); xem max_shades(night)

const DRIFTER_SPEED: float = 7.0
const DRIFTER_IDLE_SPEED: float = 2.0
const DRIFTER_MAX_ALIVE: int = 2
const DRIFTER_SPAWN_EVERY_TICKS: int = 1200
const DRIFTER_AGGRO_CARRIED: int = 5
const DRIFTER_AGGRO_DIST: float = 15.0
const DRIFTER_STEAL_DIST: float = 1.2
const DRIFTER_STEAL_MAX: int = 3
const DRIFTER_FLEE_TICKS: int = 240
const CHARM_DURATION_TICKS: int = 600
const CHARM_RUN_SPEED: float = 7.2
const CHARM_RESPAWN_TICKS: int = 2700
const WIND_EVERY_TICKS: int = 1800
const WIND_DURATION_TICKS: int = 300
const WIND_PUSH_MPS: float = 2.0
const WIND_WARN_TICKS: int = 120

# --- accessors theo Dem (night 1..3) ---
static func night_duration_s(night: int) -> float:
	match night:
		2: return NIGHT2_DURATION_S
		3: return NIGHT3_DURATION_S
	return NIGHT1_DURATION_S

static func night_duration_ticks(night: int) -> int:
	return int(round(night_duration_s(night) * float(TICK_RATE)))   # v1.2: 14400/16200/18000

static func shade_speed(night: int) -> float:
	match night:
		2: return SHADE_SPEED_NIGHT2
		3: return SHADE_SPEED_NIGHT3
	return SHADE_SPEED_NIGHT1

static func island_radius(night: int) -> float:
	match night:
		2: return 28.0
		3: return 45.0
	return ISLAND_RADIUS_NIGHT1

static func lantern_count(night: int) -> int:
	match night:
		2: return 6
		3: return 7
	return LANTERN_COUNT_NIGHT1

static func max_shades(night: int) -> int:
	match night:
		2: return 8
		3: return 10
	return 6

static func shade_spawn_interval_ticks(night: int) -> int:
	match night:
		2: return 420
		3: return 360
	return 480

## So den dang sang toi thieu de thang luc binh minh: ceil(WIN_RATIO * tong den), tinh bang so nguyen
## (0.6 = 3/5): Dem 1 -> 3/5, Dem 2 -> 4/6, Dem 3 -> 5/7.
static func win_threshold(lantern_total: int) -> int:
	return int((3 * lantern_total + 4) / 5)

static func has_drifters(night: int) -> bool:
	return night >= 2

static func has_wind(night: int) -> bool:
	return night == 3

## Dung de test doi chieu voi game.contract.json (contract v1.2)
static func tuning_dict() -> Dictionary:
	return {
		"player_speed": PLAYER_SPEED, "carry_capacity": CARRY_CAPACITY,
		"lantern_cost": LANTERN_COST, "lantern_count_night1": LANTERN_COUNT_NIGHT1,
		"pickup_radius": PICKUP_RADIUS, "interact_radius": INTERACT_RADIUS,
		"pulse_cost": PULSE_COST, "pulse_radius": PULSE_RADIUS,
		"night1_duration_s": NIGHT1_DURATION_S, "flames": FLAMES,
		"invuln_s": INVULN_S, "hit_drop_ratio": HIT_DROP_RATIO,
		"pulse_stun_s": PULSE_STUN_S, "pulse_push_m": PULSE_PUSH_M,
		"pulse_cooldown_s": PULSE_COOLDOWN_S, "safe_radius": SAFE_RADIUS,
		"shade_speed": SHADE_SPEED, "shade_hit_radius": SHADE_HIT_RADIUS,
		"fall_enabled": FALL_ENABLED,
		"dash_speed": DASH_SPEED, "dash_duration_s": DASH_DURATION_S,
		"dash_cooldown_s": DASH_COOLDOWN_S,
		"night2_duration_s": NIGHT2_DURATION_S, "night3_duration_s": NIGHT3_DURATION_S,
		"fuel_max": FUEL_MAX, "fuel_decay_per_s": FUEL_DECAY_PER_S, "fuel_per_mote": FUEL_PER_MOTE,
		"relight_cost": RELIGHT_COST, "win_ratio": WIN_RATIO, "drain_per_s": DRAIN_PER_S,
		"low_fuel_threshold": LOW_FUEL_THRESHOLD, "capacity_max": CAPACITY_MAX,
		# [GIA DINH] ten khoa score v1.2: ticket khong liet ke; per_second_left bi bo theo ticket muc 5
		"score": {
			"per_mote": SCORE_PER_MOTE, "per_lantern": SCORE_PER_LANTERN,
			"per_relight": SCORE_PER_RELIGHT, "per_stun": SCORE_PER_STUN,
			"per_stun_drain": SCORE_PER_STUN_DRAIN, "per_lit_lantern_dawn": SCORE_PER_LIT_LANTERN_DAWN,
			"per_flame_left": SCORE_PER_FLAME_LEFT,
		},
	}
