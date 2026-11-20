# s08_shade_hit_invuln
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s08_shade_hit_invuln.scenario.json`, `s08_shade_hit_invuln.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: carried 4, flames 3, shade S1 (2.05,0,0) dung yen ben canh (doi tu 2.0 de tranh bien chinh xac 1.0); ticks 150.

Expected: Khoang cach 2.05-0.066667n <=1 khi n=16 (n=15: 1.05). Event tick 16 `player_hit {shade, flames 2, dropped floor(4/2)=2}` => carried 2. Invuln 90 tick: hit 2 o tick 106 hoac 107 (sai so float tren bien): flames 1, dropped floor(2/2)=1, carried 1. Hit 3 ~tick 197 > 150. Snap 80: flames 2 carried 2. End: playing, 150, 0.
