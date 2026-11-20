# s08_shade_hit_invuln
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s08_shade_hit_invuln.scenario.json`, `s08_shade_hit_invuln.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 4, flames 3, shade S1 (2,0,0) dung yen ben canh; ticks 150.

Expected: Khoang cach 2-0.058333n <=1 khi n=18 (n=17: 1.008). Event tick 18 `player_hit {shade, flames 2, dropped floor(4*0.5)=2}` => carried 2. Invuln 90 tick: khong hit lan nua toi tick ~108. Hit 2 o tick 108 hoac 109 (sai so float tren bien): flames 1, dropped floor(2*0.5)=1, carried 1. Hit 3 ~tick 199 > 150. Snap 80: flames 2 carried 2. End: playing, 150, 0.
