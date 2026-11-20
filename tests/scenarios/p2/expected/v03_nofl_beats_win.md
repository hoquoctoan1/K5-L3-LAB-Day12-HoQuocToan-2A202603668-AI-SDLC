# v03_nofl_beats_win

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Fall (as f01, event tick 63 = step 62) on the same step that the last lantern is lit: flames 1 -> 0 and all lit.
Step 62: player falls (player_hit flames 0), deposit 10 lights L1 (+100), step 11: no_flames beats all_lit.
Events at tick 63 in order: player_hit {by fall, flames 0, dropped 0, lost 10} (the fall empties carried BEFORE the lantern step, so deposit may not happen; accepted outcome: lost no_flames, no win).
Assertions: game_over {lost, no_flames}; end state lost; no won.
