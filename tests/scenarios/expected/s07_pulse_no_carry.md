# s07_pulse_no_carry
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s07_pulse_no_carry.scenario.json`, `s07_pulse_no_carry.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 1 (<pulse_cost 2), shade (4,0,0); pulse tick 0; ticks 30.

Expected: Khong event pulse, carried van 1, score 0. Shade duoi: x=4-30*0.058333=2.25 tai tick 30 (chua cham: cham can x<=1 tuc tick 52). flames 3. End: playing, 30, 0.
