# Kiem tra khang dinh tay (hand-derived) cho moi scenario. Dung: python -I check.py <name> <out.jsonl>
# Dap an lay tu luat + GameConfig, xem expected/<name>.md. KHONG sua cho khop output.
import json, sys

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

def names():
    return [(e["tick"], e["name"]) for e in evs]

def final(state, ticks, score):
    chk(end["type"] == "end", "last line not end")
    chk(end.get("state") == state, "end.state=%r want %r" % (end.get("state"), state))
    chk(end.get("ticks") == ticks, "end.ticks=%r want %r" % (end.get("ticks"), ticks))
    chk(end.get("score") == score, "end.score=%r want %r" % (end.get("score"), score))

def snap(t):
    s = snaps.get(t)
    chk(s is not None, "missing snapshot tick %d" % t)
    return s or {"player": {"pos": [0, 0, 0], "carried": -1, "flames": -1}, "shades": [{"state": "?", "pos": [0, 0, 0]}], "lanterns": [{"id": "L1", "lit": None, "deposited": -1}], "score": -1, "time_left_s": -1, "motes_active": -1}

if name == "s01_idle":
    chk(evs == [], "expected no events, got %s" % names())
    final("playing", 120, 0)
    s = snap(120)
    chk(all(near(a, 0, 1e-3) for a in s["player"]["pos"]), "player moved")
    chk(near(s["time_left_s"], 298.0, 1e-3), "time_left")
elif name == "s02_pick_mote":
    chk(names() == [(39, "mote_picked")], "events %s" % names())
    chk(ev("mote_picked") and ev("mote_picked")[0]["data"] == {"carried": 1}, "data")
    final("playing", 60, 10)
    s = snap(60)
    chk(s["player"]["carried"] == 1 and near(s["player"]["pos"][2], 6.0), "snap60 %s" % s["player"])
    chk(s["motes_active"] == 0, "motes_active")
elif name == "s03_full_no_pickup":
    chk(evs == [], "events %s" % names())
    final("playing", 60, 0)
    s = snap(60)
    chk(s["player"]["carried"] == 5 and s["motes_active"] == 1, "carried/motes")
elif name == "s04_deposit_partial":
    chk(names() == [(1, "deposit")], "events %s" % names())
    chk(ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 3, "deposited": 3}, "deposit data")
    final("playing", 30, 0)
    s = snap(30)
    l1 = [l for l in s["lanterns"] if l["id"] == "L1"][0]
    chk(l1["deposited"] == 3 and l1["lit"] is False and s["player"]["carried"] == 0, "state")
elif name == "s05_deposit_lights":
    chk(names() == [(1, "deposit"), (1, "lantern_lit")], "events %s" % names())
    chk(ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 3, "deposited": 5}, "deposit data")
    chk(ev("lantern_lit")[0]["data"] == {"lantern_id": "L1"}, "lit data")
    final("playing", 30, 100)
    chk([l for l in snap(30)["lanterns"] if l["id"] == "L1"][0]["lit"] is True, "L1 lit")
elif name == "s06_pulse_stun":
    chk(names() == [(1, "pulse")], "events %s" % names())
    chk(ev("pulse")[0]["data"] == {"stunned_ids": ["S1"]}, "pulse data")
    final("playing", 60, 5)
    s = snap(60)
    sh = s["shades"][0]
    chk(s["player"]["carried"] == 1, "carried")
    chk(sh["state"] == "stunned" and near(sh["pos"][0], 7.0) and near(sh["pos"][2], 0.0), "shade %s" % sh)
elif name == "s07_pulse_no_carry":
    chk(names() == [], "events %s" % names())
    final("playing", 30, 0)
    s = snap(30)
    sh = s["shades"][0]
    chk(s["player"]["carried"] == 1 and s["player"]["flames"] == 3, "player")
    chk(sh["state"] != "stunned" and near(sh["pos"][0], 2.25), "shade %s" % sh)
