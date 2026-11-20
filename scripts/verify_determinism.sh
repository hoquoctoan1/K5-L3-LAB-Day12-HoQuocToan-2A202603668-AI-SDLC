#!/usr/bin/env bash
# D2: kiem tra tat dinh. Moi to hop (seed, scenario, inputs) chay headless 2 lan,
# so sanh tung byte (cmp). Mot FAIL bat ky -> exit 1.
# Dung: GODOT=/duong/dan/godot scripts/verify_determinism.sh
# Log day du luu o docs/evidence/phase-1/determinism/run.txt (xem lenh o cuoi file).
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

GODOT="${GODOT:-godot}"
EVID="docs/evidence/phase-1/determinism"
OUT="$EVID/out"
SCEN="contract/scenario_example.json"
INP="contract/inputs_example.json"
TICKS=3000
TICKS_LONG=18000
SEEDS=(1 42 12345)

mkdir -p "$OUT" || exit 1
rm -f "$OUT"/*.jsonl "$OUT"/*.log

# Godot (exe Windows) doi cwd sang --path godot va khong hieu /c/... nen moi duong dan
# gui cho Godot phai tuyet doi, dang C:/... (cygpath -m).
native() {
  local p="$1"
  case "$p" in /*|[A-Za-z]:*) ;; *) p="$ROOT/$p" ;; esac
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$p"; else printf '%s' "$p"; fi
}

now() { date +%s.%N; }
elapsed() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.2f", b - a }'; }

FAILS=0
COMBOS=0

echo "== verify_determinism.sh"
echo "date: $(date -Iseconds)"
echo "repo: $ROOT"
echo "godot: $GODOT"
"$GODOT" --version 2>&1 | sed 's/^/godot --version: /'
echo

# run_one NAME OUTFILE SEED TICKS [SCEN] [INP] -> sets RC and ELAPSED
run_one() {
  local name="$1" file="$2" seed="$3" ticks="$4" scen="${5:-}" inp="${6:-}"
  local -a cmd=("$GODOT" --headless --path godot
    --script res://src/adapters/headless/headless_runner.gd --
    --seed "$seed" --night 1 --ticks "$ticks" --out "$(native "$file")")
  if [ -n "$scen" ]; then cmd+=(--scenario "$(native "$scen")"); fi
  if [ -n "$inp" ]; then cmd+=(--inputs "$(native "$inp")"); fi
  echo "+ ${cmd[*]}"
  local t0 t1
  t0=$(now)
  "${cmd[@]}" > "${file%.jsonl}.log" 2>&1
  RC=$?
  t1=$(now)
  ELAPSED=$(elapsed "$t0" "$t1")
  echo "  exit=$RC wall=${ELAPSED}s bytes=$(wc -c < "$file" 2>/dev/null || echo 0)"
}

# check NAME SEED TICKS [SCEN] [INP]: chay 2 lan, cmp
check() {
  local name="$1" seed="$2" ticks="$3" scen="${4:-}" inp="${5:-}"
  COMBOS=$((COMBOS + 1))
  echo "--- combo $name (seed=$seed ticks=$ticks${scen:+ scenario=$scen}${inp:+ inputs=$inp})"
  run_one "$name" "$OUT/$name.a.jsonl" "$seed" "$ticks" "$scen" "$inp"
  local rc_a=$RC
  run_one "$name" "$OUT/$name.b.jsonl" "$seed" "$ticks" "$scen" "$inp"
  local rc_b=$RC
  if [ "$rc_a" -ne 0 ] || [ "$rc_b" -ne 0 ]; then
    echo "FAIL $name: exit code a=$rc_a b=$rc_b (xem $OUT/$name.a.log, $OUT/$name.b.log)"
    tail -n 20 "$OUT/$name.a.log"
    FAILS=$((FAILS + 1))
    return
  fi
  if [ ! -s "$OUT/$name.a.jsonl" ]; then
    echo "FAIL $name: output rong"
    FAILS=$((FAILS + 1))
    return
  fi
  echo "  end line: $(tail -n 1 "$OUT/$name.a.jsonl")"
  local req_ticks="$ticks"
  local got_ticks
  got_ticks=$(tail -n 1 "$OUT/$name.a.jsonl" | sed -n 's/.*"ticks":\([0-9]*\).*/\1/p')
  if [ "${got_ticks:-0}" -lt "$req_ticks" ]; then
    echo "  note: game ket thuc som: $got_ticks/$req_ticks tick (state trong end line)"
  fi
  if cmp -s "$OUT/$name.a.jsonl" "$OUT/$name.b.jsonl"; then
    echo "PASS $name: 2 lan byte-giong nhau (sha256 $(sha256sum < "$OUT/$name.a.jsonl" | cut -c1-16)...)"
  else
    echo "FAIL $name: 2 lan KHAC byte"
    cmp "$OUT/$name.a.jsonl" "$OUT/$name.b.jsonl" | head -n 3
    FAILS=$((FAILS + 1))
  fi
}

for s in "${SEEDS[@]}"; do
  check "noscen_s${s}" "$s" "$TICKS"
  check "scen_s${s}" "$s" "$TICKS" "$SCEN" "$INP"
done

# Thong tin (khong fail): seed khac nhau co cho ra ket qua khac khong?
echo
echo "== info: seed khac nhau (no-scenario, ticks=$TICKS)"
for ((i = 0; i < ${#SEEDS[@]} - 1; i++)); do
  for ((j = i + 1; j < ${#SEEDS[@]}; j++)); do
    a="$OUT/noscen_s${SEEDS[i]}.a.jsonl"; b="$OUT/noscen_s${SEEDS[j]}.a.jsonl"
    if cmp -s "$a" "$b"; then
      echo "INFO seed ${SEEDS[i]} vs ${SEEDS[j]}: GIONG NHAU (khong mong doi, nhung khong phai loi)"
    else
      echo "INFO seed ${SEEDS[i]} vs ${SEEDS[j]}: khac nhau"
    fi
  done
done

# Hieu nang: 18000 tick (5 phut game). Chay 2 lan de cung kiem tra tat dinh.
echo
echo "== timing: --ticks $TICKS_LONG (no-scenario, seed 42)"
check "long_s42" 42 "$TICKS_LONG"

echo
if [ "$FAILS" -eq 0 ]; then
  echo "RESULT: PASS ($COMBOS/$COMBOS to hop)"
  exit 0
else
  echo "RESULT: FAIL ($FAILS/$COMBOS to hop that bai)"
  exit 1
fi
