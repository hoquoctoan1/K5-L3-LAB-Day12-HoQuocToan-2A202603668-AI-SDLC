# s10_win_all_lit
Tuning (GameConfig): speed 6 (0.1 m/tick), carry_cap 5, lantern_cost 5, pickup_r 1.2, interact_r 2.5, pulse_cost 2, pulse_r 6, push 3, stun 3s, invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 3.5 (0.05833 m/tick), hit_r 1, safe_r 5, score: mote 10, lantern 100, stun 5, sec_left 1, flame_left 50. Seed 1.
Files: `s10_win_all_lit.scenario.json`, `s10_win_all_lit.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: L2..L5 lit:true (khong diem), L1 (0,0,2) deposited 0; carried 4, mote (0,0,0.5); time_left 100; interact tick 0.

Expected: Tick 1 theo thu tu: `mote_picked {5}` (+10), `deposit {L1,5,5}`, `lantern_lit {L1}` (+100), `game_over {won, all_lit}`. Thang: remaining_ticks=6000-1=5999, secs=floor(5999/60)=99. Score = 10+100+50*3+1*99 = 359. L2..L5 dat san khong +100. End: won, 1, 359.
