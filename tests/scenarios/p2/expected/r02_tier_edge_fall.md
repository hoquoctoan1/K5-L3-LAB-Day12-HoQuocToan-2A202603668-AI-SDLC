# r02_tier_edge_fall

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Tier 1 (y=3, annulus r 12..24, z>0) at (0,3,18) walk +Z: r=24 at tick 60; beyond that the vertical wall -> fall to tier 0 (y=0), 3 m drop (not off island): no player_hit.
y(60)=3.0, y never below 0, final y=0 grounded, z>24, flames 3, a snapshot exists with 0.1<y<2.9 and not grounded.
