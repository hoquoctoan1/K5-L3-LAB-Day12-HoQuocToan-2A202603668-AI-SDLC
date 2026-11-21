# Kiem tra khang dinh tay (hand-derived) Phase 3 / contract v1.2. Dung: python -I check_p3.py <name> <out.jsonl>
# Dap an suy ra BANG TAY tu docs/notes/ticket-03.md (+ gia dinh Q1-Q9 trong docs/TASKS_P3.md). KHONG sua cho khop output.
# Don vi dau: 1 unit = 1/60 fuel; hao 1 unit/tick; moi Bong Muc drain 5 unit/tick; xuat = round_half_up(units/6)/10.
import json, math, sys

name, path = sys.argv[1], sys.argv[2]
rows = [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]
snaps = {r["tick"]: r for r in rows if r["type"] == "snapshot"}
evs = [r for r in rows if r["type"] == "event" and r["name"] != "night_start"]
end = rows[-1]
errs = []


def chk(c, msg):
    if not c:
        errs.append(msg)


def ev(n):
    return [e for e in evs if e["name"] == n]


def names():
    return [(e["tick"], e["name"]) for e in evs]


def final(state, ticks, score):
    chk(end["type"] == "end", "last line not end")
    chk(end.get("state") == state, "end.state=%r want %r" % (end.get("state"), state))
    chk(end.get("ticks") == ticks, "end.ticks=%r want %r" % (end.get("ticks"), ticks))
    chk(end.get("score") == score, "end.score=%r want %r" % (end.get("score"), score))


def S(t):
    s = snaps.get(t)
    chk(s is not None, "missing snapshot tick %d" % t)
    return s or {"lanterns": [], "shades": [], "player": {}, "score": -1, "night": -1, "motes_active": -1}


def lant(t, lid):
    for x in S(t)["lanterns"]:
        if x["id"] == lid:
            return x
    chk(False, "lantern %s missing at %d" % (lid, t))
    return {"lit": None, "fuel": -1, "ever_lit": None, "relit_count": -1, "deposited": -1}


def shade(t, sid):
    for x in S(t)["shades"]:
        if x["id"] == sid:
            return x
    chk(False, "shade %s missing at %d" % (sid, t))
    return {"state": "?", "pos": [0, 0, 0]}


