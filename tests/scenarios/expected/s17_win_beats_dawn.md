# s17_win_beats_dawn
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s17_win_beats_dawn.scenario.json`, `s17_win_beats_dawn.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: time_left_s 1/60 (1 tick), L2..L5 lit, L1 (0,0,2), carried 10, interact tick 0.

Expected: Tick 1: deposit {L1,10,10}, lantern_lit, game_over {won, all_lit} (thang uu tien hon dawn du remaining=0). Score = 100 + 50*3 + 2*floor(0)=250. End: won, 1, 250.
