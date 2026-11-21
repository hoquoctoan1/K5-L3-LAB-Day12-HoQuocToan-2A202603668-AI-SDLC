# Kiem tra khang dinh tay (hand-derived) Phase 2. Dung: python -I check_p2.py <name> <out.jsonl>
# Dap an suy ra tu ticket-02.json (xem expected/<name>.md). KHONG sua cho khop output.
import json, math, sys

name, path = sys.argv[1], sys.argv[2]
rows = [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]
snaps = {r["tick"]: r for r in rows if r["type"] == "snapshot"}
evs = [r for r in rows if r["type"] == "event"]
end = rows[-1]
errs = []


def chk(c, msg):
    if not c:
        errs.append(msg)


def near(a, b, tol=0.01):
    return abs(a - b) <= tol


def ev(n):
    return [e for e in evs if e["name"] == n]


def evt(n):
    return [e["tick"] for e in ev(n)]


def names(skip_start=True):
    return [(e["tick"], e["name"]) for e in evs if not (skip_start and e["name"] == "night_start")]


def final(state, ticks, score):
    chk(end["type"] == "end", "last line not end")
    chk(end.get("state") == state, "end.state=%r want %r" % (end.get("state"), state))
    chk(end.get("ticks") == ticks, "end.ticks=%r want %r" % (end.get("ticks"), ticks))
    chk(end.get("score") == score, "end.score=%r want %r" % (end.get("score"), score))


_EMPTY = {"tick": -1, "sim_tick": -1, "state": "?", "time_left_s": -1, "score": -1, "night": -1,
          "wind": {"active": None, "dir_deg": 0}, "motes_active": -1, "motes": [], "drifters": [], "charms": [],
          "shades": [], "lanterns": [],
          "player": {"pos": [0, 0, 0], "vel": [0, 0, 0], "grounded": None, "invuln": -1, "dash_cd_s": -1,
                     "pulse_cd_s": -1, "charm_s": -1, "flames": -1, "carried": -1}}


def S(t):
    s = snaps.get(t)
    chk(s is not None, "missing snapshot tick %d" % t)
    return s or _EMPTY


def P(t):
    return S(t)["player"]["pos"]


def shade(t, sid):
    for x in S(t)["shades"]:
        if x["id"] == sid:
            return x
    chk(False, "shade %s missing at tick %d" % (sid, t))
    return {"id": sid, "pos": [0, 0, 0], "state": "?"}


def drifter(t, did):
    for x in S(t)["drifters"]:
        if x["id"] == did:
            return x
    return None


def lant(t, lid):
    for x in S(t)["lanterns"]:
        if x["id"] == lid:
            return x
    chk(False, "lantern %s missing" % lid)
    return {"pos": [0, 0, 0], "lit": None, "deposited": -1}


def dist2(a, b):
    return math.hypot(a[0] - b[0], a[2] - b[2])


def first_after(pred, lo, hi):
    for t in range(lo, hi + 1):
        if t in snaps and pred(snaps[t]):
            return t
    return None


def fall_events():
    return [e for e in ev("player_hit") if e["data"].get("by") == "fall"]


def check_fall_basic(F):
    chk(60 <= F <= 66, "fall tick %s not in 60..66" % F)


# ---------------- dash ----------------
if name == "d01_dash":
    chk(names() == [(1, "dash"), (91, "dash")], "events %s" % names())
    final("playing", 120, 0)
    chk(near(P(12)[2], 2.8) and near(P(12)[0], 0), "z(12) %s" % P(12))
    chk(near(P(1)[2], 14 / 60, 0.005), "z(1) %s" % P(1))
    chk(near(S(1)["player"]["dash_cd_s"], 1.5), "cd(1)")
    chk(near(S(31)["player"]["dash_cd_s"], 1.0), "cd(31)")
    chk(near(S(45)["player"]["dash_cd_s"], 46 / 60), "cd(45) %s" % S(45)["player"]["dash_cd_s"])
elif name == "d02_dash_cd_boundary":
    chk(names() == [(1, "dash")], "events %s" % names())
    final("playing", 100, 0)
