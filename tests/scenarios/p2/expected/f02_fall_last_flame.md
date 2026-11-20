# f02_fall_last_flame

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Same fall with flames 1: flames 0 -> lost immediately, no respawn. Events same tick F: player_hit {by fall, flames 0, dropped 0, lost 2} then game_over {lost, no_flames}.
End: lost, ticks=F, score 0. Last snapshot tick = F with y < -10.
