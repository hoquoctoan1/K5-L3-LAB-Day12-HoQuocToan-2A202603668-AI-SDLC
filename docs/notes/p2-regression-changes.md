# Regression Phase 1 -> so chuan Phase 2 (A0-P2)

Kiem: `timeout 150 $GODOT --headless --path godot --script res://tests/run_core_tests.gd` va `sh scripts/run_scenarios.sh`.

## Test don vi (godot/tests)
| File | Thay doi | Ly do |
|---|---|---|
| core/test_config.gd | contract_version doc tu `GameConfig.CONTRACT_VERSION` ("1.1"); them kiem khoa thua, 5 khoa moi, ticks dem, stream RNG, `height_at`, `sim_ticks` | contract v1.1 |
| core/test_mote_lantern.gd | nap dung `LANTERN_COST` (3 roi `C-3+2`); mote Y = `PICKUP_MAX_DY` | cost 5->10; pickup them dy<=1.5 (he thong Phase 1 van bo qua Y: B3) |
| core/test_pulse_system.gd | carried theo `PULSE_COST` | pulse_cost 2->3 (test cu dung carried 2 nen pulse khong kich hoat) |
| core/test_shade_system.gd | spawn sau `SHADE_SPAWN_INTERVAL_S*60+20` tick; `populate_initial` kiem mote (INITIAL_SHADES=0) | interval 20s->8s; shade dau do spawn v2 (B5) |
| core/test_sim.gd, headless/test_e2e.gd | carried = `LANTERN_COST`, amount/deposited theo config | cost 5->10 |

## Kich ban (tests/scenarios)
Moi `expected/*.md`: dong Tuning doi sang so chuan. Doi rieng:
| Kich ban | Doi | Ly do |
|---|---|---|
| s02 | mote tick 39 -> 41 | pickup 1.2 -> 1.0 |
| s03 | carried 5 -> 10 | capacity 10 |
| s05 | carried 3->8, deposit {8,10} | cost 10 |
| s06 | carried 3->4; shade x 7->8 | pulse_cost 3, push 4 |
| s07 | shade x 2.25 -> 2.0 | shade_speed 4.0 |
| s08 | shade (2,0,0)->(2.05,0,0); hit1 tick 18->16; hit2 (108,109)->(106,107) | speed 4.0; tranh bien chinh xac 1.0 (float32) |
| s09, s16 | shade (2.05); tick 18->16; s16 time_left 0.3 -> 0.2666666667 (16 tick) | nhu s08; giu "no_flames va dawn cung tick" |
| s10 | carried 4->9; deposit {10,10}; score 359 -> 458 | cost 10; bonus giay x2 (99*2). Van +10 khi nhat (requests R1) |
| s17 | carried 5->10 | cost 10 (score 250 giu nguyen) |
Giu nguyen: s01, s04, s11-s15, s18.

## Hang so khac doi (GameConfig) anh huong gian tiep
`INITIAL_MOTES` 30->20, `MOTE_RESPAWN_TICKS` 120->240 (tran 30 = `MOTE_CAP`; spawn_system doi `< INITIAL_MOTES` -> `< MOTE_CAP`), `INITIAL_SHADES` 3->0, `MAX_SHADES` 5->6, `SHADE_SPAWN_INTERVAL_S` 20->8, `ISLAND_RADIUS` 45->40, `GRAVITY` 18->20, `JUMP_SPEED` 6->7, `FALL_ENABLED` false->true.

## Sua code ngoai game_config/sim_state (toi thieu)
`sim.gd` (`seed_streams`, wind mac dinh, thoi gian theo `night_duration_s`), `spawn_system.gd` (dung `make_mote/make_shade`, tran `MOTE_CAP`).