elif name == "d03_dash_moving":
    chk(names() == [(6, "dash")], "events %s" % names())
    chk(near(P(5)[0], 0.5), "x(5) %s" % P(5))
    chk(near(P(17)[0], 3.3) and near(P(17)[2], 0), "x(17) %s" % P(17))
    chk(near(P(29)[0], 4.5), "x(29) %s" % P(29))
elif name == "d04_dash_charm":
    chk(names() == [(1, "dash"), (13, "dash"), (31, "dash")], "events %s" % names())
    chk(all(near(S(t)["player"]["dash_cd_s"], 0.0) for t in range(1, 61)), "dash_cd_s not 0 with charm")
    chk(near(P(12)[2], 2.8), "z(12) %s" % P(12))
    chk(near(S(1)["player"]["charm_s"], 599 / 60), "charm_s(1)")
# ---------------- fall ----------------
elif name == "f01_fall_flames":
    fe = fall_events()
    chk(len(fe) == 1, "fall events %d" % len(fe))
    if fe:
        F = fe[0]["tick"]
        check_fall_basic(F)
        chk(fe[0]["data"] == {"by": "fall", "flames": 2, "dropped": 0, "lost": 4}, "data %s" % fe[0]["data"])
        chk(S(F)["player"]["flames"] == 2 and S(F)["player"]["carried"] == 0, "flames/carried at F")
        chk(S(F + 30)["player"]["pos"][1] < -10 and S(F + 59)["player"]["pos"][1] < -10, "not waiting below -10")
        q = S(F + 60)["player"]
        chk(all(near(a, 0, 1e-3) for a in q["pos"]), "respawn pos %s" % q["pos"])
        chk(all(near(a, 0, 1e-3) for a in q["vel"]) and q["grounded"] is True, "respawn vel/grounded")
        chk(near(q["invuln"], 1.5), "invuln at respawn %s" % q["invuln"])
        chk(S(F + 149)["player"]["invuln"] > 0 and S(F + 151)["player"]["invuln"] == 0, "invuln end")
    chk([n for _, n in names()] == ["player_hit"], "events %s" % names())
    final("playing", 240, 0)
    chk(S(240)["player"]["flames"] == 2, "flames end")
elif name == "f02_fall_last_flame":
    fe = fall_events()
    chk(len(fe) == 1, "fall events")
    if fe:
        F = fe[0]["tick"]
        check_fall_basic(F)
        chk(fe[0]["data"] == {"by": "fall", "flames": 0, "dropped": 0, "lost": 2}, "data %s" % fe[0]["data"])
        chk([(e["tick"], e["name"]) for e in evs if e["name"] in ("player_hit", "game_over")] == [(F, "player_hit"), (F, "game_over")], "order")
        go = ev("game_over")
        chk(go and go[0]["data"] == {"result": "lost", "reason": "no_flames"}, "game_over data")
        final("lost", F, 0)
        chk(max(snaps) == F and S(F)["player"]["pos"][1] < -10, "last snapshot")
elif name == "f03_fall_ignores_invuln":
    fe = fall_events()
    chk(len(fe) == 1 and fe[0]["data"]["flames"] == 2, "fall with invuln %s" % [e["data"] for e in fe])
    final("playing", 120, 0)
# ---------------- pads / bridge ----------------
elif name == "j01_pad_night2":
    final("playing", 120, 0)
    chk(names() == [], "events %s" % names())
    L = first_after(lambda s: s["player"]["grounded"] is True, 5, 120)
    chk(L is not None and 83 <= L <= 86, "landing tick %s" % L)
    chk(near(P(42)[1], 4.9, 0.3), "apex y %s" % P(42)[1])
    if L:
        p = P(L)
        chk(near(p[0], 51.5, 1.2) and near(p[2], 6.7, 1.2) and near(p[1], 0, 0.02), "landing pos %s" % p)
        chk(dist2(p, (70, 0, 0)) < 28, "not on island B")
        chk(near(P(L + 10)[0], p[0], 0.02), "moved after landing")
    chk(S(40)["player"]["grounded"] is False and P(40)[1] > 1, "not airborne at 40")
