# Kế hoạch Phase 2 — Ba hòn đảo (tag `phase-2`, contract v1.1)

Nguồn: ticket TICKET-02 (JSON do Product Owner dán, lưu ở `docs/notes/ticket-02.json` bởi A0-P2). Chưa có file `TEST_CONTRACT_v1.1.md` trong `contract/`; tên trường lấy từ bản tóm tắt JSON và là **giả định** (ghi ở `docs/assumptions.md`). Khi có file gốc: đối chiếu và sửa.

## 0. Quyết định đã chốt
| # | Quyết định |
|---|---|
| P1 | Tag `phase-1` đã gắn tại `92caca0` (Product Owner đồng ý). Phase 2 làm tiếp trên `main`. |
| P2 | Số chuẩn của ticket **thay thế** giá trị tạm Phase 1 (xem bảng mục 1). Test Phase 1 phải đọc từ `GameConfig`/scenario, đạt lại với số chuẩn (regression). |
| P3 | Câu hỏi mở: Đêm 2/3 sinh Bóng Mực 2 con ở tick 300 rồi theo interval riêng (Đêm 2: 420, Đêm 3: 360); `max_alive` tính chung cả bản đồ, luân phiên giữa các đảo (Đêm 2); áp dụng ≥15 m cho mọi Đêm; pulse trúng Gió Lạc **không** cộng điểm; điểm sinh/gió/sương dùng `Rng` seed cố định; đom đóm Gió Lạc thả: kind `dropped`, TTL 120 tick. |
| P4 | Lõi + headless + 3 bản đồ + contract v1.1 + regression trước. Menu/HUD/âm thanh làm sau, âm thanh tổng hợp bằng code (không asset ngoài). |
| P5 | Contract ưu tiên: Test Contract v1.1 > ticket > PRD. Tick order: 12 bước của ticket (mục `tick_order`). |

## 1. Số chuẩn thay đổi so với Phase 1
sức chứa 5→10 · lantern_cost 5→10 · island 45→40 · pickup 1.2→1.0 (+|Δy|≤1.5) · interact 2.5→2.0 · pulse_cost 2→3 · pulse_radius 6→5 (3D, tâm = chân+0.8) · cooldown 120→180 tick · stun 3 s→120 tick · knockback 3 m→4 m/15 tick · safe 5→6 · shade 3.5→4.0 (Đêm 3: 4.5) · jump 6→7, gravity 18→20 · invuln 1.5 s→90 tick · bonus giây ×1→×2 · player_speed 6 giữ.
Mới: dash 14 m/s 12 tick hồi 90; fall_y −10; rơi khỏi đảo mất 1 lửa + toàn bộ đom đóm, chờ 60 tick, hồi sinh; Đêm 2 = 330 s, Đêm 3 = 360 s; `--night 1|2|3`.

