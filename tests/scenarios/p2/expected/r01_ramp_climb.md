# r01_ramp_climb

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 3 ramp at 30 deg: foot r30 y0 -> top r24 y3, linear. Start at foot (25.98,0,15) (r=30), walk straight up the centre line at 6 m/s.
y rises 0.5 m per metre: tick 30 -> r=27, y=1.5 (+-0.2); tick 60 -> r=24, y=3.0; tick 70 -> r=23 on tier 1, y=3.0 (+-0.05). Never falls (no player_hit).
