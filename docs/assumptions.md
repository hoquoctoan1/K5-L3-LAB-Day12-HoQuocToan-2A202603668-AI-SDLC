# Giả định (Phase 1)

Thứ tự ưu tiên nguồn: Test Contract v1.0 > PRD > `game.contract.json` nháp (xem `docs/TASKS.md` mục 0 và `docs/notes/test-contract-mapping.md`). Các mã D1–D5 và Q1–Q6 tham chiếu tới `docs/TASKS.md` và `docs/notes/test-contract-mapping.md`.

Mọi số tuning là **provisional** (D3). Chỉ khai báo ở `godot/src/core/game_config.gd`, mirror vào `game.contract.json`. Test đọc từ config, không hard-code.

| # | Chỗ mơ hồ | Quyết định | Nguồn / nơi kiểm tra |
|---|---|---|---|
| A1 | Mô hình ánh sáng | Mang và nạp, không dùng "ánh sáng tích trữ". `carried` ≤ `carry_capacity`. Nạp vào đèn: `amount = min(carried, lantern_cost − deposited)`. Đèn sáng khi `deposited` đạt `lantern_cost`. | X1, `lantern_system.gd` |
| A2 | Chọn đèn khi nạp (`E`) | Chỉ xét đèn chưa sáng trong `interact_radius` (+1e-4). Chọn đèn gần nhất. Hòa thì chọn id nhỏ hơn. | Q6, D4; `lantern_system.gd` |
| A3 | Nhặt khi đầy | Khi `carried = carry_capacity` thì không nhặt. Đom đóm ở lại trên đảo. | Q3 |
| A4 | Thời điểm cộng `per_mote` | Cộng khi nhặt, không cộng khi nạp. | Q3; `mote_system.gd` |
| A5 | Thời điểm cộng `per_lantern` | Cộng một lần, khi đèn chuyển sang `lit`. | `lantern_system.gd` |
| A6 | Đom đóm bị đánh rơi | `floor(carried × hit_drop_ratio)` đom đóm bị rơi và biến mất, không nằm xuống đất. | D4; `hit_drop_ratio` trong contract (chưa đối chiếu file xử lý trong D4) |
| A7 | Bóng Mực đang `stunned` | Không gây sát thương. Trạng thái `stunned` là bắt buộc. Các trạng thái khác do `shade_system.gd` quyết định (chưa đối chiếu hết trong D4). | D4 |
| A8 | Pulse (`F`) | Tốn `pulse_cost` đom đóm đang mang. Ảnh hưởng mọi shade trong `pulse_radius` (≤, +1e-4). | `pulse_system.gd` |
| A9 | Pulse lên shade đã choáng | Shade đã `stunned` vẫn bị choáng lại: `stun_left` đặt lại `pulse_stun_s` và cộng `per_stun` lần nữa. | `pulse_system.gd` (comment đầu file) |
| A10 | Thứ tự event trong một tick | `mote_picked` → `deposit` → `lantern_lit` → `pulse` → `player_hit` → `shade_spawned` → `game_over`. | D5 |
| A11 | Thắng và thua cùng tick | Thắng ưu tiên. Nếu đèn thứ 5 sáng cùng tick với điều kiện thua thì kết quả là `won`, `reason: all_lit`. | D4, Q2; `lifecycle_system.gd` |
| A12 | Thứ tự kiểm tra kết thúc | `all_lit` → `no_flames` → `dawn`. | `lifecycle_system.gd` |
| A13 | Thời điểm cộng điểm thưởng | Chỉ khi thắng, một lần, trong đúng bước thắng: `50 × flames còn lại + 1 × số giây còn lại`. | `lifecycle_system.gd` |
| A14 | Số giây còn lại | `time_left = time_left_initial − (steps+1)/60`, tính sau bước đó. Số giây cộng điểm là `floor(max(0, remaining_ticks/60))`. | `lifecycle_system.gd` |
| A15 | Dung sai khoảng cách | Biên bán kính (nhặt, nạp, pulse, va chạm shade) cộng thêm `1e-4` để bù sai số float32. | `mote_system.gd`, `lantern_system.gd` |
| A16 | `fall_enabled = false` | Không có mất máu do rơi. Không có event `player_hit` với `by: "fall"`. | Test Contract; `game_config.gd` |
| A17 | Tái xuất hiện đom đóm | Ban đầu 30 đom đóm. Khi số đom đóm dưới 30, cứ mỗi 120 tick thêm một đom đóm mới (cho đến khi đủ 30). | `docs/TASKS.md` mục 3; `spawn_system.gd` |
| A18 | Bóng Mực mới | Ban đầu 3 shade. Cứ 20 giây thêm một shade, tối đa 5 shade. | `docs/TASKS.md` mục 3; `spawn_system.gd` |
| A19 | Vị trí đèn | 5 đèn trên vòng bán kính 25 m quanh tâm đảo. L1 tại (0, 0, 25), các đèn cách nhau 72°. | `docs/TASKS.md` mục 3 |
| A20 | Mô phỏng chuyển động | Core tự mô phỏng di chuyển, trọng lực và nhảy ở 60 Hz (D2). Nhảy một lần cho đến khi chạm đất. Đảo bán kính 45 m. Scene chỉ hiển thị. | D2, Q4; `player_system.gd` |
| A21 | Tuning | Toàn bộ là giá trị tạm (provisional), chờ Product Owner duyệt (Q5). | D3; `game_config.gd` |
| A22 | Đầu ra headless khi kết thúc | Khi status là `won` hoặc `lost`, runner dừng sớm và vẫn ghi dòng `end` cuối. | `headless_runner.gd` |

