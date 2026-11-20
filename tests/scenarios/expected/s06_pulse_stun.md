# s06_pulse_stun
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s06_pulse_stun.scenario.json`, `s06_pulse_stun.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 4, shade S1 (4,0,0) (dist 4 <= 5); pulse tick 0; ticks 60.

Expected: Tick 1: `pulse {stunned_ids:[S1]}`; carried 4-3=1; score +5. Shade bi day ra 4 m => x=8.0, state stunned 2s (=120 tick) nen tick 60 van stunned, dung yen. End: playing, 60, 5.
