# Kế hoạch triển khai song song nhiều agent — Đảo Đèn Lồng Phase 1

> Bản viết lại (v2) để nhiều agent code cùng lúc. Nguồn luật: [Test Contract v1.0](../contract/TEST_CONTRACT_v1.0.md) > PRD.md > bản nháp. Đối chiếu: [test-contract-mapping.md](notes/test-contract-mapping.md). Không sửa PRD.md.
> Tài liệu cũ (T00–T22 tuần tự, giả định "light/máu") đã bị thay vì Test Contract dùng mô hình mang-nạp, `flames`, `pulse`, hết giờ `dawn`.

## 0. Quyết định đã chốt (Product Owner)

| # | Quyết định |
|---|---|
| D1 | Test Contract ghi đè PRD. `game.contract.json` ở gốc thay bằng schema chính thức; bản nháp cũ lưu ở `docs/notes/game.contract.draft.json`. |
| D2 | **Core tự mô phỏng** chuyển động/nhảy/va chạm ở 60 Hz tất định. Scene Godot chỉ hiển thị state, không có `CharacterBody3D` quyết định vị trí. |
| D3 | Tuning dùng bộ đề xuất (mục 3), **provisional**, chỉ khai báo ở `game_config.gd` và mirror vào `game.contract.json`. Product Owner có thể đổi số bất kỳ lúc nào; test phải đọc từ config, không hard-code số. |
| D4 | Thắng ưu tiên nếu đèn thứ 5 sáng cùng tick với điều kiện thua. `per_mote` cộng khi nhặt; đầy `carry_capacity` thì không nhặt. Chọn đèn gần nhất chưa sáng, hòa thì id nhỏ. Mote đánh rơi biến mất (không rơi xuống đất). Shade đang `stunned` không gây sát thương. |
| D5 | Thứ tự event trong một tick: `mote_picked` → `deposit` → `lantern_lit` → `pulse` → `player_hit` → `shade_spawned` → `game_over`. |

## 1. Bố cục thư mục (res:// = `godot/`)

