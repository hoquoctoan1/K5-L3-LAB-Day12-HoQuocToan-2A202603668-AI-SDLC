# s03_full_no_pickup
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s03_full_no_pickup.scenario.json`, `s03_full_no_pickup.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 10 (= capacity 10), mote (0,0,0.5) trong ban kinh; ticks 60.

Expected: Khong event. carried 10, motes_active 1 (mote khong bi nhat). End: playing, 60, 0.
