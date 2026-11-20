# T00 — Đối chiếu Test Contract v1.0 với PRD và contract nháp

Nguồn chính thức: [contract/TEST_CONTRACT_v1.0.md](../../contract/TEST_CONTRACT_v1.0.md) (mục A–G). Thứ tự ưu tiên theo contract mục G và ARCHITECTURE §1: **Test Contract > PRD > `game.contract.json` nháp**.
Trạng thái: **chờ Product Owner xác nhận** các quyết định ở mục 3. Chưa sửa PRD.md hay game.contract.json.

## 1. Giao diện bắt buộc (trích từ contract)

| Hạng mục | Yêu cầu | Mục |
|---|---|---|
| `game.contract.json` | Schema mới: `contract_version "1.0"`, `team`, `build_cmd`, `run_cmd`, `headless_cmd`, `tuning{...}` (18 khóa + `score{5 khóa}`); `lantern_count_night1` = 5; giá trị khớp code | A |
| Lệnh headless | `<headless_cmd> --seed --night 1 [--scenario] [--inputs] --ticks --out [--snapshot-every=10]` | B |
| Thời gian | 60 tick/s cố định, không cửa sổ/GPU; dừng khi đủ `--ticks` hoặc game kết thúc; exit 0 | B1 |
| Lỗi | exit khác 0 + stderr; inputs/scenario sai định dạng: **exit 2** | B1 |
| Tick | Snapshot tick 0 sau scenario, trước input; bước k đọc input tick k -> trạng thái k+1; event có `tick=k+1` | B2 |
| Quy ước | Mét, Y lên, đất Y=0, xuất phát (0,0,0); khoảng cách ngang XZ; "trong bán kính" là ≤ | B1, B3 |
| Inputs | `frames[]` stateful, `tick` tăng nghiêm ngặt, `move[x,z]` chuẩn hóa nếu dài >1, xoay theo `cam_yaw_deg`, `jump/interact/pulse` kích theo cạnh lên | C |
| Scenario | `player{pos,carried,flames}`, `random_motes/random_shades`, `motes`, `shades`, `lanterns` (cập nhật theo id, `lit`, `pos`, `deposited`), `time_left_s`; dựng scenario không sinh event/điểm | D |
| Output JSONL | `snapshot` / `event` / `end` (end là dòng cuối); tọa độ làm tròn 3 chữ số; event: `mote_picked, deposit, lantern_lit, pulse, player_hit, shade_spawned, game_over` | E |
| Tất định | Cùng seed+scenario+inputs -> output giống hệt từng byte, kể cả id tự sinh | E4 |

## 2. Xung đột / khác biệt với PRD và contract nháp

| # | PRD / nháp nói | Test Contract nói | Ảnh hưởng |
|---|---|---|---|
| X1 | Ánh sáng tích trữ 0..10, +1/đom đóm, **-3** khi thắp đèn | Mô hình **mang và nạp**: `carried` (≤ `carry_capacity`), event `deposit{amount,deposited}`, đèn sáng khi `deposited` đạt `lantern_cost` | Viết lại luật light/lantern (T02, T05, T06, TASKS giả định "light") |
| X2 | Máu 3, -1/lần chạm | `flames` (player.flames); `player_hit{by,flames,dropped}`; `hit_drop_ratio` đánh rơi bớt đom đóm đang mang; thua `no_flames` | T07 |
| X3 | Tỏa sáng: -2 ánh sáng, tác dụng 2s, hồi 3s | `pulse`: `pulse_cost`, `pulse_radius`, `pulse_stun_s`, `pulse_push_m`, `pulse_cooldown_s`; event `pulse{stunned_ids}`; trạng thái shade `stunned`; điểm `per_stun` | T08 |
| X4 | Không có giới hạn thời gian | `night1_duration_s`, `time_left_s`, thua với `reason:"dawn"`; điểm `per_second_left` | Thêm luật hết giờ (T11) |
| X5 | Điểm: +10/đom đóm, +100/đèn, +50/máu còn lại | `score.per_mote, per_lantern, per_stun, per_second_left, per_flame_left` | T09; `per_mote` tính khi nhặt hay khi nạp? (xem Q3) |
| X6 | Bóng Mực 4 trạng thái Wander/Chase/Repelled/AvoidLight | Tối thiểu có `stunned`; còn lại tự đặt; có `shade_speed`, `shade_hit_radius`, `safe_radius`; event `shade_spawned` | T10 (đang BLOCKED) |
| X7 | HUD/điều khiển E, F, Space, chuột (đề xuất) | Headless dùng `interact`, `pulse`, `jump`, `move`, `cam_yaw_deg` | Map phím GUI -> cùng frame input |
| X8 | `game.contract.json` nháp dạng `requirements/proposed_gameplay_values` | Schema A hoàn toàn khác; file ở gốc repo phải theo schema A | Cần cho phép thay file nháp (xem Q1) |
| X9 | ARCHITECTURE: di chuyển bằng `CharacterBody3D` | Headless phải mô phỏng vị trí tất định ở 60 Hz không GPU | Cần mô phỏng di chuyển/nhảy/va chạm **trong core**, scene chỉ phản chiếu (Q4) |
| X10 | Tie-break thắng/thua đồng thời "theo contract" | Contract **không quy định** (mục G) | Cần quyết định (Q2) |

