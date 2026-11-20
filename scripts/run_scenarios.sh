#!/usr/bin/env sh
# Chay moi bo scenario trong tests/scenarios va kiem tra khang dinh tay (check.py).
# Dung: GODOT=<duong dan godot> sh scripts/run_scenarios.sh [ten_bo ...]
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SD="$ROOT/tests/scenarios"
OUT="${OUT_DIR:-${TMPDIR:-/tmp}/scenario_out}"
PY="${PYTHON:-python}"
command -v "$PY" >/dev/null 2>&1 || PY=python3
mkdir -p "$OUT"
export GODOT="${GODOT:-godot}"
SEED=1
# ten:ticks
SETS="s01_idle:120 s02_pick_mote:60 s03_full_no_pickup:60 s04_deposit_partial:30 s05_deposit_lights:30
s06_pulse_stun:60 s07_pulse_no_carry:30 s08_shade_hit_invuln:150 s09_loss_no_flames:600 s10_win_all_lit:600
s11_loss_dawn_t60:600 s12_no_entities_yaw90:300 s13_diagonal:60 s14_ticks_zero:0 s15_dawn_ticks59:59
s16_nofl_beats_dawn:600 s17_win_beats_dawn:600"
fail=0; pass=0
run() { # name ticks outfile
  sh "$ROOT/scripts/headless.sh" --seed $SEED --night 1 --scenario "$SD/$1.scenario.json" --inputs "$SD/$1.inputs.json" --ticks "$2" --out "$3"
}
for item in $SETS; do
  n="${item%%:*}"; t="${item##*:}"
  if [ $# -gt 0 ]; then case " $* " in *" $n "*) ;; *) continue;; esac; fi
  f="$OUT/$n.jsonl"; rm -f "$f" "$f.2"
  run "$n" "$t" "$f" >"$OUT/$n.log" 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then echo "FAIL $n: exit code $rc"; fail=$((fail+1)); continue; fi
  msg=$("$PY" -I "$SD/check.py" "$n" "$f" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then echo "FAIL $n: $msg"; fail=$((fail+1)); continue; fi
  run "$n" "$t" "$f.2" >/dev/null 2>&1
  if ! cmp -s "$f" "$f.2"; then echo "FAIL $n: non-deterministic output"; fail=$((fail+1)); continue; fi
  echo "PASS $n"; pass=$((pass+1))
done
# s18: inputs sai dinh dang (tick trung) -> exit code 2
want18=1
if [ $# -gt 0 ]; then case " $* " in *" s18_bad_inputs "*) ;; *) want18=0;; esac; fi
if [ $want18 -eq 1 ]; then
  run s18_bad_inputs 10 "$OUT/s18.jsonl" >"$OUT/s18.log" 2>&1
  rc=$?
  if [ $rc -eq 2 ]; then echo "PASS s18_bad_inputs"; pass=$((pass+1)); else echo "FAIL s18_bad_inputs: exit code $rc want 2"; fail=$((fail+1)); fi
fi
echo "passed=$pass failed=$fail"
[ $fail -eq 0 ]
