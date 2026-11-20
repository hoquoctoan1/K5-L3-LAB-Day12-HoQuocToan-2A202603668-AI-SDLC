# f01_fall_flames

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 1 island radius 40. Start (39.7,0,0), carried 4, flames 3. Move +X: x=40.1 at tick 4 -> outside island, falls.
Fall (g=20): y<-10 after n steps where (20/3600)*n(n+1)/2 > 10 -> n=60 -> event about tick 63 (accept 60..66), exactly once.
Event player_hit {by:fall, flames:2, dropped:0, lost:4}. After it: flames 2, carried 0.
Wait 60 ticks (y stays < -10 at F+30 and F+59), then at tick F+60 respawn at start (0,0,0), vel 0, grounded, invuln 90 ticks = 1.5 s.
invuln(F+60+k)=(90-k)/60 -> >0 at F+149, 0 at F+151. No other events (no pickup). End playing.
