# w01_wind

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Night 3, wind_enabled: strong wind every 1800 ticks, duration 300 ticks, push 2 m/s in random direction, warning 120 ticks before (not in snapshot).
wind.active false up to tick 1798, true from 1802 to 2098 (300 active snapshots +-1 in 1790..2110), false at >=2102. Player idle: displacement over the active window = 2 m/s * 5 s = 10 m (+-0.2),
direction = dir_deg (from +X toward +Z) +-3 deg [convention assumption]. Before wind player at (0,0,-20) exactly; no fall (stays within 30 m). No events but night_start.