elif name == "b01_bridge_walk":
    chk(near(P(90)[0], 33.0) and near(P(90)[1], 0, 0.01) and near(P(90)[2], 0, 0.01), "pos(90) %s" % P(90))
    chk(S(90)["player"]["grounded"] is True and S(90)["player"]["flames"] == 3, "state")
    chk(names() == [], "events %s" % names())
elif name == "b02_bridge_side_fall":
    fe = fall_events()
    chk(len(fe) == 1, "fall events")
    if fe:
        chk(60 <= fe[0]["tick"] <= 75, "fall tick %s" % fe[0]["tick"])
        chk(fe[0]["data"]["flames"] == 2 and fe[0]["data"]["lost"] == 3, "data %s" % fe[0]["data"])
        chk(near(P(fe[0]["tick"])[0], 35.0, 0.05), "x drift")
# ---------------- night 3 ----------------
elif name == "r01_ramp_climb":
    chk(near(P(30)[1], 1.5, 0.2), "y(30) %s" % P(30))
    chk(near(P(60)[1], 3.0, 0.15), "y(60) %s" % P(60))
    chk(near(P(70)[1], 3.0, 0.05), "y(70) %s" % P(70))
    p = P(70)
    chk(near(math.hypot(p[0], p[2]), 23.0, 0.15), "r(70) %s" % math.hypot(p[0], p[2]))
    chk(names() == [], "events %s" % names())
elif name == "r02_tier_edge_fall":
    chk(names() == [], "events %s" % names())
    chk(near(P(60)[1], 3.0, 0.01), "y(60)")
    chk(all(snaps[t]["player"]["pos"][1] >= -0.01 for t in snaps), "dropped below tier 0")
    chk(near(P(140)[1], 0.0, 0.01) and S(140)["player"]["grounded"] is True and P(140)[2] > 24.0, "final %s" % P(140))
    chk(first_after(lambda s: 0.1 < s["player"]["pos"][1] < 2.9 and s["player"]["grounded"] is False, 61, 140) is not None, "no falling snapshot")
    chk(S(140)["player"]["flames"] == 3, "flames")
elif name == "r03_pad_tier2":
    L = first_after(lambda s: s["player"]["grounded"] is True, 5, 100)
    chk(L is not None and 50 <= L <= 56, "landing tick %s" % L)
    if L:
        p = P(L)
        chk(near(p[1], 6.0, 0.05) and 5.6 <= p[2] <= 6.8 and near(p[0], 0, 0.1), "landing pos %s" % p)
    chk(names() == [], "events %s" % names())
# ---------------- pulse / shades ----------------
elif name == "p01_pulse_3d":
    chk(names() == [(1, "pulse")], "events %s" % names())
    chk(ev("pulse") and ev("pulse")[0]["data"] == {"stunned_ids": ["S1"]}, "pulse data")
    final("playing", 40, 5)
    chk(S(1)["player"]["carried"] == 2 and S(40)["player"]["carried"] == 2, "carried")
    chk(near(S(1)["player"]["pulse_cd_s"], 3.0) and near(S(91)["player"]["pulse_cd_s"], 1.5) if 91 in snaps else near(S(1)["player"]["pulse_cd_s"], 3.0), "pulse_cd")
    chk(shade(1, "S1")["state"] == "stunned", "S1 state")
    chk(near(shade(20, "S1")["pos"][0], 8.9, 0.03) and near(shade(40, "S1")["pos"][0], 8.9, 0.03), "S1 x %s" % shade(20, "S1")["pos"])
    chk(all(shade(t, "S2")["state"] == "chase" for t in range(1, 41)), "S2 not chase")
    chk(shade(10, "S2")["pos"][0] < 4.95, "S2 not moving")
