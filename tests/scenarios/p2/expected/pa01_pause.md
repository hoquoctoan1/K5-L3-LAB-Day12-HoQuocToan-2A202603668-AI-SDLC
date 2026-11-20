# pa01_pause

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 1. Walk +Z 0.1/tick. t5 pause press: tick 6 event paused, state paused, sim_tick stays 5. Ticks 6..20 advance (tick) but sim_tick 5, z 0.5, time_left 300-5/60 = 299.9167 frozen.
t20 press while paused: event resumed@21 and that step runs: sim_tick 6, z 0.6, state playing. Afterwards sim_tick(t)=t-15, z(40)=2.5, time_left(40)=300-25/60.
Events: night_start@1, paused@6, resumed@21. Run 40 ticks. state "paused" for ticks 6..20; "playing" otherwise.
