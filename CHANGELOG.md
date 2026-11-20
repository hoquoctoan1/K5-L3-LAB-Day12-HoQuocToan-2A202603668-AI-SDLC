# Changelog

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/). Phiên bản theo [SemVer](https://semver.org/lang/vi/).

## [Unreleased]

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