## 3. Quyết định cần Product Owner

- **Q1.** Cho phép thay `game.contract.json` ở gốc bằng schema chính thức mục A (bản nháp chuyển sang `docs/notes/` để giữ lịch sử)?
- **Q2.** Tie-break khi thắng và thua cùng tick: đề xuất **thắng nếu lantern thứ 5 sáng ở cùng tick** (đèn xử lý trước, hết giờ/flames xử lý sau).
- **Q3.** `per_mote` cộng khi **nhặt** (đề xuất) hay khi **nạp**; nhặt khi đầy `carry_capacity`: đề xuất **không nhặt được** (đom đóm ở lại).
- **Q4.** Core tự mô phỏng chuyển động (kinematic, bán kính đảo giới hạn, trọng lực nhảy) cho cả headless và GUI.
- **Q5.** Duyệt bộ `tuning` (mục 4), vì contract chỉ nói "khai báo đúng giá trị game dùng".
- **Q6.** Quy tắc chọn đèn khi nhiều đèn trong `interact_radius`: đề xuất **gần nhất, hòa thì id nhỏ nhất**; thứ tự event cùng tick: `mote_picked` -> `deposit` -> `lantern_lit` -> `pulse` -> `player_hit` -> `shade_spawned` -> `game_over`.

## 4. Đề xuất `tuning` (provisional, chưa duyệt)

player_speed 6 · carry_capacity 5 · lantern_cost 5 · lantern_count_night1 5 · pickup_radius 1.2 · interact_radius 2.5 · pulse_cost 2 · pulse_radius 6 · night1_duration_s 300 · flames 3 · invuln_s 1.5 · hit_drop_ratio 0.5 · pulse_stun_s 3 · pulse_push_m 3 · pulse_cooldown_s 2 · safe_radius 5 · shade_speed 3.5 · shade_hit_radius 1 · fall_enabled false · score: per_mote 10, per_lantern 100, per_stun 5, per_second_left 1, per_flame_left 50.
Lưu ý: `fall_enabled=false` thì không ghi event `player_hit` với `by:"fall"`; giải thích trong README.
Ràng buộc khả thi: 5 đèn x 5 = 25 đom đóm cần nạp; cần ≥ 25 đom đóm hoặc tái xuất hiện (PRD FR-04).

## 5. Việc chưa làm / rủi ro
- Chưa chạy được gì để đạt contract; chưa có Godot trong PATH (có `Downloads/Godot_v4.7.2-stable_win64.exe`; headless cmd sẽ phải trỏ tới binary Godot, cần đường dẫn không tuyệt đối cho macOS/Linux).
- Godot không tự phân tích `--seed/--ticks...`: runner GDScript phải đọc `OS.get_cmdline_user_args()`.
