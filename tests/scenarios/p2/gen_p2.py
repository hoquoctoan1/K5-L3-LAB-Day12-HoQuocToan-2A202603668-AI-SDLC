# Sinh scenario/inputs/expected cho bo kich ban Phase 2 (P2-C2). Chay: python -I gen_p2.py
# Dap an (expected/*.md + check_p2.py) la suy ra BANG TAY tu docs/notes/ticket-02.json, khong lay tu output.
# Quy uoc: buoc k doc input k; event/snapshot tick = k+1; nut va move GIU gia tri den khi frame ke tiep doi.
import json, os
D = os.path.dirname(os.path.abspath(__file__))


def base(**kw):
    s = {"random_motes": False, "random_shades": False, "random_drifters": False, "wind_enabled": False,
         "motes": [], "shades": [], "drifters": [], "charms": []}
    s.update(kw)
    return s


def F(tick, **kw):
    d = {"tick": tick}
    d.update(kw)
    return d


def player(pos=(0, 0, 0), **kw):
    p = {"pos": list(pos), "carried": 0, "flames": 3}
    p.update(kw)
    return p


SETS = {}  # name -> (scenario, frames, md)


def add(name, scen, frames, md):
    SETS[name] = (scen, frames, md)


# ---------------- dash ----------------
add("d01_dash", base(player=player()),
    [F(0, move=[0, 1], dash=True), F(1, dash=False), F(12, move=[0, 0]), F(30, dash=True), F(31, dash=False), F(90, dash=True), F(91, dash=False)],
    """Night 1, player (0,0,0) facing +Z. Dash 14 m/s x 12 ticks = 12*14/60 = 2.8 m; cooldown 90 ticks from dash start.
Input t0: move +Z + dash. Dash at step 0 -> event `dash` tick 1; z after 12 steps (snapshot tick 12) = 2.8; z(1)=14/60=0.2333.
cd set to 90 at step 0, minus 1 per step: snapshot tick t shows (91-t)/60 s -> tick 1 = 1.5, tick 31 = 1.0, tick 45 = 0.7667.
Press at t30: cd>0 -> ignored (no event). Press at t90: cd has reached 0 at that step -> allowed, event `dash` tick 91.
Events (besides night_start): dash@1, dash@91. End playing 120 score 0.""")
add("d02_dash_cd_boundary", base(player=player()),
    [F(0, dash=True), F(1, dash=False), F(89, dash=True), F(90, dash=False)],
    """Dash at step 0 (facing +Z, no move). Press at t89: cooldown still 1 at that step's check -> ignored. Only event dash@1. End playing 100.""")
add("d03_dash_moving", base(player=player()),
    [F(0, move=[1, 0]), F(5, dash=True), F(6, dash=False)],
    """Walk +X at 6 m/s (0.1/tick). Press t5 -> dash toward moving direction (+X), event dash@6. x(5)=0.5 (5 steps);
dash steps 5..16 move 12*14/60=2.8 -> x(17)=3.3; step 17.. back to 6 m/s: x(29)=3.3+12*0.1=4.5. z stays 0.""")
add("d04_dash_charm", base(player=player(charm_ticks=600)),
    [F(0, move=[0, 1], dash=True), F(1, dash=False), F(5, dash=True), F(6, dash=False), F(12, dash=True), F(13, dash=False), F(30, dash=True)],
    """Charm active (600 ticks): dash cooldown 0 but each dash needs a NEW press (false->true) and presses while dashing are ignored.
t0 press -> dash@1 (steps 0..11). t5 press during dash -> ignored. t12 press: dash finished -> dash@13. t30 press (held to end) -> dash@31 only once.
Expected events dash@1, dash@13, dash@31. dash_cd_s = 0 in every snapshot 1..60. z(12)=2.8. charm_s(1)=599/60=9.983.""")

