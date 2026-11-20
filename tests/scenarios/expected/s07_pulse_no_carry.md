# s07_pulse_no_carry
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s07_pulse_no_carry.scenario.json`, `s07_pulse_no_carry.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 1 (<pulse_cost 3), shade (4,0,0); pulse tick 0; ticks 30.

Expected: Khong event pulse, carried van 1, score 0. Shade duoi: x=4-30*0.066667=2.0 tai tick 30 (cham can x<=1 tuc tick 45). flames 3. End: playing, 30, 0.
