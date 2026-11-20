# v02_win_bonus_n3

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 3, last lantern L1 at (0,6,6) (tier 2), player (0,6,5) carried 10: deposit 10 -> lit at tick 1 (steps=1): time left 6000-1=5999 ticks -> floor(5999/60)=99 s.
Score = 100 (lantern) + 99*2 + 50*2 flames = 398. Events deposit {L1,10,10}, lantern_lit, game_over {won, all_lit} at tick 1. End won,1,398.
