class_name SimState
extends RefCounted
## Trang thai mo phong. KHONG sua file nay ngoai A0 (giao dien dong bang).

var tick: int = 0
var steps: int = 0
var status: String = "playing"   # playing | won | lost
var loss_reason: String = ""     # no_flames | dawn | ""
var time_left_initial: float = 300.0
var score: int = 0

# player: pos Vector3, vy float, carried int, flames int,
#         invuln_left float, pulse_cd_left float, on_ground bool
var player: Dictionary = {}
# lanterns: [{id:String "L1".., pos:Vector3, lit:bool, deposited:int}]
var lanterns: Array = []
# motes: [{id:String "m1".., pos:Vector3}]
var motes: Array = []
# shades: [{id:String "S1".., pos:Vector3, state:String, stun_left:float}]
var shades: Array = []

var random_motes: bool = true
var random_shades: bool = true
var next_mote_id: int = 1
var next_shade_id: int = 1
var spawn_timer_s: float = 0.0
var mote_respawn_ticks_left: int = 0
var rng: Rng = Rng.new(0)

func time_left_s() -> float:
	return maxf(0.0, time_left_initial - float(steps) * GameConfig.DT)

static func make_default_player() -> Dictionary:
	return {
		"pos": Vector3.ZERO, "vy": 0.0, "carried": 0,
		"flames": GameConfig.FLAMES, "invuln_left": 0.0,
		"pulse_cd_left": 0.0, "on_ground": true,
	}