# ---------------- fall off island ----------------
fall_in = [F(0, move=[1, 0]), F(5, move=[0, 0])]
add("f01_fall_flames", base(player=player((39.7, 0, 0), carried=4)), fall_in,
    """Night 1 island radius 40. Start (39.7,0,0), carried 4, flames 3. Move +X: x=40.1 at tick 4 -> outside island, falls.
Fall (g=20): y<-10 after n steps where (20/3600)*n(n+1)/2 > 10 -> n=60 -> event about tick 63 (accept 60..66), exactly once.
Event player_hit {by:fall, flames:2, dropped:0, lost:4}. After it: flames 2, carried 0.
Wait 60 ticks (y stays < -10 at F+30 and F+59), then at tick F+60 respawn at start (0,0,0), vel 0, grounded, invuln 90 ticks = 1.5 s.
invuln(F+60+k)=(90-k)/60 -> >0 at F+149, 0 at F+151. No other events (no pickup). End playing.""")
add("f02_fall_last_flame", base(player=player((39.7, 0, 0), carried=2, flames=1)), fall_in,
    """Same fall with flames 1: flames 0 -> lost immediately, no respawn. Events same tick F: player_hit {by fall, flames 0, dropped 0, lost 2} then game_over {lost, no_flames}.
End: lost, ticks=F, score 0. Last snapshot tick = F with y < -10.""")
add("f03_fall_ignores_invuln", base(player=player((39.7, 0, 0), invuln_ticks=600)), fall_in,
    """Fall ignores invulnerability: invuln 600 ticks, still event player_hit by fall with flames 2.""")

# ---------------- jump pad / bridge (night 2) ----------------
add("j01_pad_night2", base(player=player((20, 0, 18))), [],
    """Night 2 pad (20,0,18) r1, launch vy 14, horizontal 24 m/s toward island B centre (70,0,0): dir=(50,-18)/53.15.
Flight time 2*14/20 = 1.4 s = 84 ticks (discrete: lands at tick 84; accept 83..86). Horizontal ~ 24*1.4=33.6 m -> landing about (51.5,0,6.7) (accept +-1.2).
Inside island B (dist to (70,0,0) < 28), grounded, y 0. Apex ~4.9 m (tick 42 within 0.3). Keys do not override velocity (no input anyway).
Pos after landing stays (no input). No events but night_start.""")
add("b01_bridge_walk", base(player=player((24, 0, 0)), charms=[]), [F(0, move=[1, 0])],
    """Night 2 bridge x 26..44, |z|<=2. Walk +X 6 m/s from (24,0,0): x(90)=33.0, y 0, grounded, no player_hit, flames 3.""")
add("b02_bridge_side_fall", base(player=player((35, 0, 1.5), carried=3), charms=[]), [F(0, move=[0, 1]), F(10, move=[0, 0])],
    """Bridge has no railing: z>2 is void. Start (35,0,1.5) move +Z: z=2.1 at tick 6 -> falls. Event player_hit by fall about tick 66 (accept 60..75): flames 2, lost 3.""")

# ---------------- night 3 ----------------
add("r01_ramp_climb", base(player=player((25.98, 0, 15))),
    [F(0, move=[-0.866025, -0.5]), F(70, move=[0, 0])],
    """Night 3 ramp at 30 deg: foot r30 y0 -> top r24 y3, linear. Start at foot (25.98,0,15) (r=30), walk straight up the centre line at 6 m/s.
y rises 0.5 m per metre: tick 30 -> r=27, y=1.5 (+-0.2); tick 60 -> r=24, y=3.0; tick 70 -> r=23 on tier 1, y=3.0 (+-0.05). Never falls (no player_hit).""")
add("r02_tier_edge_fall", base(player=player((0, 3, 18))), [F(0, move=[0, 1]), F(70, move=[0, 0])],
    """Tier 1 (y=3, annulus r 12..24, z>0) at (0,3,18) walk +Z: r=24 at tick 60; beyond that the vertical wall -> fall to tier 0 (y=0), 3 m drop (not off island): no player_hit.
y(60)=3.0, y never below 0, final y=0 grounded, z>24, flames 3, a snapshot exists with 0.1<y<2.9 and not grounded.""")
add("r03_pad_tier2", base(player=player((0, 3, 13))), [],
    """Night 3 pad (0,3,13) r1: vy 12, horizontal 8 m/s toward -Z. y(t)=3+12t-10t^2 crosses 6 again (descending) at t=(12+sqrt(24))/20=0.845 s ~ 51-52 ticks;
z=13-8*0.845=6.2 -> r=6.2 <8: lands on tier 2 (y=6). Land tick in 50..56, y=6 (+-0.05), z in 5.6..6.8, x~0, grounded.""")

