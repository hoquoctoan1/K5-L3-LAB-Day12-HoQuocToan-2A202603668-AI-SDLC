# s09_loss_no_flames
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s09_loss_no_flames.scenario.json`, `s09_loss_no_flames.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: flames 1, carried 0, shade (2.05,0,0); ticks 600.

Expected: Tick 16: `player_hit {shade, flames 0, dropped 0}` roi `game_over {lost, no_flames}` cung tick 16. Game dung ngay: End: lost, ticks 16, score 0 (khong thuong khi thua).