elif name == "p02_stun_120":
    chk(names() == [(1, "pulse")], "events %s" % names())
    chk(ev("pulse") and ev("pulse")[0]["data"] == {"stunned_ids": ["S1"]}, "pulse data")
    final("playing", 125, 5)
    chk(S(125)["player"]["carried"] == 0, "carried")
    chk(all(shade(t, "S1")["state"] == "stunned" for t in range(1, 119)), "stunned before 119")
    t1 = first_after(lambda s: [x for x in s["shades"] if x["id"] == "S1"][0]["state"] != "stunned", 1, 125)
    chk(t1 is not None and 119 <= t1 <= 122, "stun ends at %s" % t1)
    chk(shade(125, "S1")["state"] == "chase", "S1 after stun %s" % shade(125, "S1")["state"])
    chk(near(shade(20, "S1")["pos"][0], 7.0, 0.03), "knockback x %s" % shade(20, "S1")["pos"])
elif name == "p03_pulse_dy":
    chk(names() == [(1, "pulse")], "events %s" % names())
    chk(ev("pulse") and ev("pulse")[0]["data"] == {"stunned_ids": ["S1"]}, "pulse data")
    final("playing", 20, 5)
    chk(near(shade(20, "S1")["pos"][0], 7.0, 0.05), "S1 x %s" % shade(20, "S1")["pos"])
    chk(shade(5, "S2")["state"] == "chase", "S2 state")
elif name == "h01_shade_hit":
    ph = ev("player_hit")
    chk(len(ph) == 1 and ph[0]["tick"] == 4 and ph[0]["data"] == {"by": "shade", "flames": 2, "dropped": 3}, "hit %s" % [(e["tick"], e["data"]) for e in ph])
    s4 = S(4)
    dm = [m for m in s4["motes"] if m["kind"] == "dropped"]
    chk(len(dm) == 3 and sorted(m["id"] for m in dm) == ["m1", "m2", "m3"], "dropped %s" % dm)
    chk(all(1.49 <= math.hypot(m["pos"][0], m["pos"][2]) <= 2.51 for m in dm), "ring radius")
    chk(all(near(m["ttl_s"], 8.0, 0.02) for m in dm), "ttl(4) %s" % [m["ttl_s"] for m in dm])
    chk(all(near(m["ttl_s"], 7.0, 0.05) for m in S(64)["motes"] if m["kind"] == "dropped") and len(S(64)["motes"]) == 3, "ttl(64)")
    chk(s4["player"]["carried"] == 4 and near(s4["player"]["invuln"], 1.5), "carried/invuln")
    chk(near(S(64)["player"]["invuln"], 0.5), "invuln(64)")
    chk(shade(5, "S1")["state"] == "recoil", "recoil state %s" % shade(5, "S1")["state"])
    chk(near(shade(64, "S1")["pos"][0], 2.98, 0.2), "recoil x %s" % shade(64, "S1")["pos"])
    final("playing", 90, 0)
    chk(ev("mote_picked") == [], "picked")
elif name == "h02_hit_no_drop":
    ph = ev("player_hit")
    chk(len(ph) >= 1 and ph[0]["tick"] == 1 and ph[0]["data"] == {"by": "shade", "flames": 2, "dropped": 0}, "hit %s" % [(e["tick"], e["data"]) for e in ph])
    chk(S(10)["player"]["carried"] == 1 and all(m["kind"] != "dropped" for m in S(10)["motes"]), "carried/motes")
elif name == "h03_dropped_ttl":
    ph = ev("player_hit")
    chk(len(ph) == 1 and ph[0]["tick"] == 4 and ph[0]["data"] == {"by": "shade", "flames": 2, "dropped": 2}, "hit %s" % [(e["tick"], e["data"]) for e in ph])
    chk(len([m for m in S(5)["motes"] if m["kind"] == "dropped"]) == 2, "dropped at 5")
    picked = ev("mote_picked")
    for t in (50, 100, 200, 300, 400):
        n = len([m for m in S(t)["motes"] if m["kind"] == "dropped"])
        got = len([e for e in picked if e["tick"] <= t])
        chk(n + got == 2, "tick %d dropped %d picked %d" % (t, n, got))
    chk(all(near(m["ttl_s"], 184 / 60, 0.05) for m in S(300)["motes"] if m["kind"] == "dropped"), "ttl(300)")
    chk(all(m["kind"] != "dropped" for m in S(490)["motes"]), "dropped remain at 490")
    chk(S(500)["player"]["flames"] == 2, "flames")
