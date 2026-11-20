# s03_full_no_pickup
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s03_full_no_pickup.scenario.json`, `s03_full_no_pickup.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 5 (= capacity), mote (0,0,0.5) trong ban kinh; ticks 60.

Expected: Khong event. carried 5, motes_active 1 (mote khong bi nhat). End: playing, 60, 0.
