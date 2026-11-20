#!/usr/bin/env sh
# Chay bo scenario Phase 2 (tests/scenarios/p2) + check_p2.py + so sanh 2 lan chay (tat dinh).
# Dung: GODOT=<godot> sh scripts/run_scenarios_p2.sh [ten_bo ...]
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SD="$ROOT/tests/scenarios/p2"
OUT="${OUT_DIR:-${TMPDIR:-/tmp}/scenario_out_p2}"
PY="${PYTHON:-python}"
command -v "$PY" >/dev/null 2>&1 || PY=python3
mkdir -p "$OUT"
export GODOT="${GODOT:-godot}"
SEED=1
# ten:night:ticks:snapshot_every
SETS="d01_dash:1:120:1 d04_dash_charm:1:60:1 f01_fall_flames:1:240:1 f02_fall_last_flame:1:200:1
j01_pad_night2:2:120:1 b01_bridge_walk:2:90:1 b02_bridge_side_fall:2:120:1
r01_ramp_climb:3:80:1 r02_tier_edge_fall:3:140:1 r03_pad_tier2:3:100:1
p01_pulse_3d:1:40:1 p02_stun_120:1:125:1 p03_pulse_dy:3:20:1 h01_shade_hit:1:90:1
m01_capacity:1:30:1 m02_respawn:1:500:1 l01_partial_fill:1:30:1 l02_complete_fill:1:30:1
z01_safe_block:1:120:1 z02_safe_push:1:200:1 s01_spawn_n1:1:800:10
dr01_steal:2:330:1 dr04_pulse_chase_flee:2:260:1 dr05_pulse_flee_drop:2:130:1
c01_charm:2:2720:1 w01_wind:3:2150:1 pa01_pause:1:40:1
n01_night_start:1:3:1 n03_night_start:3:3:1 n04_charms_replace:2:3:1
tb01_ticks0_n3:3:0:1 tb02_dawn_tick59:2:59:1 tb03_dawn_tick60:2:61:1
v01_win_beats_dawn_n2:2:100:1 v02_win_bonus_n3:3:10:1 v03_nofl_beats_win:1:100:1"
BADS="e01_bad_shade_state:1:2 e02_drifters_not_array:1:2 e05_input_dash_type:1:2"
fail=0; pass=0
run() { sh "$ROOT/scripts/headless.sh" --seed $SEED --night "$2" --scenario "$SD/$1.scenario.json" --inputs "$SD/$1.inputs.json" --ticks "$3" --snapshot-every "$4" --out "$5"; }
want() { [ $# -eq 0 ] && return 0; return 1; }
sel() { [ -z "$SEL" ] && return 0; case " $SEL " in *" $1 "*) return 0;; esac; return 1; }
SEL="$*"
for item in $SETS; do
  IFS=: read n k t e <<EOT
$item
EOT
  sel "$n" || continue
  f="$OUT/$n.jsonl"; rm -f "$f" "$f.2"
  run "$n" "$k" "$t" "$e" "$f" >"$OUT/$n.log" 2>&1; rc=$?
  if [ $rc -ne 0 ]; then echo "FAIL $n: exit code $rc"; fail=$((fail+1)); continue; fi
  msg=$("$PY" -I "$SD/check_p2.py" "$n" "$f" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then echo "FAIL $n: $msg"; fail=$((fail+1)); continue; fi
  run "$n" "$k" "$t" "$e" "$f.2" >/dev/null 2>&1
  if ! cmp -s "$f" "$f.2"; then echo "FAIL $n: non-deterministic output"; fail=$((fail+1)); continue; fi
  echo "PASS $n"; pass=$((pass+1))
done
for item in $BADS; do
  IFS=: read n k want <<EOT
$item
EOT
  sel "$n" || continue
  run "$n" "$k" 10 10 "$OUT/$n.jsonl" >"$OUT/$n.log" 2>&1; rc=$?
  if [ $rc -eq "$want" ]; then echo "PASS $n"; pass=$((pass+1)); else echo "FAIL $n: exit code $rc want $want"; fail=$((fail+1)); fi
done
echo "passed=$pass failed=$fail"
[ $fail -eq 0 ]
