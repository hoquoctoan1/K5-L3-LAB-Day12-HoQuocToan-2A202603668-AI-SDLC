#!/usr/bin/env sh
# Chay bo scenario Phase 3 / contract v1.2 (tests/scenarios/p3) + check_p3.py + so sanh 2 lan chay (tat dinh).
# Dung: GODOT=<godot> sh scripts/run_scenarios_p3.sh [ten_bo ...]
# Sinh lai file scenario: python -I tests/scenarios/p3/gen_p3.py
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SD="$ROOT/tests/scenarios/p3"
OUT="${OUT_DIR:-${TMPDIR:-/tmp}/scenario_out_p3}"
PY="${PYTHON:-python}"
command -v "$PY" >/dev/null 2>&1 || PY=python3
mkdir -p "$OUT"
export GODOT="${GODOT:-godot}"
SEED=1
# ten:night:ticks:snapshot_every
SETS="f01_decay_out:1:70:1 f02_refuel:1:10:1 f04_relight:1:5:1 c01_capacity_20:1:5:1
d01_drain_one:1:300:1 d02_drain_two:1:200:1 d03_drain_to_chase:1:20:1 d04_pulse_drain:1:5:1 d05_refuel_push:1:60:1
w01_dawn_win_3of5:1:120:1 w02_dawn_lose_2of5:1:120:1 w03_noflames_at_dawn:1:10:1 w04_n3_win_5of7:3:120:1 w05_out_at_dawn:1:120:1"
BADS="e01_bad_fuel:1:2 e02_bad_target:1:2 e03_bad_ever_lit:1:2"
fail=0; pass=0
run() { sh "$ROOT/scripts/headless.sh" --seed $SEED --night "$2" --scenario "$SD/$1.scenario.json" --inputs "$SD/$1.inputs.json" --ticks "$3" --snapshot-every "$4" --out "$5"; }
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
  msg=$("$PY" -I "$SD/check_p3.py" "$n" "$f" 2>&1); rc=$?
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
