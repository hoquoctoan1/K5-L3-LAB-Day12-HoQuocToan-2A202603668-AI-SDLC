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
