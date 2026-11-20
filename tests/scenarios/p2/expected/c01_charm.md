# c01_charm

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 2. Start 2.05 m from charm at 6 m/s: distance 2.05-0.1n <=1.0 at n=11 -> event charm_picked@11 {C1, charm_ticks 600}. charm_s(11)=10.0; charm_s(t)=(611-t)/60, 0 from tick 611.
Charm speed 7.2 m/s: x(11)=34.05; x(41)=34.05+30*0.12=37.65 (+-0.05). Charm snapshot: available false, respawn_s(11)=45.0 (2700 ticks); available true again at tick 2711 (false at 2710, true at 2715).
Charm not re-picked (player ~38.7 m, 3.7 m away from 35).
