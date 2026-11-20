# dr01_steal

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 2. carried 6 >=5 and 10 m <=15: idle->chase at step 0 (tick 1 state chase). Speed 7/60=0.11667/tick toward player: distance 10-0.11667*n <=1.2 first at n=76 (n=75: 1.25).
Steal at step 75 -> event drifter_steal@76 {D1, amount min(3,6)=3, carried 3}; D1 flee stolen 3, once per drifter. No flame loss (flames 3), score 0.
Flee 240 ticks (7 m/s away): state removed at tick ~316 (accept 314..318), absent at tick 320. carried 3 to the end. Only one steal.