# ---------------- motes / lanterns ----------------
elif name == "m01_capacity":
    # P3 (v1.2): nhat khong cong diem (TICKET-03 muc 5) -> 10 thanh 0; capacity snapshot = 10 (0 lan thap)
    chk(names() == [(1, "mote_picked")] and ev("mote_picked")[0]["data"] == {"carried": 10}, "events %s" % names())
    final("playing", 30, 0)
    chk(S(30)["player"]["capacity"] == 10, "capacity 10")
    chk(S(30)["player"]["carried"] == 10 and S(30)["motes_active"] == 1, "state")
elif name == "m02_respawn":
    chk(names() == [], "events %s" % names())
    a = [S(t)["motes_active"] for t in (239, 240, 479, 480)]
    chk(a == [1, 2, 2, 3], "motes_active %s" % a)
    for m in S(480)["motes"]:
        chk(m["kind"] == "random" and m["ttl_s"] == -1.0, "kind/ttl %s" % m)
        r = math.hypot(m["pos"][0], m["pos"][2])
        chk(m["pos"][2] == 38 or near(r, 12, 0.02) or near(r, 33, 0.02), "mote point radius %s" % r)
elif name == "l01_partial_fill":
    chk(names() == [(1, "deposit")] and ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 4, "deposited": 7}, "events %s" % names())
    chk(lant(30, "L1")["deposited"] == 7 and lant(30, "L1")["lit"] is False and S(30)["player"]["carried"] == 0, "state")
    final("playing", 30, 20)   # P3 (v1.2): +5 moi mote nap (4 mote)
elif name == "l02_complete_fill":
    chk(names() == [(1, "deposit"), (1, "lantern_lit")], "events %s" % names())
    chk(ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 3, "deposited": 10}, "deposit data")
    chk(S(30)["player"]["carried"] == 4 and lant(30, "L1")["lit"] is True, "state")
    final("playing", 30, 115)  # P3 (v1.2): 3*5 + 100
    chk(ev("lantern_lit")[0]["data"] == {"lantern_id": "L1", "relight": False}, "lit relight false")
elif name == "l03_out_of_range":
    chk(names() == [], "events %s" % names())
    chk(S(30)["player"]["carried"] == 3 and lant(30, "L1")["deposited"] == 0, "state")
elif name == "l04_nearest_tie_id":
    chk(names() == [(1, "deposit")] and ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 2, "deposited": 2}, "events %s" % names())
    chk(lant(30, "L2")["deposited"] == 0, "L2")
# ---------------- safe zone ----------------
elif name == "z01_safe_block":
    chk(names() == [], "events %s" % names())
    chk(near(shade(30, "S1")["pos"][2], 33.0, 0.06), "z(30) %s" % shade(30, "S1")["pos"])
    z = shade(120, "S1")["pos"]
    chk(30.95 <= z[2] <= 31.2 and dist2(z, (0, 0, 25)) >= 5.95, "blocked z %s" % z)
    chk(S(120)["player"]["flames"] == 3, "flames")
elif name == "z02_safe_push":
    chk(ev("player_hit") == [], "hit %s" % names())
    chk(S(200)["player"]["flames"] == 3, "flames")
    for t in (60, 200):
        d = dist2(shade(t, "S1")["pos"], (0, 0, 25))
        chk(d >= 5.9, "dist to lantern at %d = %.3f" % (t, d))
# ---------------- spawn ----------------
elif name == "s01_spawn_n1":
    chk(names() == [(300, "shade_spawned"), (300, "shade_spawned"), (780, "shade_spawned")], "events %s" % names())
    chk([e["data"]["id"] for e in ev("shade_spawned")] == ["S1", "S2", "S3"], "ids")
    for sid in ("S1", "S2"):
        p = shade(300, sid)["pos"]
        chk(near(math.hypot(p[0], p[2]), 37.0, 0.05), "radius %s" % p)
        a = math.degrees(math.atan2(p[2], p[0])) % 30
        chk(near(a, 15.0, 0.3), "angle mod 30 = %.2f" % a)