# ---------------- pulse / shades ----------------
add("p01_pulse_3d", base(player=player(carried=5), shades=[{"id": "S1", "pos": [4.9, 0, 0]}, {"id": "S2", "pos": [4.95, 0, 0]}]),
    [F(0, pulse=True), F(1, pulse=False)],
    """Pulse centre = feet + 0.8, 3D radius 5. S1 (4.9,0,0): sqrt(4.9^2+0.8^2)=4.965 <=5 -> stunned. S2 (4.95,0,0): sqrt(24.5025+0.64)=5.014 >5 -> NOT stunned (2D would hit).
Event pulse@1 {stunned_ids:[S1]}; carried 5-3=2; score 5 (one stun). pulse_cd: 180 at step 0 -> pulse_cd_s(1)=3.0, (91)=1.5.
Knockback 4 m over 15 ticks: S1 x = 4.9+4 = 8.9 (+-0.03) by tick 20. S2 stays chase (never stunned) and moves toward player: x(10)<4.95. Run 40 ticks (S2 would touch at ~60).""")
add("p02_stun_120", base(player=player(carried=3), shades=[{"id": "S1", "pos": [3, 0, 0]}]),
    [F(0, pulse=True), F(1, pulse=False)],
    """Pulse at t0 stuns S1 for 120 ticks: state stunned in snapshots 1..~118; first non-stunned (chase) between ticks 119 and 122. carried 3-3=0, score 5, event pulse@1 [S1].
Knockback: x = 3+4 = 7.0 (+-0.03) at tick 20. Shade then chases but is 6 m away: no hit by tick 125 (needs ~90 ticks).""")
add("p03_pulse_dy", base(player=player((0, 3, 18), carried=3), shades=[{"id": "S1", "pos": [3, 0, 18]}, {"id": "S2", "pos": [-4, 0, 18]}]),
    [F(0, pulse=True), F(1, pulse=False)],
    """Night 3, player on tier 1 (y=3): centre y = 3.8. S1 (3,0,18): sqrt(9+3.8^2)=4.84 <=5 stunned. S2 (-4,0,18): sqrt(16+14.44)=5.52 >5 not stunned although XZ dist 4 <5.
Event pulse@1 {stunned_ids:[S1]}; score 5; carried 0. S1 knocked +X: x(20)=7.0 (+-0.05). No hit (dy=3 >1.5).""")
add("h01_shade_hit", base(player=player(carried=7), shades=[{"id": "S1", "pos": [1.25, 0, 0]}]), [],
    """Shade speed 4/60=0.0667/tick. 1.25-0.0667*3=1.05 >1; 4 moves -> 0.983 <=1: hit at step 3 -> event tick 4 player_hit {by shade, flames 2, dropped floor(7/2)=3}. carried 7-3=4.
3 dropped motes kind dropped, ids m1..m3, ring 1.5..2.5 m around player, ttl_s(4)=8.0 (480 ticks), ttl_s(64)=7.0. invuln(4)=1.5, invuln(64)=0.5.
Recoil: state recoil at tick 5; shade pushed 2 m away (+X): x(64)=0.983+2=2.98 (+-0.2). No second hit before tick 90 (invuln 90 ticks). Score 0.""")
add("h02_hit_no_drop", base(player=player(carried=1), shades=[{"id": "S1", "pos": [0.5, 0, 0]}]), [],
    """carried 1 -> floor(1/2)=0 dropped. Hit event tick 1 {by shade, flames 2, dropped 0}. carried stays 1, no dropped motes.""")
add("h03_dropped_ttl", base(player=player((-30, 0, 0), carried=4), shades=[{"id": "S1", "pos": [-31.25, 0, 0]}]),
    [F(5, move=[1, 0])],
    """Hit at tick 4 (1.25 gap as h01): drops floor(4/2)=2 dropped motes with ttl 480 from tick 4 -> ttl_s(t)=(484-t)/60, gone by tick 485.
Player then runs +X (6 > shade 4) so no further hits; may pick up a dropped mote on the way (mote_picked events).
Assertions: at tick 5 two dropped motes exist; dropped present + picked events == 2 until expiry; at tick 300 ttl_s of any remaining = 184/60; at tick 490 no dropped motes remain. flames 2 at end.""")

