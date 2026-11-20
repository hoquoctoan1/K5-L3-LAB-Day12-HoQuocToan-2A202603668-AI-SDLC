class_name GameConfig
extends RefCounted
## Nguon su that duy nhat cho tuning. Phai khop game.contract.json (co test).

const DT: float = 1.0 / 60.0

# --- tuning cong khai trong contract ---
const PLAYER_SPEED: float = 6.0
const CARRY_CAPACITY: int = 5
const LANTERN_COST: int = 5
const LANTERN_COUNT_NIGHT1: int = 5
const PICKUP_RADIUS: float = 1.2
const INTERACT_RADIUS: float = 2.5
const PULSE_COST: int = 2
const PULSE_RADIUS: float = 6.0
const NIGHT1_DURATION_S: float = 300.0
const FLAMES: int = 3
const INVULN_S: float = 1.5
const HIT_DROP_RATIO: float = 0.5
const PULSE_STUN_S: float = 3.0
const PULSE_PUSH_M: float = 3.0
const PULSE_COOLDOWN_S: float = 2.0
const SAFE_RADIUS: float = 5.0
const SHADE_SPEED: float = 3.5
const SHADE_HIT_RADIUS: float = 1.0
const FALL_ENABLED: bool = false

const SCORE_PER_MOTE: int = 10
const SCORE_PER_LANTERN: int = 100
const SCORE_PER_STUN: int = 5
const SCORE_PER_SECOND_LEFT: int = 1
const SCORE_PER_FLAME_LEFT: int = 50

# --- hang so noi bo (khong thuoc contract) ---
const ISLAND_RADIUS: float = 45.0
const GRAVITY: float = 18.0
const JUMP_SPEED: float = 6.0
const LANTERN_RING_RADIUS: float = 25.0
const INITIAL_MOTES: int = 30
const INITIAL_SHADES: int = 3
const MOTE_RESPAWN_TICKS: int = 120
const SHADE_SPAWN_INTERVAL_S: float = 20.0
const MAX_SHADES: int = 5

## Dung de test doi chieu voi game.contract.json
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
		"score": {
			"per_mote": SCORE_PER_MOTE, "per_lantern": SCORE_PER_LANTERN,
			"per_stun": SCORE_PER_STUN, "per_second_left": SCORE_PER_SECOND_LEFT,
			"per_flame_left": SCORE_PER_FLAME_LEFT,
		},
	}
