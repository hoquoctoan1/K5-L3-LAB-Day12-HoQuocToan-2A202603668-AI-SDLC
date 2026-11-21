# s04_deposit_partial
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s04_deposit_partial.scenario.json`, `s04_deposit_partial.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 3, L1 at (0,0,2) deposited 0, interact tick 0; ticks 30.

Expected: dist 2 <= 2.5. amount=min(3,5-0)=3. Event tick 1: `deposit {L1,3,3}`. Khong lantern_lit. L1 lit=false, deposited 3, carried 0. End: playing, 30, 0.

## P3 (contract v1.2) - dap an moi
TICKET-03 muc 5: +5 moi mote nap. 3 mote -> score 15 (v1.1: 0).
