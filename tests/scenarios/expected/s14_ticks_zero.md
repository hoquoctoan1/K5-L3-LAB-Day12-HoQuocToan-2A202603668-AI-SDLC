# s14_ticks_zero
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s14_ticks_zero.scenario.json`, `s14_ticks_zero.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: --ticks 0, co input move; mote + shade (10,0,0).

Expected: Output dung 2 dong: snapshot tick 0 (player (0,0,0), time_left 300.0, motes_active 1, 1 shade) va `end {ticks 0, playing, 0}`. Input chua duoc ap.