elif name == "s02_spawn_n2":
    chk(names() == [(300, "shade_spawned"), (300, "shade_spawned"), (720, "shade_spawned")], "events %s" % names())
    isl = []
    for sid in ("S1", "S2"):
        p = shade(300, sid)["pos"]
        dA, dB = dist2(p, (0, 0, 0)), dist2(p, (70, 0, 0))
        chk(near(dA, 26.0, 0.05) or near(dB, 26.0, 0.05), "ring radius %s" % p)
        c = (0, 0, 0) if near(dA, 26.0, 0.05) else (70, 0, 0)
        isl.append(c)
        a = math.degrees(math.atan2(p[2] - c[2], p[0] - c[0])) % 45
        chk(near(a, 22.5, 0.3), "angle mod 45 = %.2f" % a)
    chk(isl[0] != isl[1], "S1,S2 same island")
elif name == "s03_spawn_n3":
    chk(names() == [(300, "shade_spawned"), (300, "shade_spawned"), (660, "shade_spawned")], "events %s" % names())
    ang = []
    for sid in ("S1", "S2"):
        p = shade(300, sid)["pos"]
        chk(near(math.hypot(p[0], p[2]), 43.0, 0.05), "radius %s" % p)
        ang.append(math.degrees(math.atan2(p[2], p[0])))
    d = ((ang[0] - ang[1]) % 22.5)
    chk(min(d, 22.5 - d) < 0.3, "angle diff %.2f not multiple of 22.5" % d)
# ---------------- drifters ----------------
elif name == "dr01_steal":
    chk(names() == [(76, "drifter_steal")], "events %s" % names())
    chk(ev("drifter_steal") and ev("drifter_steal")[0]["data"] == {"drifter_id": "D1", "amount": 3, "carried": 3}, "steal data")
    chk(drifter(1, "D1")["state"] == "chase", "chase at 1")
    chk(drifter(75, "D1")["state"] == "chase" and drifter(75, "D1")["stolen"] == 0, "75 %s" % drifter(75, "D1"))
    d76 = drifter(76, "D1")
    chk(d76 and d76["state"] == "flee" and d76["stolen"] == 3, "76 %s" % d76)
    chk(S(75)["player"]["carried"] == 6 and S(76)["player"]["carried"] == 3 and S(330)["player"]["carried"] == 3, "carried")
    chk(S(330)["player"]["flames"] == 3, "flames")
    tr = first_after(lambda s: not [x for x in s["drifters"] if x["state"] != "removed"], 200, 330)
    chk(tr is not None and 314 <= tr <= 318, "drifter gone at %s" % tr)
    chk(drifter(320, "D1") is None, "D1 at 320")
    final("playing", 330, 0)
elif name == "dr02_no_aggro_low":
    chk(names() == [], "events %s" % names())
    chk(all(drifter(t, "D1")["state"] == "idle" for t in range(1, 121)), "not idle")
    chk(S(120)["player"]["carried"] == 4, "carried")
elif name == "dr03_no_aggro_far":
    chk(names() == [], "events %s" % names())
    chk(all(drifter(t, "D1")["state"] == "idle" for t in range(1, 21)), "not idle")
elif name == "dr04_pulse_chase_flee":
    chk(names() == [(1, "pulse")] and ev("pulse")[0]["data"] == {"stunned_ids": []}, "events %s" % names())
    d = drifter(1, "D1")
    chk(d and d["state"] == "flee" and d["stolen"] == 0, "flee %s" % d)
    chk(S(1)["player"]["carried"] == 3 and S(1)["score"] == 0, "carried/score")
    chk(near(drifter(10, "D1")["pos"][0], 4.17, 0.06), "x(10) %s" % drifter(10, "D1")["pos"])
    chk(drifter(230, "D1") is not None and drifter(250, "D1") is None, "flee duration")