# ---------------- motes / lanterns ----------------
add("m01_capacity", base(player=player(carried=9), motes=[[0, 0, 0.5], [0, 0, 0.6]]), [],
    """Capacity 10. carried 9, two motes within 1 m: first pickup -> carried 10 (event mote_picked {carried:10} tick 1), second not picked. motes_active 1, score 10 (per_mote at pickup, Product Owner).""")
add("m02_respawn", base(player=player(), random_motes=True, motes=[[0, 0, 38]]), [],
    """random_motes true with one explicit mote (so no 20 initial). Respawn: first at tick 240, then every 240, 1 per time on a free point (rings r=12 or r=33).
motes_active: tick 239 = 1, tick 240 = 2, tick 479 = 2, tick 480 = 3. New motes kind random, ttl_s -1. No events.""")
add("l01_partial_fill", base(player=player(carried=4), lanterns=[{"id": "L1", "pos": [0, 0, 2], "deposited": 3}]), [F(0, interact=True), F(1, interact=False)],
    """Partial fill remembered: L1 deposited 3, carried 4, cost 10 -> deposit min(4, 7)=4 -> deposited 7, not lit. Event deposit@1 {L1, 4, 7}. carried 0, score 0.""")
add("l02_complete_fill", base(player=player(carried=7), lanterns=[{"id": "L1", "pos": [0, 0, 2], "deposited": 7}]), [F(0, interact=True), F(1, interact=False)],
    """L1 deposited 7, carried 7 -> amount min(7,3)=3 -> deposited 10 = cost 10 -> lit. Events deposit {L1,3,10}, lantern_lit {L1} at tick 1. carried 4, score 100 (+0 for deposit), 4 other lanterns unlit -> still playing.""")
add("l03_out_of_range", base(player=player(carried=3), lanterns=[{"id": "L1", "pos": [0, 0, 2.05]}]), [F(0, interact=True)],
    """Interact radius 2.0: L1 at 2.05 -> nothing happens. No events (except night_start), carried 3.""")
add("l04_nearest_tie_id", base(player=player(carried=2), lanterns=[{"id": "L1", "pos": [0, 0, 1.5]}, {"id": "L2", "pos": [0, 0, -1.5]}]), [F(0, interact=True)],
    """Equal distance 1.5: smaller id L1 wins: deposit@1 {L1, 2, 2}; L2 stays 0.""")

# ---------------- safe zone ----------------
add("z01_safe_block", base(player=player((0, 0, 22)), shades=[{"id": "S1", "pos": [0, 0, 35]}], lanterns=[{"id": "L1", "lit": True}]), [],
    """L1 (0,0,25) lit, safe radius 6. Shade S1 chases from (0,0,35) (10 m from lantern) along -Z at 0.0667/tick: z(30)=33.0 (+-0.05).
It is blocked at the 6 m edge: z=31.0 (reached after 60 ticks): z(120) in 30.95..31.2, dist to L1 >= 5.95. No hit, flames 3.""")
add("z02_safe_push", base(player=player((0, 0, 22.4)), shades=[{"id": "S1", "pos": [0, 0, 22]}], lanterns=[{"id": "L1", "lit": True}]), [],
    """Shade starts 3 m inside the lit lantern zone, touching the player. It is pushed out to the inner edge within 30 ticks with no damage, then blocked at the 6 m edge.
Assertions: no player_hit for the whole 200 ticks, flames 3, dist(shade,L1) >= 5.9 at tick 60 and tick 200.""")

# ---------------- spawn schedules ----------------
add("s01_spawn_n1", base(player=player(), random_shades=True), [],
    """Night 1: 2 shades at tick 300 (S1,S2) then 1 per 480 ticks: S3 at 780. Ring r=37 points at 15,45,.. deg. Events shade_spawned@300 x2, @780 x1, nothing else.
At tick 300: both shades at r=37 (+-0.05), angle mod 30 = 15 (+-0.3). Run 800 ticks (no contact: spawns 37 m away).""")
add("s02_spawn_n2", base(player=player(), random_shades=True, charms=[]), [],
    """Night 2: 2 shades at tick 300, then interval 420 -> S3 at 720. Ring radius 26 around island centres A(0,0,0) or B(70,0,0), angles 22.5+45k. S1,S2 on different islands (alternation, P3 assumption).
Assertions at tick 300: each at 26 (+-0.05) from A or B centre, angle mod 45 = 22.5 (+-0.3). Events: shade_spawned@300 x2, @720.""")
add("s03_spawn_n3", base(player=player((0, 0, -20)), random_shades=True, charms=[]), [],
    """Night 3: 2 shades at tick 300, interval 360 -> S3 at 660. Ring r=43, 16 points step 22.5. At tick 300 both at r=43 (+-0.05), angle difference between them a multiple of 22.5. Events shade_spawned@300 x2, @660.""")

