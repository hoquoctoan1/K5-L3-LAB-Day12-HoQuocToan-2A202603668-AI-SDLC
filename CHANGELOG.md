# Changelog

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/). Phiên bản theo [SemVer](https://semver.org/lang/vi/).

## [phase-3] - 2026-11-21 — "Đèn cạn dầu" (contract v1.2)

### Breaking changes
- **Luật thắng:** bỏ `won/all_lit`. Thắp đủ đèn không kết thúc Đêm. Thắng chỉ ở bình minh nếu số đèn đang sáng ≥ ceil(0,6 × tổng đèn) (`game_over.reason = "dawn_survived"`); thiếu thì `lost/dawn`; hết Ngọn Lửa vẫn ưu tiên `no_flames`, kể cả ở tick cuối.
- **Thời gian Đêm:** 300/330/360 s → **240/270/300 s** (14400/16200/18000 tick). `time_left_s` ở mọi snapshot và tick bình minh đổi theo.
- **Điểm:** bỏ +10 khi nhặt và thưởng theo giây. Mới: +5 mỗi đom đóm nạp (thắp mới, thắp lại, châm dầu), +100 thắp lần đầu, +40 thắp lại, pulse +5 (hoặc +15 nếu con đó đang `drain`), bình minh (khi thắng) +50 + floor(fuel) mỗi đèn sáng và +50 mỗi Ngọn Lửa.
- **Đèn có nhiên liệu:** đèn sáng hao 1 fuel/s, hết dầu thì tắt (`lantern_out`, `deposited = 0`). Đèn đã sáng nhưng chưa đầy dầu **nhận** đom đóm (châm dầu, event `refuel`). Đèn từng sáng thắp lại tốn 5.
- **Vùng an toàn:** chỉ còn ở đèn có fuel ≥ 30.
- **Bóng Mực:** thêm trạng thái `drain` (hút 5 fuel/s). `wander` đi về đèn yếu rồi đến đèn tắt gần nhất, thay cho đi ngẫu nhiên. Hết choáng thì về `wander`.
- **Sức chứa:** 10 + 2 × số lần thắp thành công, tối đa 20 (không còn cố định 10).
- **Snapshot:** lantern thêm `fuel`, `ever_lit`, `relit_count`; player thêm `capacity`. **Event mới:** `refuel`, `lantern_out`, `fuel_drain`; `lantern_lit` thêm `relight`.
- **Scenario:** lantern nhận `lit`, `fuel` (0..100), `ever_lit`; player `successful_lights`; shade `target_lantern_id` và state `drain`. Giá trị sai thì thoát mã 2.
- **`game.contract.json`:** `contract_version` "1.2", thêm `fuel_max`, `fuel_decay_per_s`, `fuel_per_mote`, `relight_cost`, `win_ratio`, `drain_per_s`, `low_fuel_threshold`, `capacity_max`. Khối `score` đổi khóa: bỏ `per_second_left`; thêm `per_relight`, `per_stun_drain`, `per_lit_lantern_dawn`. Tên các khóa `score` là giả định.

### Added
- Thanh dầu trên đèn; đèn sắp hết dầu nhấp nháy 1 Hz; đèn tắt xẹp 20% và có vết rách; HUD hiển thị đang mang/sức chứa.
- Cài đặt "Bảng màu dễ phân biệt" (lưu trong `user://settings.cfg`): Bóng Mực #00B3FF, cảnh báo #FFFFFF kèm ⚠. Cờ demo `--colorblind`.
- 17 kịch bản headless Phase 3 (`tests/scenarios/p3`, `scripts/run_scenarios_p3.sh`); test đơn vị `test_lantern_v3.gd`.
- ADR `docs/adr/ADR-001-den-can-dau.md`; ghi chú regression `docs/notes/p3-regression-changes.md`.

## [phase-2] - 2026-11-20 — Ba hòn đảo (contract v1.1)
Xem `README.md` mục "Phase 2" và `docs/TASKS_P2.md`.

## [phase-1] - 2026-11-20
Phiên bản đầu (contract v1.0). Nội dung ghi ở mục dưới, giữ nguyên từ Phase 1.

## [Unreleased] (ghi chú gốc Phase 1)

Phase 1 đang thực hiện. Chưa có tag `phase-1`. Bản `v1.0.0` sẽ được phát hành ở Phase 4.

### Added
- Core Godot (`godot/src/core/`): `SimState`, `Rng` (mulberry32), `GameConfig` (tuning provisional), các system người chơi, đom đóm, đèn, pulse, Bóng Mực, spawn, lifecycle (chưa xác minh đầy đủ).
- Chế độ headless: CLI và codec JSONL theo Test Contract v1.0 (`scripts/headless.sh`, `scripts/headless.cmd`).
- Test core: `godot/tests/run_core_tests.gd` và các file trong `godot/tests/core/`.
- Scene hiển thị (`godot/src/adapters/view/`, `godot/scenes/`). Hiện chỉ là demo, chưa nối với điều khiển.
- Tài liệu: `README.md`, `docs/assumptions.md`, `docs/ai-log.md`, `LICENSE` (MIT), `Dockerfile` (chưa kiểm chứng).

### Changed
- `game.contract.json` thay bằng schema Test Contract v1.0. Bản nháp cũ chuyển sang `docs/notes/game.contract.draft.json`.
- README gốc của lab chuyển sang `docs/LAB_README.md`.

### Known issues
- Điều khiển và luồng chơi GUI chưa được xác minh.
- Chưa có `scripts/run_scenarios.sh`, `scripts/verify_determinism.sh`.
- Dockerfile chưa được build hay chạy.
- Chi tiết xem mục "Giới hạn đã biết" trong `README.md`.
