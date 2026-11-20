# d04_dash_charm

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Charm active (600 ticks): dash cooldown 0 but each dash needs a NEW press (false->true) and presses while dashing are ignored.
t0 press -> dash@1 (steps 0..11). t5 press during dash -> ignored. t12 press: dash finished -> dash@13. t30 press (held to end) -> dash@31 only once.
Expected events dash@1, dash@13, dash@31. dash_cd_s = 0 in every snapshot 1..60. z(12)=2.8. charm_s(1)=599/60=9.983.