def fuel_out(units):
    return ((units * 10 + 30) // 60) / 10.0


def dxz(a, b):
    return math.hypot(a[0] - b[0], a[2] - b[2])


L1POS = [0, 0, 20]


def drain_start(sid, lo=1, hi=200):
    for t in range(lo, hi + 1):
        if t in snaps and shade(t, sid)["state"] == "drain":
            return t
    return None


if name == "f01_decay_out":
    # fuel 1.0 = 60 unit, hao 1/tick -> tick 60 = 0 -> tat
    chk(names() == [(60, "lantern_out")], "events %s" % names())
    chk(ev("lantern_out") and ev("lantern_out")[0]["data"] == {"lantern_id": "L1"}, "data")
    chk(lant(30, "L1")["lit"] is True and lant(30, "L1")["fuel"] == 0.5, "tick30 fuel 0.5 %s" % lant(30, "L1"))
    chk(lant(59, "L1")["lit"] is True, "tick59 van sang")
    l = lant(60, "L1")
    chk(l["lit"] is False and l["fuel"] == 0.0 and l["ever_lit"] is True and l["deposited"] == 0, "tick60 tat %s" % l)
    final("playing", 70, 0)
elif name == "f02_refuel":
    # tick1: 4404-1=4403, thieu 1597 -> ceil(1597/600)=3 mote -> 6000. tick3: 5998, thieu 2 -> 1 mote.
    chk(names() == [(1, "refuel"), (3, "refuel")], "events %s" % names())
    r = ev("refuel")
    chk(len(r) == 2 and r[0]["data"] == {"lantern_id": "L1", "amount": 3, "fuel": 100.0}, "refuel1 %s" % r[:1])
    chk(len(r) == 2 and r[1]["data"] == {"lantern_id": "L1", "amount": 1, "fuel": 100.0}, "refuel2 %s" % r[1:])
    chk(S(3)["player"]["carried"] == 1 and lant(10, "L2")["deposited"] == 0, "carried/L2")
    chk(lant(10, "L1")["fuel"] == fuel_out(6000 - 7), "tick10 fuel %s" % lant(10, "L1"))
    final("playing", 10, 20)
elif name == "f04_relight":
    chk(names() == [(1, "deposit"), (1, "lantern_lit")], "events %s" % names())
    chk(ev("deposit")[0]["data"] == {"lantern_id": "L1", "amount": 5, "deposited": 5}, "deposit")
    chk(ev("lantern_lit")[0]["data"] == {"lantern_id": "L1", "relight": True}, "relight true")
    l = lant(1, "L1")
    chk(l["lit"] is True and l["fuel"] == 100.0 and l["relit_count"] == 1 and l["ever_lit"] is True, "L1 %s" % l)
    chk(S(1)["player"]["carried"] == 2 and S(1)["player"]["capacity"] == 12, "player %s" % S(1)["player"])
    chk(lant(5, "L1")["fuel"] == fuel_out(6000 - 4), "tick5 fuel")
    final("playing", 5, 5 * 5 + 40)
elif name == "c01_capacity_20":
    chk(names() == [(1, "mote_picked")] and ev("mote_picked")[0]["data"] == {"carried": 20}, "events %s" % names())
    p = S(1)["player"]
    chk(p["capacity"] == 20 and p["carried"] == 20 and S(1)["motes_active"] == 1, "player %s" % p)
    final("playing", 5, 0)
elif name in ("d01_drain_one", "d02_drain_two"):
    ids = ["S1"] if name == "d01_drain_one" else ["S1", "S2"]
    rate = 1 + 5 * len(ids)
    D = drain_start("S1")
    chk(D is not None and 29 <= D <= 31, "drain start %s" % D)
    if D:
        for sid in ids:
            chk(drain_start(sid) == D, "%s drain cung tick" % sid)
            chk(dxz(shade(D, sid)["pos"], L1POS) <= 2.0001 and dxz(shade(D - 1, sid)["pos"], L1POS) > 2.0, "%s vao 2 m dung tick" % sid)
        base = 1200 - D                       # fuel 20 = 1200 unit, hao 1/tick tu tick 1..D
        t_out = D + -(-base // rate)          # ceil(base / rate)
        want = []
        k = 1
        while D + 60 * k <= t_out:
            t = D + 60 * k
            for sid in ids:
                want.append((t, "fuel_drain", {"lantern_id": "L1", "shade_id": sid, "fuel": fuel_out(max(0, base - rate * 60 * k))}))
            k += 1
        want.append((t_out, "lantern_out", {"lantern_id": "L1"}))
        got = [(e["tick"], e["name"], e["data"]) for e in evs]
        chk(got == want, "events %s want %s" % (got, want))
        chk(lant(D + 10, "L1")["fuel"] == fuel_out(base - rate * 10), "fuel D+10 %s" % lant(D + 10, "L1"))
        for sid in ids:
            chk(shade(t_out, sid)["state"] == "wander", "%s ve wander khi den tat" % sid)
    final("playing", 300 if name == "d01_drain_one" else 200, 0)
elif name == "d03_drain_to_chase":
    chk(shade(1, "S1")["state"] == "drain" and lant(1, "L1")["fuel"] == fuel_out(1200 - 6), "tick1 drain, fuel 19.9")
    T = None
    for t in range(1, 21):
        if shade(t, "S1")["state"] == "chase":
            T = t
            break
    chk(T is not None, "khong chuyen chase")
    if T:
        chk(shade(T - 1, "S1")["state"] == "drain", "truoc do drain")
        chk(dxz(S(T)["player"]["pos"], shade(T - 1, "S1")["pos"]) <= 6.0 + 1e-3, "May trong 6 m luc chuyen")
        chk(dxz(S(T - 1)["player"]["pos"], shade(T - 1, "S1")["pos"]) > 6.0, "tick truoc ngoai 6 m")
    chk(ev("player_hit") == [], "khong hit")
elif name == "d04_pulse_drain":
    chk(names() == [(1, "pulse")] and ev("pulse")[0]["data"] == {"stunned_ids": ["S1"]}, "events %s" % names())
    chk(shade(1, "S1")["state"] == "stunned" and S(1)["score"] == 15, "stunned + 15")
    final("playing", 5, 15)
elif name == "d05_refuel_push":
    # tick1 buoc 2b: 1200 - 1 - 5 = 1194; cham 3 mote -> 2994 (>= 1800: co lai vung an toan)
    chk(names() == [(1, "refuel")], "events %s" % names())
    chk(ev("refuel") and ev("refuel")[0]["data"] == {"lantern_id": "L1", "amount": 3, "fuel": fuel_out(1194 + 1800)}, "refuel %s" % ev("refuel"))
    chk(shade(1, "S1")["state"] != "drain", "het drain sau cham len >= 30")
    chk(dxz(shade(31, "S1")["pos"], L1POS) >= 6.0 - 0.01, "bi day ra mep trong <= 30 tick: %s" % shade(31, "S1"))
    final("playing", 60, 15)
elif name == "w01_dawn_win_3of5":
    chk(names() == [(60, "game_over")] and ev("game_over")[0]["data"] == {"result": "won", "reason": "dawn_survived"}, "events %s" % names())
    final("won", 60, 3 * (50 + (6000 - 60) // 60) + 3 * 50)
elif name == "w02_dawn_lose_2of5":
    chk(names() == [(60, "game_over")] and ev("game_over")[0]["data"] == {"result": "lost", "reason": "dawn"}, "events %s" % names())
    final("lost", 60, 0)
elif name == "w03_noflames_at_dawn":
    chk(names() == [(1, "game_over")] and ev("game_over")[0]["data"] == {"result": "lost", "reason": "no_flames"}, "events %s" % names())
    final("lost", 1, 0)
elif name == "w04_n3_win_5of7":
    chk(S(0)["night"] == 3 and len(S(0)["lanterns"]) == 7, "Dem 3, 7 den")
    chk(bool(ev("game_over")) and ev("game_over")[0]["data"] == {"result": "won", "reason": "dawn_survived"}, "events %s" % names())
    final("won", 60, 5 * (50 + 99) + 3 * 50)
elif name == "w05_out_at_dawn":
    # L3 fuel 1.0 tat o buoc 2b tick 60 -> chi con 2/5 luc xet thang -> dawn
    chk(names() == [(60, "lantern_out"), (60, "game_over")], "events %s" % names())
    chk(bool(ev("game_over")) and ev("game_over")[0]["data"] == {"result": "lost", "reason": "dawn"}, "go")
    final("lost", 60, 0)
else:
    errs.append("unknown set " + name)

if errs:
    print("; ".join(errs))
    sys.exit(1)
