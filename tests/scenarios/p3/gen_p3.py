# Sinh scenario/inputs Phase 3 (contract v1.2). Dung: python -I gen_p3.py  (ghi de file .json trong thu muc nay)
import json, os
D = os.path.dirname(os.path.abspath(__file__))
BASE = {"random_motes": False, "random_shades": False, "random_drifters": False, "wind_enabled": False,
        "motes": [], "shades": [], "drifters": [], "charms": []}
def put(name, sc, frames):
    d = dict(BASE); d.update(sc)
    json.dump(d, open(os.path.join(D, name + ".scenario.json"), "w"), separators=(",", ":"))
    json.dump({"frames": frames}, open(os.path.join(D, name + ".inputs.json"), "w"), separators=(",", ":"))
FAR = {"pos": [0, 0, 0], "carried": 0, "flames": 3}
WEAK = {"id": "L1", "pos": [0, 0, 20], "lit": True, "fuel": 20}
# hao dau toi tat
put("f01_decay_out", {"player": FAR, "lanterns": [{"id": "L1", "pos": [20, 0, 0], "lit": True, "fuel": 1.0}]}, [])
# cham dau 2 lan (3 mote roi 1 mote), den sang gan hon den chua sang van duoc chon vi chua day
put("f02_refuel", {"player": {"pos": [0, 0, 0], "carried": 5, "flames": 3},
    "lanterns": [{"id": "L1", "pos": [0, 0, 1], "lit": True, "fuel": 73.4}, {"id": "L2", "pos": [0, 0, 1.5]}]},
    [{"tick": 0, "interact": True}, {"tick": 1, "interact": False}, {"tick": 2, "interact": True}])
# thap lai can 5, suc chua tang len 12
put("f04_relight", {"player": {"pos": [0, 0, 0], "carried": 7, "flames": 3},
    "lanterns": [{"id": "L1", "pos": [0, 0, 1], "lit": False, "ever_lit": True}]}, [{"tick": 0, "interact": True}])
# suc chua toi da 20
put("c01_capacity_20", {"player": {"pos": [0, 0, 0], "carried": 19, "flames": 3, "successful_lights": 5},
    "motes": [[0, 0, 0.5], [0, 0, 0.6]]}, [])
# Bong Muc wander toi den yeu roi hut (1 con / 2 con)
put("d01_drain_one", {"player": FAR, "lanterns": [WEAK], "shades": [{"id": "S1", "pos": [3, 0, 20], "state": "wander"}]}, [])
put("d02_drain_two", {"player": FAR, "lanterns": [WEAK], "shades": [{"id": "S1", "pos": [3, 0, 20], "state": "wander"},
    {"id": "S2", "pos": [-3, 0, 20], "state": "wander"}]}, [])
# drain -> chase khi May vao 6 m
put("d03_drain_to_chase", {"player": {"pos": [0, 0, 28], "carried": 0, "flames": 3}, "lanterns": [WEAK],
    "shades": [{"id": "S1", "pos": [0, 0, 21.5], "state": "drain", "target_lantern_id": "L1"}]},
    [{"tick": 0, "move": [0, -1]}, {"tick": 10, "move": [0, 0]}])
# pulse trung con dang drain: +15
put("d04_pulse_drain", {"player": {"pos": [0, 0, 25.5], "carried": 3, "flames": 3}, "lanterns": [WEAK],
    "shades": [{"id": "S1", "pos": [0, 0, 21.5], "state": "drain", "target_lantern_id": "L1"}]}, [{"tick": 0, "pulse": True}])
# cham dau len >= 30 khi co Bong Muc trong 6 m: day ra, khong sat thuong
put("d05_refuel_push", {"player": {"pos": [0, 0, 18.5], "carried": 3, "flames": 3}, "lanterns": [WEAK],
    "shades": [{"id": "S1", "pos": [0, 0, 21.5], "state": "drain", "target_lantern_id": "L1"}]}, [{"tick": 0, "interact": True}])
# luat thang binh minh
put("w01_dawn_win_3of5", {"player": FAR, "time_left_s": 1.0,
    "lanterns": [{"id": "L1", "lit": True}, {"id": "L2", "lit": True}, {"id": "L3", "lit": True}]}, [])
put("w02_dawn_lose_2of5", {"player": FAR, "time_left_s": 1.0, "lanterns": [{"id": "L1", "lit": True}, {"id": "L2", "lit": True}]}, [])
put("w03_noflames_at_dawn", {"player": {"pos": [0, 0, 0], "carried": 0, "flames": 0}, "time_left_s": 0.0166666667,
    "lanterns": [{"id": "L%d" % i, "lit": True} for i in range(1, 6)]}, [])
put("w04_n3_win_5of7", {"time_left_s": 1.0, "lanterns": [{"id": "L%d" % i, "lit": True} for i in range(1, 6)]}, [])
put("w05_out_at_dawn", {"player": FAR, "time_left_s": 1.0,
    "lanterns": [{"id": "L1", "lit": True}, {"id": "L2", "lit": True}, {"id": "L3", "lit": True, "fuel": 1.0}]}, [])
# scenario sai -> exit 2
put("e01_bad_fuel", {"lanterns": [{"id": "L1", "lit": True, "fuel": 101}]}, [])
put("e02_bad_target", {"lanterns": [WEAK], "shades": [{"id": "S1", "pos": [3, 0, 20], "state": "drain", "target_lantern_id": "L9"}]}, [])
put("e03_bad_ever_lit", {"lanterns": [{"id": "L1", "ever_lit": "yes"}]}, [])
