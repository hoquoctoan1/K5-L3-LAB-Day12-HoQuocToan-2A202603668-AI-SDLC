# h01_shade_hit

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Shade speed 4/60=0.0667/tick. 1.25-0.0667*3=1.05 >1; 4 moves -> 0.983 <=1: hit at step 3 -> event tick 4 player_hit {by shade, flames 2, dropped floor(7/2)=3}. carried 7-3=4.
3 dropped motes kind dropped, ids m1..m3, ring 1.5..2.5 m around player, ttl_s(4)=8.0 (480 ticks), ttl_s(64)=7.0. invuln(4)=1.5, invuln(64)=0.5.
Recoil: state recoil at tick 5; shade pushed 2 m away (+X): x(64)=0.983+2=2.98 (+-0.2). No second hit before tick 90 (invuln 90 ticks). Score 0.
