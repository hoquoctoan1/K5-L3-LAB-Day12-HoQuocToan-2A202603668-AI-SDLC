# s11_loss_dawn_t60
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s11_loss_dawn_t60.scenario.json`, `s11_loss_dawn_t60.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: time_left_s 1, khong shade/mote; ticks 600.

Expected: Tong 60 tick. Buoc 59 => tick 60: `game_over {lost, dawn}`. End: lost, ticks 60, score 0.