```
godot/
  project.godot
  src/core/            # logic thuần RefCounted, CẤM Node/Input/scene tree
  src/adapters/headless/   # CLI + codec JSONL
  src/adapters/view/       # scene 3D, HUD (chỉ đọc state)
  scenes/  tests/
scripts/headless.sh | headless.cmd   # wrapper gọi Godot (biến GODOT hoặc `godot` trong PATH)
game.contract.json (gốc repo)
```
Godot tại máy Windows hiện tại: `C:\Users\Admin\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (đặt vào biến `GODOT`, không hard-code trong repo).

## 2. Giao diện đóng băng (Wave 0 tạo, các wave sau KHÔNG sửa)

Một agent duy nhất (A0) tạo `src/core/sim_state.gd` và `src/core/interfaces.md` rồi merge trước khi wave 1 bắt đầu.

**`SimState`** (RefCounted, field công khai): `tick:int`, `status:String` (`playing|won|lost`), `time_left_initial:float`, `steps:int`, `score:int`, `player{pos:Vector3, vy:float, carried:int, flames:int, invuln_left:float, pulse_cd_left:float, on_ground:bool}`, `lanterns:Array[{id,pos:Vector3,lit:bool,deposited:int}]`, `motes:Array[{id,pos:Vector3}]`, `shades:Array[{id,pos:Vector3,state:String,stun_left:float}]`, `random_motes:bool`, `random_shades:bool`, `next_mote_id:int`, `next_shade_id:int`, `rng` (xem `Rng`).
**`FrameInput`**: `move:Vector2`, `cam_yaw_deg:float`, `jump/interact/pulse:bool` đã là **cạnh lên** (edge) sau khi `input_decoder` xử lý.
**`Events`**: mảng `{name:String, data:Dictionary}`; mỗi system `static func step(state, input, cfg, events:Array) -> void` và không tự biết `tick` (Sim gắn tick = steps+1).
**`Rng`**: `Rng.new(seed:int)`, `next_float()`, `next_int(n)`; mulberry32 thuần số nguyên.
**Thứ tự gọi trong `Sim.step`**: player_system → mote_system(pick) → lantern_system(interact) → pulse_system → shade_system(move+hit) → spawn_system → lifecycle_system(win/lose/time, bonus điểm).

## 3. Tuning provisional (D3)

player_speed 6 · carry_capacity 5 · lantern_cost 5 · lantern_count_night1 5 · pickup_radius 1.2 · interact_radius 2.5 · pulse_cost 2 · pulse_radius 6 · night1_duration_s 300 · flames 3 · invuln_s 1.5 · hit_drop_ratio 0.5 (`floor(carried*ratio)`) · pulse_stun_s 3 · pulse_push_m 3 · pulse_cooldown_s 2 · safe_radius 5 · shade_speed 3.5 · shade_hit_radius 1 · fall_enabled false · score: per_mote 10, per_lantern 100, per_stun 5, per_second_left 1 (floor giây còn lại, chỉ khi thắng), per_flame_left 50 (chỉ khi thắng).
Hằng nội bộ ngoài contract (khai trong `game_config.gd`, ghi README): island_radius 45, gravity 18, jump_speed 6, lantern ring bán kính 25 (L1 tại (0,0,25), 5 đèn cách 72°), 30 mote ban đầu, 3 shade ban đầu, tái xuất hiện mote mỗi 120 tick nếu <30, shade mới mỗi 20 s tới tối đa 5.

## 4. Nhóm task và quyền sở hữu file

Quy tắc: **mỗi file có đúng một owner**; agent chỉ sửa file trong cột "Sở hữu". Cần đổi file người khác hoặc giao diện đóng băng → dừng, ghi vào `docs/notes/requests.md`, chờ orchestrator.

### Wave 0 — tuần tự, 1 agent (chặn mọi thứ)
| ID | Việc | Sở hữu | Xong khi |
|---|---|---|---|
| A0 | Tạo `sim_state.gd`, `rng.gd`, `game_config.gd` (tuning D3), `interfaces.md`; thay `game.contract.json` theo schema mục A, chuyển bản nháp sang `docs/notes/`; harness test `tests/run_core_tests.gd`, `tests/core/test_support.gd` (chạy `GODOT --headless --path godot --script res://tests/run_core_tests.gd`, exit≠0 khi fail) | `src/core/{sim_state,rng,game_config}.gd`, `src/core/interfaces.md`, `game.contract.json`, `tests/run_core_tests.gd`, `tests/core/test_support.gd` | Runner báo pass mẫu và fail có chủ đích (không lưu fixture fail); test: `game_config` khớp `game.contract.json` |

