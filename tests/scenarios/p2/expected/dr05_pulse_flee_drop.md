# dr05_pulse_flee_drop

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Drifter fleeing with 3 stolen; pulse at 3D dist sqrt(16+0.64)=4.08 hits: drops all 3 at its place (ring 1.5..2.5 m around drifter): event drifter_drop@1 {D1, 3}; 3 dropped motes ttl 120 (drifter TTL), ttl_s(1)=2.0.
Motes expire: present at tick 115, absent at tick 125 (created at tick 1 with 120 ticks). stolen 0 afterwards. carried 3-3=0 stays 0 (motes >=1.5 m from player). Score 0.
