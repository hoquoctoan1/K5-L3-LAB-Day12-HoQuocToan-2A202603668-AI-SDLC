# s10_win_all_lit
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s10_win_all_lit.scenario.json`, `s10_win_all_lit.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: L2..L5 lit:true (khong diem), L1 (0,0,2) deposited 0; carried 9, mote (0,0,0.5); time_left 100; interact tick 0.

Expected: Tick 1 theo thu tu: `mote_picked {10}` (+10, Phase 1 cong khi nhat; xem requests.md R1), `deposit {L1,10,10}`, `lantern_lit {L1}` (+100), `game_over {won, all_lit}`. Thang: remaining_ticks=6000-1=5999, secs=floor(5999/60)=99. Score = 10+100+50*3+2*99 = 458. L2..L5 dat san khong +100. End: won, 1, 458.
