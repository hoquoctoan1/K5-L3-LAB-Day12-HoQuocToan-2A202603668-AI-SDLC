# E1 independent review (Test Contract v1.0, section F)

Runner: `GODOT=<4.7.2 console exe> scripts/headless.sh ...` (Git Bash), absolute `C:/...` paths for files. Probe inputs live in this folder (lit.sc.json, yaw*.json, pulse.*, b*.json, s*.json ...).

## Defects (ranked)
1. HIGH - Relative `--scenario/--inputs/--out` paths resolve against `godot/` (Godot's `--path` changes cwd), not the caller's cwd.
   Repro (repo root): `scripts/headless.sh --seed 1 --night 1 --scenario docs/evidence/phase-1/E1/lit.sc.json --ticks 5 --out x.jsonl` -> stderr "khong doc duoc file", exit 2 even though the file exists. `--out relout.jsonl` writes to `godot/relout.jsonl`. A grader passing relative paths gets exit 2 / missing output. Fix: wrapper should absolutize paths (or cd-safe resolution) before exec.
2. LOW/ambiguity - `random_motes:true` with `motes:[]` (or `random_shades:true` with `shades:[]`) still spawns random entities (30 motes / 3 shades observed), because Sim.begin treats empty list as "not specified". Contract D1 says `[]` = none. Only matters if a test pairs `true` with `[]`.
3. LOW - Invalid `--ticks`/`--snapshot-every` (negative, 0, non-numeric) and missing required args exit 1 (contract only says non-zero; acceptable). `--night 2` silently accepted (exit 0).
4. INFO - A game_over tick not divisible by snapshot-every gets no final snapshot (only the end line). Contract allows this.

## Checklist (all run unless noted)
| Item | Result | Evidence |
|---|---|---|
| game.contract.json keys/version/values | PASS (read) | all keys of section A present, version "1.0"; every tuning value + score.* equals GameConfig consts (compared by reading both files; no automated diff run) |
| team/build/run/headless cmds real | PASS (read) | headless_cmd `scripts/headless.sh` works; macOS/Linux run NOT VERIFIED here |
| README <=3 commands, GUI run | NOT VERIFIED | not in scope |
| Headless with all B params, no GPU | PASS | runs with `--headless`; exit 0 (but see defect 1 for relative paths) |
| Fixed 60 Hz, dt=1/60 | PASS | idle-ish run: tick 60 time_left_s 299.0; yaw90 moved exactly 6.0 m in 60 ticks (speed 6) |
| Snapshot tick 0 pre-input; events tick=k+1; ticks<=N | PASS | pulse at input tick 0 -> event tick 1; `--ticks 0` -> snapshot tick 0 + `end ticks 0`; dawn scenario ended at ticks 150 for time_left_s 2.5 |
| Stateful frames, tick strictly increasing, edge trigger | PASS | b2 (dup tick), b3 (decreasing), b7 (missing tick) -> exit 2; `pulse:true` held for 200 ticks (cooldown 120) produced exactly 1 pulse event |
| move outside [-1,1] | PASS | `[1.5,0]` and `[1,-1.0001]` -> exit 2 |
| cam_yaw rotation | PASS | yaw 90, move [1,0] -> pos z=-6.0 (formula: x'=0, z'=-1); yaw 45, move [0,1] -> (4.243,0,4.243) |
| Diagonal normalization | PASS (read) | input_decoder normalizes length>1; not run separately (authors' s13 not re-run by me) |
| Scenario preset lit:true -> no score/events | PASS | lit.sc.json: L1 lit at tick 0, score 0 and no events through tick 100 |
| lantern pos override / deposited | PASS | L2 pos [3,0,4], deposited 2 shown in snapshot |
| carried > capacity preset | PASS | carried 9 accepted and stays 9 |
| shades with explicit ids | PASS | explicit S9 + two unnamed -> S10, S11 |
| `motes:[]`/`shades:[]` replace lists | PASS with defect 2 | with random_*:false -> none |
| time_left_s scenario honored, = dur - steps/60 | PASS | 2.5 -> 1.667 at tick 50 -> 0.0 lost "dawn" at tick 150 |
| Stun state after pulse; push; per_stun | PASS | S9 (3,0,0) -> (6,0,0) "stunned"; S10 pushed; third shade at 40 m untouched "chase"; stunned_ids ["S9","S10"] |
| snapshot-every 1 / 7 / 0 / -3 / abc | PASS | 1 -> 21 snapshots for 20 ticks; 7 -> 3; 0,-3,abc -> exit 1 |
| --ticks negative / non-numeric | PASS | exit 1 with stderr message |
| Rounding 3 dp, no "-0.0" | PASS | grep of 3000-tick and pulse outputs: 0 matches `-0.0`, no >3-decimal numbers |
| state in {playing,won,lost} | PASS | observed playing/lost |
| game_over then no more events, end last | PASS | dawn run: game_over, snapshot, end last; sim stops stepping (loop condition) |
| Byte determinism | PASS | seed 5, 3000 ticks, random entities: `cmp` identical, same md5; different seed differs |
| JSON fields / event names per contract | PASS | only mote_picked/deposit/lantern_lit/pulse/player_hit/shade_spawned/game_over in code; no fall event (fall_enabled false) |
| Exit codes | PASS | bad/missing/non-JSON/array-root inputs & scenario, unknown lantern id, bad shade -> 2; missing --seed -> 1; empty frames -> 0 |
| win/lose/dawn priority scenarios (s09-s17) | NOT VERIFIED by me | authors' expected files not re-executed |
| Evidence of GUI run, tag phase-1 | NOT VERIFIED | out of scope |

Not tested: interact edge-trigger in isolation (my held-interact probe lit the lantern in one tick so it cannot discriminate; code reading shows edge handling in input_decoder), player_hit/drop numbers, win score formula.
