# s12_no_entities_yaw90
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s12_no_entities_yaw90.scenario.json`, `s12_no_entities_yaw90.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: motes [], shades []; move [0,1], cam_yaw 90; ticks 300.

Expected: x'=x cos90+z sin90=1, z'=~0 => di +X. x=0.1*300=30.0, z=0. Khong event, shades [], motes_active 0. End: playing, 300, 0.
