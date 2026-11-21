# s02_pick_mote
Tuning (GameConfig, Phase 2 v1.1): speed 6 (0.1 m/tick), carry_cap 10, lantern_cost 10, pickup_r 1.0, interact_r 2.0, pulse_cost 3, pulse_r 5, push 4, stun 2s (120 ticks), invuln 1.5s (90 ticks), drop_ratio 0.5, shade_speed 4.0 (0.066667 m/tick), hit_r 1, safe_r 6, score: mote 10, lantern 100, stun 5, sec_left 2, flame_left 50. Seed 1.
Files: `s02_pick_mote.scenario.json`, `s02_pick_mote.inputs.json`. Quy uoc tick: buoc k doc input k, event tick = k+1. Dap an suy ra BANG TAY tu luat, kiem bang `check.py`.

Setup: Mote (0,0,5.05); move [0,1] tu tick 0; ticks 60.

Expected: z sau n buoc = 0.1n. Nhat khi 5.05-z <= 1.0 => z>=4.05 => n=41 (n=40: dist 1.05 > 1.0). Event `mote_picked {carried:1}` tick 41. Score 10 (Phase 1: cong khi NHAT; xem docs/notes/requests.md R1). Tick 60: z=6.0, carried 1, motes_active 0. End: playing, 60, 10.

## P3 (contract v1.2) - dap an moi
TICKET-03 muc 5 THAY THE diem khi nhat: nhat khong cong diem. End score 10 -> 0.
