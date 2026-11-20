# s16_nofl_beats_dawn
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s16_nofl_beats_dawn.scenario.json`, `s16_nofl_beats_dawn.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: flames 1, shade (2.05,0,0), time_left_s 0.2666666667 (=16 tick), ticks 600.

Expected: Cung tick 16: dieu kien no_flames va dawn deu dung; uu tien no_flames (thang > no_flames > dawn). Events: `player_hit {shade,0,0}`, `game_over {lost, no_flames}`. End: lost, 16, 0. Ghi chu: 'thang + no_flames cung tick' khong the xay ra qua den cuoi, vi den vua sang day shade ra safe_radius truoc khi hit (xem s17 cho thang cung tick dawn).