# ---------------- drifters (night 2) ----------------
add("dr01_steal", base(player=player(carried=6), drifters=[{"id": "D1", "pos": [10, 0, 0], "state": "idle"}]), [],
    """Night 2. carried 6 >=5 and 10 m <=15: idle->chase at step 0 (tick 1 state chase). Speed 7/60=0.11667/tick toward player: distance 10-0.11667*n <=1.2 first at n=76 (n=75: 1.25).
Steal at step 75 -> event drifter_steal@76 {D1, amount min(3,6)=3, carried 3}; D1 flee stolen 3, once per drifter. No flame loss (flames 3), score 0.
Flee 240 ticks (7 m/s away): state removed at tick ~316 (accept 314..318), absent at tick 320. carried 3 to the end. Only one steal.""")
add("dr02_no_aggro_low", base(player=player(carried=4), drifters=[{"id": "D1", "pos": [3, 0, 0], "state": "idle"}]), [],
    """carried 4 <5: drifter never chases or steals: stays idle for 120 ticks (idle speed 2 m/s), no events, carried 4.""")
add("dr03_no_aggro_far", base(player=player(carried=6), drifters=[{"id": "D1", "pos": [17, 0, 0], "state": "idle"}]), [],
    """carried 6 but 17 m >15: idle at ticks 1..20 (moves <=2 m/s so still >15 m). No steal.""")
add("dr04_pulse_chase_flee", base(player=player(carried=6), drifters=[{"id": "D1", "pos": [3, 0, 0], "state": "chase"}]),
    [F(0, pulse=True), F(1, pulse=False)],
    """Pulse (3D dist sqrt(9+0.64)=3.1 <=5) while drifter in chase: -> flee, no steal. Event pulse@1 {stunned_ids:[]}, no drifter_steal. carried 6-3=3, stolen 0, score 0 (no points for drifters, P3).
Flee 7 m/s away along +X: x(10)=3+10*0.1167=4.17 (+-0.06). Flee 240 ticks: present at tick 230, removed by tick 250.""")
add("dr05_pulse_flee_drop", base(player=player(carried=3), drifters=[{"id": "D1", "pos": [4, 0, 0], "state": "flee", "stolen": 3}]),
    [F(0, pulse=True), F(1, pulse=False)],
    """Drifter fleeing with 3 stolen; pulse at 3D dist sqrt(16+0.64)=4.08 hits: drops all 3 at its place (ring 1.5..2.5 m around drifter): event drifter_drop@1 {D1, 3}; 3 dropped motes ttl 120 (drifter TTL), ttl_s(1)=2.0.
Motes expire: present at tick 115, absent at tick 125 (created at tick 1 with 120 ticks). stolen 0 afterwards. carried 3-3=0 stays 0 (motes >=1.5 m from player). Score 0.""")

# ---------------- charm ----------------
add("c01_charm", base(player=player((32.95, 0, 0)), charms=[{"id": "C1", "pos": [35, 0, 0]}]),
    [F(0, move=[1, 0]), F(41, move=[0, 0])],
    """Night 2. Start 2.05 m from charm at 6 m/s: distance 2.05-0.1n <=1.0 at n=11 -> event charm_picked@11 {C1, charm_ticks 600}. charm_s(11)=10.0; charm_s(t)=(611-t)/60, 0 from tick 611.
Charm speed 7.2 m/s: x(11)=34.05; x(41)=34.05+30*0.12=37.65 (+-0.05). Charm snapshot: available false, respawn_s(11)=45.0 (2700 ticks); available true again at tick 2711 (false at 2710, true at 2715).
Charm not re-picked (player ~38.7 m, 3.7 m away from 35).""")

