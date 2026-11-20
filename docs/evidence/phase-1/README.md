# Bằng chứng Phase 1

Mọi file dưới đây là output thật, sinh bằng mã ở commit ghi trong từng file (không sửa tay).

| Yêu cầu | Bằng chứng |
|---|---|
| Test lõi (304 kiểm tra) | `tests/core_tests.txt` — lệnh: `GODOT --headless --path godot --script res://tests/run_core_tests.gd` |
| 18 kịch bản có đáp án tính tay | `tests/scenarios.txt`; đáp án ở `tests/scenarios/expected/*.md` — lệnh: `sh scripts/run_scenarios.sh` |
| Tất định (byte-giống) + 18000 tick | `determinism/run.txt`, `determinism/long_a.jsonl` vs `long_b.jsonl` — lệnh: `bash scripts/verify_determinism.sh` |
| Review độc lập đối chiếu Test Contract | `E1/review.md` (kèm input/output probe) |
| Giao diện chạy thật | `evidence/screenshots/b8_game_view.png`, `d1_gameplay.png` |
| Giả định / AI log / retro | `docs/assumptions.md`, `docs/ai-log.md`, `docs/notes/retro-phase-1.md` |

Chưa có bằng chứng: chơi thử phím/chuột thật, CI trên GitHub, Docker, macOS/Linux.