## 2. Wave
### Wave 0 — một agent (chặn mọi thứ; sonnet)
**A0-P2**: sửa `game_config.gd` và `game.contract.json` theo số chuẩn + contract v1.1 (thêm khóa `dash_speed, dash_duration_s, dash_cooldown_s, night2_duration_s, night3_duration_s`, `contract_version "1.1"`); mở rộng `SimState` (night, vel, grounded, dash_cd, charm_ticks, wind, drifters, charms, state_ticks_left cho shade, `kind/ttl` cho mote, island/tier/geometry); viết `interfaces_v2.md` (khung cố định, thứ tự 12 bước, id C/D/S); `docs/notes/ticket-02.json`; sửa các test Phase 1 đọc config (regression); chạy lại test + 18 kịch bản P1 (cập nhật số chuẩn trong `expected/` kèm lý do).
### Wave 1 — song song (sonnet, trừ ghi chú)
| ID | Việc | Sở hữu |
|---|---|---|
| P2-B1 | Bản đồ & hình học: 3 bản đồ (`maps/night1..3`), điểm đèn/mote/shade spawn, đảo A/B + cầu, tầng/dốc/tháp, kiểm tra trong đảo/rơi, độ cao nền | `src/core/maps/*`, test |
| P2-B2 | Player v2: gia tốc dừng, air control, nhảy 7/-20, **dash**, rơi khỏi đảo + hồi sinh, bục nhảy (Đêm 2/3) | `systems/player_system.gd` (+ `jump_pad_system.gd`), test |
| P2-B3 | Mote v2: kind random/dropped/TTL, respawn 240 tick, điểm trống, pickup XZ≤1.0 & |Δy|≤1.5, drop vòng 1.5–2.5 m, capacity 10 | `systems/mote_system.gd`, test |
| P2-B4 | Lantern v2: cost 10, vùng an toàn 6 m (đẩy ra tối đa 30 tick, không sát thương), tương tác 2.0 | `systems/lantern_system.gd`, test |
| P2-B5 | Pulse v2 + Shade v2: tâm +0.8 m, 3D, stun 120, knockback 15 tick dừng khi gặp vật cản, trạng thái spawning/wander/chase/recoil/stunned, detect 12/lose 18, touch & recoil 2 m/60 tick | `systems/pulse_system.gd`, `shade_system.gd`, `spawn_system.gd`, test |
| P2-B6 | Gió Lạc (drifter) + Bùa Gió (charm) + Gió mạnh Đêm 3 | `systems/{drifter,charm,wind}_system.gd`, test |
| P2-B7 | Lifecycle v2 + chính xác 12 bước `Sim.step`, pause, `night_start`, điểm (`per_mote_delivered` tính khi nạp? — xem ghi chú), thắng/thua theo thứ tự ticket | `sim.gd`, `systems/lifecycle_system.gd` (Wave 2) |
| P2-B8 | Codec/CLI v1.1: `--night 1..3`, snapshot mở rộng, scenario mở rộng (invuln_ticks…, random_drifters, wind_enabled), input `dash`/`pause`, event mới | `adapters/headless/*`, `input_decoder.gd` |
Ghi chú: ticket ghi `per_mote_delivered` — điểm cộng khi **nạp vào đèn**, khác Phase 1 (cộng khi nhặt). Giả định P6: dùng ticket (khi nạp). Cần xác nhận bằng contract v1.1.
### Wave 2 (một agent, **opus** cho `sim.gd`)
P2-C1 ghép 12 bước, pause, regression headless; P2-C2 kịch bản (≥1 mỗi tính năng mới: dash, rơi, bục nhảy, drifter steal/flee/drop, charm, wind, 3 đêm, pause).
### Wave 3 — song song
P2-D1 view 3 đảo (hình khối, palette ticket); P2-D2 menu/giới thiệu/pause/cài đặt/HUD/âm thanh tổng hợp (haiku/sonnet); P2-D3 tất định + hiệu năng (một Đêm ≤21.600 tick ≤30 s) + FPS 1280×720; P2-D4 CI, README, AGENTS.md/skill, assumptions, ai-log.
### Wave 4
E1 reviewer độc lập (sonnet) đối chiếu contract v1.1; E2 chơi thử; E3 tag `phase-2` sau khi Product Owner đồng ý.

## 3. Quy tắc (giữ từ Phase 1)
Mỗi file một owner; chỉ sửa file trong cột "Sở hữu". Không chạy `--import`/`--editor`; file mới tham chiếu bằng `preload`. Chọn model theo độ khó. Không nói "pass" nếu chưa chạy thật; báo cáo kèm lệnh + output thật. Push vào `main` chỉ khi test, kịch bản, tất định đạt thật.

## 4. Trạng thái
| ID | Trạng thái |
|---|---|
| A0-P2 | DONE (khung dong bang: game_config, sim_state, interfaces_v2.md; test 470 checks 0 failures, 18/18 kich ban) |
| Wave 1 | DONE |
| Wave 2 (C1, C2, D1) | DONE (test lõi 3055/0; p2 39/39; p1 18/18) |
| Phase 2 push | commit + tag phase-2 theo yêu cầu Product Owner |
