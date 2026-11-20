# j01_pad_night2

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 2 pad (20,0,18) r1, launch vy 14, horizontal 24 m/s toward island B centre (70,0,0): dir=(50,-18)/53.15.
Flight time 2*14/20 = 1.4 s = 84 ticks (discrete: lands at tick 84; accept 83..86). Horizontal ~ 24*1.4=33.6 m -> landing about (51.5,0,6.7) (accept +-1.2).
Inside island B (dist to (70,0,0) < 28), grounded, y 0. Apex ~4.9 m (tick 42 within 0.3). Keys do not override velocity (no input anyway).
Pos after landing stays (no input). No events but night_start.
