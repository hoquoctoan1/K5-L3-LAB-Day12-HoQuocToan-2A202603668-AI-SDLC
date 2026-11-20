# s02_pick_mote
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s02_pick_mote.scenario.json`, `s02_pick_mote.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: Mote (0,0,5.05); move [0,1] tu tick 0; ticks 60.

Expected: z sau n buoc = 0.1n. Nhat khi 5.05-z <= 1.2 => z>=3.85 => n=39 (n=38: dist 1.25 > 1.2). Event `mote_picked {carried:1}` tick 39. Score 10. Tick 60: z=6.0, carried 1, motes_active 0. End: playing, 60, 10.
