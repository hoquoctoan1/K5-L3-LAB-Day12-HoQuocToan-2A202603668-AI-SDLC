# s05_deposit_lights
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s05_deposit_lights.scenario.json`, `s05_deposit_lights.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 8, L1 deposited 2 at (0,0,2), interact tick 0; ticks 30.

Expected: amount=min(8,10-2)=8 => deposited 10. Tick 1: `deposit {L1,8,10}` roi `lantern_lit {L1}` (thu tu D5). Score +100. Chi 1/5 den sang nen chua thang. End: playing, 30, 100.