### Wave 1 — song song tối đa 6 agent (chỉ phụ thuộc A0)
| ID | Việc | Sở hữu (file + test) | Test phải có |
|---|---|---|---|
| B1 | Input: giải mã frames, stateful, tick tăng nghiêm ngặt, edge-trigger, xoay `cam_yaw_deg`, chuẩn hóa | `src/core/input_decoder.gd`, `tests/core/test_input_decoder.gd` | θ=0/90°, vector >1, giữ true nhiều tick chỉ kích 1 lần, tick trùng/giảm bị từ chối |
| B2 | Player: di chuyển 60 Hz, nhảy một lần tới khi chạm đất, trọng lực, giới hạn bán kính đảo | `src/core/systems/player_system.gd`, `tests/core/test_player_system.gd` | đi thẳng đúng quãng, không nhảy hai lần, không ra ngoài đảo |
| B3 | Mote + Lantern: nhặt (≤ pickup_radius, đầy thì không nhặt), deposit, `lantern_lit` một lần, chọn đèn gần nhất/id nhỏ, đèn đã sáng bỏ qua | `src/core/systems/{mote_system,lantern_system}.gd`, `tests/core/test_mote_lantern.gd` | biên ≤ bán kính, carried=0, đèn lit, deposit một phần, hai đèn cách đều |
| B4 | Pulse: điều kiện cost/cooldown, stun trong bán kính, đẩy lùi, điểm `per_stun`, event | `src/core/systems/pulse_system.gd`, `tests/core/test_pulse_system.gd` | thiếu carried, đang cooldown, biên bán kính, shade stunned kết thúc đúng |
| B5 | Shade: đuổi theo, không vào `safe_radius` đèn đã sáng, hit (invuln, drop, flames), stunned không gây sát thương, spawn có seed | `src/core/systems/{shade_system,spawn_system}.gd`, `tests/core/test_shade_system.gd` | không hit liên tiếp trong invuln, drop theo ratio, tới 0 flames, shade không vào vùng đèn |
| B6 | Lifecycle: thắng/thua/hết giờ `dawn`, ưu tiên thắng khi đồng tick, bonus điểm chỉ khi thắng, tính `time_left_s` từ số bước | `src/core/systems/lifecycle_system.gd`, `tests/core/test_lifecycle_system.gd` | all_lit, no_flames, dawn, đồng tick, bonus một lần |
| B7 | Codec + CLI headless (không cần systems xong; dùng stub `SimState`): parse tham số, đọc/validate scenario & inputs (sai → exit 2), áp scenario không phát event/điểm, định dạng JSONL (3 chữ số, byte-ổn định), snapshot tick 0 | `src/adapters/headless/{contract_codec,scenario_loader,headless_runner}.gd`, `scripts/headless.sh`, `scripts/headless.cmd`, `tests/headless/test_codec.gd` | file hỏng→exit 2, thiếu tham số→exit≠0, `--ticks 0`, snapshot-every, `end` luôn cuối |
| B8 | View 3D từ T01 mở rộng: render đảo/Mây/đèn/đom đóm/shade từ `SimState` (chưa cần core chạy: dùng state mẫu), HUD, màn kết quả + Replay, camera ngôi thứ ba, ánh sáng đảo sáng dần khi đèn lit (sáng tạo PRD §20) | `godot/scenes/**`, `src/adapters/view/**` | Chụp ảnh thực ở `evidence/screenshots/` |

### Wave 2 — tích hợp, 1 agent (cần B1–B7 merge)
| ID | Việc | Sở hữu | Test |
|---|---|---|---|
| C1 | `Sim` ghép các system theo thứ tự mục 2, `reset()`/replay; nối B7 với Sim thật | `src/core/sim.gd`, `tests/core/test_sim.gd`, `tests/headless/test_e2e.gd` | 10+ scenario có đáp án tay (xem C2), replay trả state ban đầu |
| C2 | Scenario & kịch bản bằng chứng (tay viết, kèm đáp án mong đợi): đứng yên, nhặt, deposit, lit, pulse, bị đánh, thắng, thua `no_flames`, thua `dawn`, không shade/mote, `--ticks` biên, đồng tick | `tests/scenarios/*.json`, `tests/scenarios/expected/*.md` | chạy được bằng một lệnh |

### Wave 3 — song song (cần C1)
| ID | Việc | Sở hữu |
|---|---|---|
| D1 | Nối View ↔ Sim: input bàn phím/chuột → `FrameInput` cùng định dạng headless; GUI và headless dùng chung `Sim`; chơi được thắng/thua/replay | `src/adapters/view/**`, `scenes/main/**` |
| D2 | Tất định + hiệu năng: chạy 2 lần so byte, `--ticks 18000` đo thời gian | `scripts/verify_determinism.*`, `docs/evidence/phase-1/determinism/` |
| D3 | CI: Godot headless trên Ubuntu chạy test + determinism | `.github/workflows/verify.yml` (thêm job, không bỏ job cũ) |
| D4 | Tài liệu: README (≤3 lệnh, điều khiển, điểm, giải thích `null/false`, "Sáng tạo của tôi"), `docs/assumptions.md`, `docs/ai-log.md`, bản build web/Docker cho macOS/Linux | `README.md`, `docs/assumptions.md`, `docs/ai-log.md`, `Dockerfile` |

### Wave 4 — xác minh và bàn giao (tuần tự)
| ID | Việc |
|---|---|
| E1 | Reviewer độc lập đọc diff từng task, chạy lại toàn bộ test, đối chiếu checklist mục F của Test Contract; lưu bằng chứng thật |
| E2 | Clone sạch → làm theo README → chạy; ghi trung thực mục chưa đạt |
| E3 | Chỉ sau khi Product Owner đồng ý: tag `phase-1`, push |