## Phase 2 (bổ sung)
| Mục mơ hồ | Quyết định |
|---|---|
| Test Contract v1.1 gốc không có trong repo | Tên trường snapshot/scenario/event suy từ bản tóm tắt ticket (`interfaces_v2.md`) |
| Điểm đom đóm | Cộng khi nhặt (khớp ví dụ contract v1.0 và Product Owner xác nhận); ticket ghi `per_mote_delivered` |
| Chiều của góc | Dùng `x = cx + r·cos a`, `z = cz + r·sin a` vì khớp tọa độ ticket (dù mô tả là ngược chiều kim đồng hồ) |
| `fall_enabled` | true ở v1.1 (rơi khỏi đảo bị phạt) |
| Bóng Mực Đêm 2/3 | 2 con ở tick 300 rồi theo interval từng đêm; max_alive tính chung; khoảng cách ≥ 15 m áp dụng mọi đêm; wander 0,5× tốc độ; `spawning` 30 tick |
| Pulse trúng Gió Lạc | Không cộng điểm |
| `night_start` | Sim phát ở bước đầu mọi đêm (kể cả Đêm 1); kịch bản Phase 1 bỏ qua event này |
| Tạm dừng | `tick` tăng, `sim_tick`/thời gian/hồi chiêu/spawn đứng yên; nhấn pause khi đang dừng thì tiếp tục |
| `ttl_s` đom đóm ngẫu nhiên | -1 |

## Phase 3 (contract v1.2, TICKET-03)
Chưa có file `TEST_CONTRACT_v1.2.md`, tên trường lấy từ ticket mục 7. Product Owner chọn Q1 = A; Q2–Q9 dùng theo đề xuất trong `docs/TASKS_P3.md`.
| # | Mục mơ hồ | Quyết định |
|---|---|---|
| Q1 | "Đi về đèn tắt gần nhất như trước" (Phase 2 vốn đi ngẫu nhiên) | Wander nhắm đèn yếu (sáng, fuel < 30) gần nhất, không có thì nhắm đèn tắt gần nhất, hòa thì id nhỏ hơn. Không còn đèn tắt thì đi ngẫu nhiên. Tốc độ wander 0,5×. |
| Q2 | `fuel_drain` mỗi 60 tick | Đếm theo từng con từ lúc vào `drain`; phát ở tick hút thứ 60, 120, …; `fuel` là giá trị sau khi trừ ở tick đó |
| Q3 | Event khi nạp | Thắp mới/thắp lại phát `deposit` + `lantern_lit{relight}`; châm dầu chỉ phát `refuel` |
| Q4 | Đẩy Bóng Mực khi châm lên ≥ 30 | Dùng chung cơ chế vùng an toàn: mọi con ở trong 6 m của đèn có fuel ≥ 30 bị đẩy ra trong ≤ 30 tick, không gây sát thương |
| Q5 | Scenario `lit:true` thiếu trường | Thiếu `fuel` thì 100; thiếu `ever_lit` thì bằng `lit`; `relit_count` 0; đèn đặt sẵn không tính `successful_lights` |
| Q6 | Làm tròn `fuel` | Lưu số nguyên 1/60; xuất `round_half_up(units/6)/10`; đèn tắt 0.0 |
| Q7 | `drain` có gây hit không | Không; chỉ `wander`/`chase` gây hit |
| Q8 | Đèn hết dầu ở tick bình minh | Tắt ở bước 2b trước, xét thắng/thua ở bước 11 sau |
| Q9 | Pulse +15 | Con đang `drain` lúc bị pulse thì tổng +15, còn lại +5 |
| Q10 | Hết choáng | Về `wander` (ticket mục 2), áp dụng cho mọi Bóng Mực |
| Q11 | Tên khóa `score` trong `game.contract.json` | `per_mote` 5, `per_lantern` 100, `per_relight` 40, `per_stun` 5, `per_stun_drain` 15, `per_lit_lantern_dawn` 50, `per_flame_left` 50 |
| Q12 | Thứ tự khóa snapshot mới | lantern `{id,pos,lit,deposited,fuel,ever_lit,relit_count}`; player thêm `capacity` sau `carried` |
| Q13 | Giá trị scenario hợp lệ | `fuel` trong [0,100]; `target_lantern_id` phải là id đèn có thật hoặc ""; sai thì thoát mã 2 |
| Q14 | Mắt Bóng Mực | Đổi cùng màu viền (#7A3CFF / #00B3FF) theo ticket mục 6 (Phase 2 dùng mắt vàng) |

