# d01_dash

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 1, player (0,0,0) facing +Z. Dash 14 m/s x 12 ticks = 12*14/60 = 2.8 m; cooldown 90 ticks from dash start.
Input t0: move +Z + dash. Dash at step 0 -> event `dash` tick 1; z after 12 steps (snapshot tick 12) = 2.8; z(1)=14/60=0.2333.
cd set to 90 at step 0, minus 1 per step: snapshot tick t shows (91-t)/60 s -> tick 1 = 1.5, tick 31 = 1.0, tick 45 = 0.7667.
Press at t30: cd>0 -> ignored (no event). Press at t90: cd has reached 0 at that step -> allowed, event `dash` tick 91.
Events (besides night_start): dash@1, dash@91. End playing 120 score 0.
