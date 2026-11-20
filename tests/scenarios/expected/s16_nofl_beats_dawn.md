# s16_nofl_beats_dawn
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s16_nofl_beats_dawn.scenario.json`, `s16_nofl_beats_dawn.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: flames 1, shade (2,0,0), time_left_s 0.3 (=18 tick), ticks 600.

Expected: Cung tick 18: dieu kien no_flames va dawn deu dung; uu tien no_flames (thang > no_flames > dawn). Events: `player_hit {shade,0,0}`, `game_over {lost, no_flames}`. End: lost, 18, 0. Ghi chu: 'thang + no_flames cung tick' khong the xay ra qua den cuoi, vi den vua sang day shade ra safe_radius 5 truoc khi hit (xem s17 cho thang cung tick dawn).
