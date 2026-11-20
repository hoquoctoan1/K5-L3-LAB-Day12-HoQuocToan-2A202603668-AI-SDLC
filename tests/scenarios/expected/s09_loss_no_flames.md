# s09_loss_no_flames
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s09_loss_no_flames.scenario.json`, `s09_loss_no_flames.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: flames 1, carried 0, shade (2,0,0); ticks 600.

Expected: Tick 18: `player_hit {shade, flames 0, dropped 0}` roi `game_over {lost, no_flames}` cung tick 18. Game dung ngay: End: lost, ticks 18, score 0 (khong thuong khi thua).