elif name == "dr05_pulse_flee_drop":
    chk(names() == [(1, "pulse"), (1, "drifter_drop")] or names() == [(1, "drifter_drop"), (1, "pulse")], "events %s" % names())
    chk(ev("drifter_drop") and ev("drifter_drop")[0]["data"] == {"drifter_id": "D1", "amount": 3}, "drop data")
    dm = [m for m in S(1)["motes"] if m["kind"] == "dropped"]
    chk(len(dm) == 3 and all(near(m["ttl_s"], 2.0, 0.02) for m in dm), "dropped %s" % dm)
    d = drifter(1, "D1")
    chk(d is not None and d["stolen"] == 0, "stolen after drop %s" % d)
    chk(all(1.45 <= dist2(m["pos"], d["pos"]) <= 2.55 for m in dm) if d else False, "ring around drifter")
    chk(len([m for m in S(115)["motes"] if m["kind"] == "dropped"]) == 3, "dropped at 115")
    chk(len([m for m in S(125)["motes"] if m["kind"] == "dropped"]) == 0, "dropped at 125")
    chk(S(125)["player"]["carried"] == 0 and S(125)["score"] == 0, "carried/score")
# ---------------- charm ----------------
elif name == "c01_charm":
    chk(names() == [(11, "charm_picked")] and ev("charm_picked")[0]["data"] == {"charm_id": "C1", "charm_ticks": 600}, "events %s" % names())
    chk(near(S(11)["player"]["charm_s"], 10.0, 0.01) and near(S(400)["player"]["charm_s"], 211 / 60, 0.02), "charm_s")
    chk(near(S(611)["player"]["charm_s"], 0.0, 0.001) and S(610)["player"]["charm_s"] > 0, "charm end")
    chk(near(P(11)[0], 34.05, 0.05) and near(P(41)[0], 37.65, 0.06), "speed x11 %s x41 %s" % (P(11)[0], P(41)[0]))
    c = S(11)["charms"][0]
    chk(c["id"] == "C1" and c["available"] is False and near(c["respawn_s"], 45.0, 0.02), "charm snap %s" % c)
    chk(S(2710)["charms"][0]["available"] is False and S(2715)["charms"][0]["available"] is True, "respawn at 2711")
# ---------------- wind ----------------
elif name == "w01_wind":
    chk(names() == [], "events %s" % names())
    act = [t for t in snaps if S(t)["wind"]["active"]]
    chk(all(snaps[t]["wind"]["active"] is False for t in range(0, 1799)), "wind early")
    chk(all(snaps[t]["wind"]["active"] is True for t in range(1802, 2099)), "wind not active 1802..2098")
    chk(all(snaps[t]["wind"]["active"] is False for t in range(2102, 2151)), "wind late")
    n = len([t for t in range(1790, 2111) if snaps[t]["wind"]["active"]])
    chk(299 <= n <= 301, "active count %d" % n)
    chk(all(near(a, b, 1e-3) for a, b in zip(P(1790), (0, 0, -20))), "moved before wind %s" % P(1790))
    if act:
        a0, a1 = min(act), max(act)
        p0, p1 = P(a0 - 1), P(a1)
        dx, dz = p1[0] - p0[0], p1[2] - p0[2]
        chk(near(math.hypot(dx, dz), 10.0, 0.25), "displacement %.3f" % math.hypot(dx, dz))
        want = S(a0 + 5)["wind"]["dir_deg"]
        got = math.degrees(math.atan2(dz, dx)) % 360
        dd = abs((got - want + 180) % 360 - 180)
        chk(dd < 3.0, "direction got %.1f want %.1f" % (got, want))
elif name == "w02_wind_off":
    chk(names() == [], "events %s" % names())
    chk(all(s["wind"]["active"] is False for s in snaps.values()), "wind active")
    chk(all(near(a, b, 1e-3) for a, b in zip(P(2150), (0, 0, -20))), "player moved %s" % P(2150))