## 5. Bảng phụ thuộc

```
A0 ──┬─> B1 B2 B3 B4 B5 B6 B7 B8   (song song)
     └────────────┬──────────────┘
                  v
                  C1 ─> C2 ─┬─> D1 D2 D3 D4 (song song) ─> E1 ─> E2 ─> E3
```
B1–B8 không đọc code của nhau, chỉ đọc `interfaces.md`. Nếu B-task cần giá trị của system khác, dùng state dựng tay trong test.

## 6. Quy tắc phối hợp nhiều agent

- Mỗi agent làm trên **nhánh riêng** `task/<ID>` (hoặc worktree riêng); merge theo thứ tự wave; không sửa file ngoài cột "Sở hữu".
- Trước khi code, agent đọc: `contract/TEST_CONTRACT_v1.0.md`, `docs/notes/test-contract-mapping.md`, mục 0–3 của file này, `interfaces.md`. Không đọc toàn repo.
- Core không `extends Node`, không gọi `Input`, `OS.get_ticks_*`, `randf()`; chỉ dùng `Rng` và `DT = 1/60`.
- Số liệu tuning chỉ đọc từ `GameConfig`; test đọc cùng config, không hard-code.
- Mỗi system chạy test riêng: `GODOT --headless --path godot --script res://tests/run_core_tests.gd -- --only <tên>`.
- Không thêm event hoặc trường JSON ngoài contract; tính năng sáng tạo chỉ nằm ở `adapters/view` và tắt khi headless.
- Báo cáo cuối task (bắt buộc): ID, file đã đổi, lệnh test đã chạy kèm output thật, vấn đề tồn đọng, giả định mới (thêm vào `docs/assumptions.md` bằng yêu cầu gửi D4). Không nói "pass" nếu chưa chạy.
- Trạng thái: `TODO → IN_PROGRESS → TESTING → REVIEW → DONE`; reviewer ≠ implementer. Bằng chứng ở `docs/evidence/phase-1/<ID>/`.
- Xung đột giữa nguồn luật: dừng, ghi `docs/notes/requests.md`, hỏi Product Owner; không tự quyết.

## 7. Bảng trạng thái

| ID | Trạng thái | Ghi chú |
|---|---|---|
| T00 (đối chiếu contract) | REVIEW | `docs/notes/test-contract-mapping.md`; D1–D5 đã được chốt |
| T01 (preview Godot) | TESTING | Preview placeholder có sẵn; chờ chạy Godot và chụp ảnh; nền cho B8 |
| A0 | DONE | `run_core_tests`: checks=28 failures=0, fail cố ý exit=1 (đã chạy thật) |
| B1–B8 | DONE | test lõi 304 checks, 0 fail (đã chạy lại) |
| C1–C2 | DONE | Sim ghép; 18 kịch bản pass; headless tất định |
| D1 | TESTING | demo + smoke đã chạy; chưa có người chơi thử phím/chuột thật |
| D2 | DONE | 7/7 byte-giống; 18000 tick ~2,5 s (kịch bản không shade) |
| D3 | REVIEW | YAML hợp lệ; chưa chạy trên GitHub |
| D4 | REVIEW | cần rà lại sau khi kết quả cuối |
| E1 | IN_PROGRESS | reviewer độc lập đang chạy |
| C1–C2 | TODO | Chờ B1–B7 |
| D1–D4 | TODO | Chờ C1 |
| E1–E3 | TODO | Chờ D1–D4; tag cần Product Owner đồng ý |

## 8. Rủi ro

- Giá trị tuning là giả định; Product Owner đổi số thì chỉ sửa `game_config.gd` + `game.contract.json` (test `test_config` bắt lệch).
- Godot không phân tích `--seed/--ticks`; `headless_runner.gd` phải đọc `OS.get_cmdline_user_args()`.
- Float sin/cos có thể lệch giữa nền tảng ở chữ số cuối; làm tròn 3 chữ số, tất định chỉ bảo đảm cùng máy/cùng build.
- Chưa có bằng chứng nào cho thấy contract đã đạt; chỉ ghi "đạt" sau khi chạy lệnh headless thật.
