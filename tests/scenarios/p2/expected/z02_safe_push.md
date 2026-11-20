# z02_safe_push

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Shade starts 3 m inside the lit lantern zone, touching the player. It is pushed out to the inner edge within 30 ticks with no damage, then blocked at the 6 m edge.
Assertions: no player_hit for the whole 200 ticks, flames 3, dist(shade,L1) >= 5.9 at tick 60 and tick 200.