# ---------------- wind ----------------
add("w01_wind", base(player=player((0, 0, -20)), wind_enabled=True, charms=[]), [],
    """Night 3, wind_enabled: strong wind every 1800 ticks, duration 300 ticks, push 2 m/s in random direction, warning 120 ticks before (not in snapshot).
wind.active false up to tick 1798, true from 1802 to 2098 (300 active snapshots +-1 in 1790..2110), false at >=2102. Player idle: displacement over the active window = 2 m/s * 5 s = 10 m (+-0.2),
direction = dir_deg (from +X toward +Z) +-3 deg [convention assumption]. Before wind player at (0,0,-20) exactly; no fall (stays within 30 m). No events but night_start.""")
add("w02_wind_off", base(player=player((0, 0, -20)), wind_enabled=False, charms=[]), [],
    """wind_enabled false: wind.active false in every snapshot through tick 2150 and player stays (0,0,-20).""")

# ---------------- pause ----------------
add("pa01_pause", base(player=player()), [F(0, move=[0, 1]), F(5, pause=True), F(6, pause=False), F(20, pause=True), F(21, pause=False)],
    """Night 1. Walk +Z 0.1/tick. t5 pause press: tick 6 event paused, state paused, sim_tick stays 5. Ticks 6..20 advance (tick) but sim_tick 5, z 0.5, time_left 300-5/60 = 299.9167 frozen.
t20 press while paused: event resumed@21 and that step runs: sim_tick 6, z 0.6, state playing. Afterwards sim_tick(t)=t-15, z(40)=2.5, time_left(40)=300-25/60.
Events: night_start@1, paused@6, resumed@21. Run 40 ticks. state "paused" for ticks 6..20; "playing" otherwise.""")

# ---------------- night start / dawn / tick boundaries ----------------
for k, tl in ((1, 300.0), (2, 330.0), (3, 360.0)):
    add("n0%d_night_start" % k, base(player=player((0, 0, -20) if k == 3 else (0, 0, 0))), [],
        """Night %d: first step emits night_start {night:%d} at tick 1. Snapshot tick 0: night %d, time_left_s %.1f. Exactly one night_start in 3 ticks.""" % (k, k, k, tl))
add("n04_charms_replace", base(player=player(), charms=[]), [],
    """arrays_replace_defaults: scenario charms [] on night 2 replaces the default charm (35,0,0): snapshot charms must be [] at every snapshot.""")
for k, n in ((1, 18000), (2, 19800), (3, 21600)):
    add("t0%d_dawn_n%d" % (k, k), base(player=player((0, 0, -20) if k == 3 else (0, 0, 0))), [],
        """Night %d full length: dawn at tick %d (%.0f s). No lanterns lit -> game_over {lost, dawn} event at tick %d, end lost %d score 0.""" % (k, n, n / 60, n, n))
add("tb01_ticks0_n3", base(player=player((0, 0, -20))), [],
    """--ticks 0 on night 3: output = one snapshot (tick 0, night 3, time_left 360.0) + end {ticks 0, playing, 0}. No events (no step executed).""")
add("tb02_dawn_tick59", base(player=player(), time_left_s=1.0), [],
    """Night 2 with time_left_s 1.0 = 60 ticks. --ticks 59: still playing: end {59, playing, 0}.""")
add("tb03_dawn_tick60", base(player=player(), time_left_s=1.0), [],
    """time_left_s 1.0, --ticks 61: game over at tick 60: event game_over {lost, dawn}@60, end {ticks 60, lost, 0} (loop stops at game over).""")

