# s05_deposit_lights
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s05_deposit_lights.scenario.json`, `s05_deposit_lights.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 3, L1 deposited 2 at (0,0,2), interact tick 0; ticks 30.

Expected: amount=min(3,5-2)=3 => deposited 5. Tick 1: `deposit {L1,3,5}` roi `lantern_lit {L1}` (thu tu D5). Score +100. Chi 1/5 den sang nen chua thang. End: playing, 30, 100.
