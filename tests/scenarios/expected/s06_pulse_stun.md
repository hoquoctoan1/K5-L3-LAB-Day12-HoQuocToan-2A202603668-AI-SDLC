# s06_pulse_stun
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s06_pulse_stun.scenario.json`, `s06_pulse_stun.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 3, shade S1 (4,0,0) (dist 4 <= 6); pulse tick 0; ticks 60.

Expected: Tick 1: `pulse {stunned_ids:[S1]}`; carried 3-2=1; score +5. Shade bi day ra 3 m => x=7.0, state stunned 3s (=180 tick) nen tick 60 van stunned, dung yen. End: playing, 60, 5.