# ---------------- win / lose precedence + scoring ----------------
add("v01_win_beats_dawn_n2", base(player=player((0, 0, 19), carried=3), time_left_s=1.0,
                                  lanterns=[{"id": "L1", "pos": [0, 0, 20], "deposited": 7}] + [{"id": "L%d" % i, "lit": True} for i in range(2, 7)]),
    [F(59, interact=True)],
    """Night 2, time_left_s 1.0 (60 ticks). L1 deposited 7, carried 3. Interact at t59 -> tick 60 (the last tick): deposit {L1,3,10}, lantern_lit {L1}, then game_over {won, all_lit} (win beats dawn).
Score = 100 + floor(0 s)*2 + 50*3 flames = 250. End won,60,250.""")
add("v02_win_bonus_n3", base(player=player((0, 6, 5), carried=10, flames=2), time_left_s=100.0,
                             lanterns=[{"id": "L1"}] + [{"id": "L%d" % i, "lit": True} for i in range(2, 8)]), [F(0, interact=True)],
    """Night 3, last lantern L1 at (0,6,6) (tier 2), player (0,6,5) carried 10: deposit 10 -> lit at tick 1 (steps=1): time left 6000-1=5999 ticks -> floor(5999/60)=99 s.
Score = 100 (lantern) + 99*2 + 50*2 flames = 398. Events deposit {L1,10,10}, lantern_lit, game_over {won, all_lit} at tick 1. End won,1,398.""")
add("v03_nofl_beats_win", base(player=player((39.7, 0, 0), carried=10, flames=1),
                               lanterns=[{"id": "L1", "pos": [40.5, 0, 0]}] + [{"id": "L%d" % i, "lit": True} for i in range(2, 6)]),
    [F(0, move=[1, 0]), F(5, move=[0, 0]), F(62, interact=True)],
    """Fall (as f01, event tick 63 = step 62) on the same step that the last lantern is lit: flames 1 -> 0 and all lit.
Step 62: player falls (player_hit flames 0), deposit 10 lights L1 (+100), step 11: no_flames beats all_lit.
Events at tick 63 in order: player_hit {by fall, flames 0, dropped 0, lost 10} (the fall empties carried BEFORE the lantern step, so deposit may not happen; accepted outcome: lost no_flames, no win).
Assertions: game_over {lost, no_flames}; end state lost; no won.""")

# ---------------- bad shapes (expected exit codes) ----------------
BAD = {
    "e01_bad_shade_state": (base(shades=[{"pos": [1, 0, 1], "state": "hovering"}]), {"frames": []}, 2, "unknown shade state -> exit 2"),
    "e02_drifters_not_array": (dict(base(), drifters="D1"), {"frames": []}, 2, "drifters is a string, not an array -> exit 2"),
    "e03_drifter_no_pos": (dict(base(), drifters=[{"id": "D1"}]), {"frames": []}, 2, "drifter without pos -> exit 2"),
    "e04_wind_flag_type": (dict(base(), wind_enabled="yes"), {"frames": []}, 2, "wind_enabled must be bool -> exit 2"),
    "e05_input_dash_type": (base(), {"frames": [{"tick": 0, "dash": 1}]}, 2, "inputs dash must be bool -> exit 2"),
    "e06_drifter_state": (dict(base(), drifters=[{"pos": [0, 0, 0], "state": "zombie"}]), {"frames": []}, 2, "unknown drifter state -> exit 2"),
}


def dump(path, obj):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, separators=(",", ":"))
        f.write("\n")


DROP = ["d02_dash_cd_boundary","d03_dash_moving","f03_fall_ignores_invuln","h02_hit_no_drop","h03_dropped_ttl","l03_out_of_range","l04_nearest_tie_id","dr02_no_aggro_low","dr03_no_aggro_far","w02_wind_off","t01_dawn_n1","t02_dawn_n2","t03_dawn_n3","s02_spawn_n2","s03_spawn_n3","e03_drifter_no_pos","e04_wind_flag_type","e06_drifter_state","n02_night_start"]
for _d in DROP:
    SETS.pop(_d, None); BAD.pop(_d, None)

if __name__ == "__main__":
    os.makedirs(os.path.join(D, "expected"), exist_ok=True)
    for name, (scen, frames, md) in SETS.items():
        dump(os.path.join(D, name + ".scenario.json"), scen)
        dump(os.path.join(D, name + ".inputs.json"), {"frames": frames})
        with open(os.path.join(D, "expected", name + ".md"), "w", encoding="utf-8", newline="\n") as f:
            f.write("# %s\n\nSeed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).\n\n%s\n" % (name, md))
    for name, (scen, inp, rc, md) in BAD.items():
        dump(os.path.join(D, name + ".scenario.json"), scen)
        dump(os.path.join(D, name + ".inputs.json"), inp)
        with open(os.path.join(D, "expected", name + ".md"), "w", encoding="utf-8", newline="\n") as f:
            f.write("# %s\n\nExpected exit code %d: %s.\n" % (name, rc, md))
    print("generated", len(SETS), "sets +", len(BAD), "bad")
