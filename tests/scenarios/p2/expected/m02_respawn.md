# m02_respawn

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

random_motes true with one explicit mote (so no 20 initial). Respawn: first at tick 240, then every 240, 1 per time on a free point (rings r=12 or r=33).
motes_active: tick 239 = 1, tick 240 = 2, tick 479 = 2, tick 480 = 3. New motes kind random, ttl_s -1. No events.