# ---------------- pause ----------------
elif name == "pa01_pause":
    chk(names(False) == [(1, "night_start"), (6, "paused"), (21, "resumed")], "events %s" % names(False))
    for t in range(6, 21):
        s = S(t)
        chk(s["state"] == "paused" and s["sim_tick"] == 5 and near(s["player"]["pos"][2], 0.5) and near(s["time_left_s"], 240 - 5 / 60, 0.001), "paused tick %d %s" % (t, (s["state"], s["sim_tick"], s["player"]["pos"])))
    chk(S(5)["state"] == "playing" and S(21)["state"] == "playing", "state around")
    chk(S(21)["sim_tick"] == 6 and near(P(21)[2], 0.6), "tick 21 %s" % P(21))
    chk(S(40)["sim_tick"] == 25 and near(P(40)[2], 2.5) and near(S(40)["time_left_s"], 240 - 25 / 60, 0.001), "tick 40")
    chk(S(40)["tick"] == 40, "tick field")
# ---------------- nights / dawn / boundaries ----------------
elif name in ("n01_night_start", "n02_night_start", "n03_night_start"):
    k = int(name[2])
    chk(names(False) == [(1, "night_start")] and ev("night_start")[0]["data"] == {"night": k}, "events %s" % names(False))
    chk(S(0)["night"] == k and near(S(0)["time_left_s"], {1: 240.0, 2: 270.0, 3: 300.0}[k], 1e-3), "snapshot 0")
elif name == "n04_charms_replace":
    chk(all(s["charms"] == [] for s in snaps.values()), "charms not replaced: %s" % S(0)["charms"])
elif name in ("t01_dawn_n1", "t02_dawn_n2", "t03_dawn_n3"):
    k = int(name[2])
    n = {1: 14400, 2: 16200, 3: 18000}[k]   # P3 (v1.2): Dem 240/270/300 s
    chk(names() == [(n, "game_over")] and ev("game_over")[0]["data"] == {"result": "lost", "reason": "dawn"}, "events %s" % names())
    final("lost", n, 0)
    chk(S(n)["state"] == "lost" and near(S(n)["time_left_s"], 0.0, 0.001), "last snapshot")
elif name == "tb01_ticks0_n3":
    chk(len(rows) == 2 and rows[0]["type"] == "snapshot" and rows[0]["tick"] == 0 and rows[0]["night"] == 3, "rows")
    final("playing", 0, 0)
    chk(near(S(0)["time_left_s"], 300.0, 1e-3), "time_left (v1.2: Dem 3 = 300 s)")
elif name == "tb02_dawn_tick59":
    chk(names() == [], "events %s" % names())
    final("playing", 59, 0)
elif name == "tb03_dawn_tick60":
    chk(names() == [(60, "game_over")] and ev("game_over")[0]["data"] == {"result": "lost", "reason": "dawn"}, "events %s" % names())
    final("lost", 60, 0)
# ---------------- win / lose precedence ----------------
elif name == "v01_win_beats_dawn_n2":
    chk(names() == [(60, "deposit"), (60, "lantern_lit"), (60, "game_over")], "events %s" % names())
    chk(ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 3, "deposited": 10}, "deposit")
    # P3 (v1.2): tick 60 = binh minh, 6/6 sang >= 4 -> dawn_survived. 3*5 + 100 + 5*(50+99) + (50+100) + 50*3
    chk(ev("game_over")[0]["data"] == {"result": "won", "reason": "dawn_survived"}, "game_over")
    final("won", 60, 1160)
elif name == "v02_win_bonus_n3":
    # P3 (v1.2): thap du 7/7 KHONG thang som (TICKET-03 muc 3); 10*5 + 100
    chk(names() == [(1, "deposit"), (1, "lantern_lit")], "events %s" % names())
    chk(ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 10, "deposited": 10}, "deposit")
    chk(ev("lantern_lit")[0]["data"] == {"lantern_id": "L1", "relight": False}, "lit")
    final("playing", 10, 150)
elif name == "v03_nofl_beats_win":
    go = ev("game_over")
    chk(len(go) == 1 and go[0]["data"] == {"result": "lost", "reason": "no_flames"}, "game_over %s" % [e["data"] for e in go])
    chk(end.get("state") == "lost", "end state %s" % end.get("state"))
else:
    errs.append("unknown set %s" % name)

if errs:
    print("; ".join(errs))
    sys.exit(1)
