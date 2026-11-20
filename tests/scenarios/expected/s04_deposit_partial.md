# s04_deposit_partial
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s04_deposit_partial.scenario.json`, `s04_deposit_partial.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 3, L1 at (0,0,2) deposited 0, interact tick 0; ticks 30.

Expected: dist 2 <= 2.5. amount=min(3,5-0)=3. Event tick 1: `deposit {L1,3,3}`. Khong lantern_lit. L1 lit=false, deposited 3, carried 0. End: playing, 30, 0.