elif name == "s08_shade_hit_invuln":
    hits = ev("player_hit")
    chk(len(hits) == 2, "hits=%d want 2" % len(hits))
    if len(hits) == 2:
        chk(hits[0]["tick"] == 18 and hits[0]["data"] == {"by": "shade", "flames": 2, "dropped": 2}, "hit1 %s" % hits[0])
        chk(hits[1]["tick"] in (108, 109) and hits[1]["data"] == {"by": "shade", "flames": 1, "dropped": 1}, "hit2 %s" % hits[1])
    chk(len(evs) == len(hits), "extra events %s" % names())
    final("playing", 150, 0)
    chk(snap(80)["player"]["flames"] == 2 and snap(80)["player"]["carried"] == 2, "snap80")
    chk(snap(150)["player"]["flames"] == 1 and snap(150)["player"]["carried"] == 1, "snap150")
elif name == "s09_loss_no_flames":
    chk(names() == [(18, "player_hit"), (18, "game_over")], "events %s" % names())
    chk(ev("player_hit")[0]["data"] == {"by": "shade", "flames": 0, "dropped": 0}, "hit data")
    chk(ev("game_over")[0]["data"] == {"result": "lost", "reason": "no_flames"}, "go data")
    final("lost", 18, 0)
elif name == "s10_win_all_lit":
    chk(names() == [(1, "mote_picked"), (1, "deposit"), (1, "lantern_lit"), (1, "game_over")], "events %s" % names())
    chk(ev("mote_picked")[0]["data"] == {"carried": 5}, "mote data")
    chk(ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 5, "deposited": 5}, "deposit data")
    chk(ev("game_over")[0]["data"] == {"result": "won", "reason": "all_lit"}, "go data")
    final("won", 1, 359)
elif name == "s11_loss_dawn_t60":
    chk(names() == [(60, "game_over")], "events %s" % names())
    chk(ev("game_over")[0]["data"] == {"result": "lost", "reason": "dawn"}, "go data")
    final("lost", 60, 0)
elif name == "s12_no_entities_yaw90":
    chk(evs == [], "events %s" % names())
    final("playing", 300, 0)
    s = snap(300)
    p = s["player"]["pos"]
    chk(near(p[0], 30.0) and near(p[2], 0.0) and s["shades"] == [] and s["motes_active"] == 0, "snap300 %s" % p)
elif name == "s13_diagonal":
    chk(evs == [], "events")
    final("playing", 60, 0)
    p = snap(60)["player"]["pos"]
    chk(near(p[0], 4.2426) and near(p[2], 4.2426), "pos %s" % p)
elif name == "s14_ticks_zero":
    chk(evs == [], "events")
    chk(len(rows) == 2 and rows[0]["type"] == "snapshot" and rows[0]["tick"] == 0, "rows %d" % len(rows))
    final("playing", 0, 0)
    s = snap(0)
    chk(all(a == 0 for a in s["player"]["pos"]) and near(s["time_left_s"], 300.0, 1e-3) and s["motes_active"] == 1 and len(s["shades"]) == 1, "snap0")
elif name == "s15_dawn_ticks59":
    chk(evs == [], "events %s" % names())
    final("playing", 59, 0)
    chk(near(snap(50)["time_left_s"], 1 - 50 / 60, 1e-3), "time_left@50")
elif name == "s16_nofl_beats_dawn":
    chk(names() == [(18, "player_hit"), (18, "game_over")], "events %s" % names())
    chk(ev("game_over")[0]["data"] == {"result": "lost", "reason": "no_flames"}, "go data")
    final("lost", 18, 0)
elif name == "s17_win_beats_dawn":
    chk(names() == [(1, "deposit"), (1, "lantern_lit"), (1, "game_over")], "events %s" % names())
    chk(ev("game_over")[0]["data"] == {"result": "won", "reason": "all_lit"}, "go data")
    final("won", 1, 250)
else:
    errs.append("unknown set " + name)

if errs:
    print("; ".join(errs))
    sys.exit(1)
