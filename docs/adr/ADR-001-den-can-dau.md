# ADR-001: Mô hình trạng thái đèn có nhiên liệu và luật thắng ở bình minh

- **Trạng thái:** Đã chấp nhận (Phase 3, contract v1.2).
- **Ngày:** 2026-11-21.
- **Nguồn:** TICKET-03 "Đèn cạn dầu" (`docs/notes/ticket-03.md`), kế hoạch `docs/TASKS_P3.md`.

## Bối cảnh
Ở Phase 1–2, đèn chỉ có hai trạng thái: `chưa sáng` → `sáng`. Đèn đã sáng thì sáng mãi, và Đêm kết thúc ngay khi mọi đèn sáng (`won/all_lit`). Playtest cho thấy người chơi giỏi thắp hết đèn trong khoảng 2 phút, nên cuối Đêm không còn căng thẳng. TICKET-03 thay mục tiêu từ "thắp hết" thành "giữ đảo sáng tới bình minh".

## Quyết định

### 1. Đèn có ba trạng thái, nhớ lịch sử
```
          nạp đủ 10              fuel ≤ 0 (bước 2b)
 CHƯA SÁNG ─────────▶ SÁNG(fuel) ───────────────▶ TẮT (ever_lit=true)
 (ever_lit=false)       ▲  │ châm dầu: fuel += 10/mote          │
                        │  └──────────────┘                    │
                        └────────── nạp đủ 5 (thắp lại) ───────┘
```
- `lit=true` luôn đi kèm `fuel_units > 0`. Hết dầu thì `lit=false`, `deposited=0` và `ever_lit=true`.
- `ever_lit` quyết định giá thắp: 5 đom đóm với đèn đã từng sáng, 10 với đèn chưa từng sáng.
- `relit_count` đếm số lần thắp lại.
- "Sáng nhưng fuel < 30" là trạng thái con: đèn **mất vùng an toàn**, nhấp nháy 1 Hz và trở thành mục tiêu của Bóng Mực.

### 2. Nhiên liệu tính bằng số nguyên
`fuel_units` là số nguyên, 1 đơn vị = 1/60 fuel, đầy = 6000. Mỗi tick đèn hao 1 đơn vị, và mỗi Bóng Mực đang hút trừ thêm 5. Mỗi đom đóm châm vào được 600 đơn vị. Ngưỡng yếu là 1800.
- **Lý do:** ticket khuyên làm vậy để tránh sai số số thực. Test Contract cũng yêu cầu output giống hệt từng byte, kể cả khi chạy trên nền tảng khác. Phép trừ số nguyên luôn tất định.
- Chỉ khi xuất ra mới làm tròn: `round_half_up(units / 6) / 10`, cho 1 chữ số thập phân.

### 3. Thứ tự trong tick
Hao dầu là **bước 2b**: `LanternSystem.tick_fuel`, chạy ngay sau bước 2 của Ticket-02.
- Bước 2b trừ dầu theo trạng thái `drain` của Bóng Mực ở cuối tick trước. Đèn hết dầu tắt ngay tại đây và phát `lantern_out`.
- Tương tác với đèn ở bước 5 dùng giá trị đã trừ, vì thế đèn đang sáng gần như không bao giờ "đầy" lúc người chơi tương tác.
- Vùng an toàn và việc đẩy Bóng Mực ra vẫn do `ShadeSystem` xử lý ở bước 8. Châm dầu lên ≥ 30 làm vùng an toàn quay lại, và cơ chế đẩy ra trong tối đa 30 tick, không gây sát thương, tự áp dụng như khi đèn vừa thắp.

### 4. Luật thắng
- Bỏ `all_lit`: thắp đủ đèn không kết thúc Đêm.
- Bước 11 xét theo thứ tự: (1) hết Ngọn Lửa thì `lost/no_flames`, kể cả ở tick cuối; (2) nếu hết giờ, đếm số đèn **đang sáng sau bước 2b** của tick cuối: ≥ ceil(0,6·N) thì `won/dawn_survived`, ngược lại `lost/dawn`.
- `ceil(0,6·N)` tính bằng số nguyên `(3N + 4) / 5`, không dùng số thực.
- Thưởng khi thắng: Σ(50 + floor(fuel)) cho mỗi đèn sáng, cộng 50 cho mỗi Ngọn Lửa. Bỏ thưởng theo thời gian.

### 5. Bóng Mực
Thêm trạng thái `drain`.
- Ở trạng thái `wander`, Bóng Mực nhắm đèn yếu gần nhất. Không có đèn yếu thì nhắm đèn tắt gần nhất (Q1 = A, Product Owner chọn). Không còn đèn tắt nào thì đi ngẫu nhiên như v1.1.
- Đến cách đèn yếu ≤ 2 m thì chuyển sang `drain`.
- Hết choáng thì về `wander`.

## Hệ quả
- **Breaking changes** (danh sách đầy đủ trong `CHANGELOG.md`): đổi thời gian Đêm, đổi công thức điểm, bỏ `all_lit`, snapshot có thêm trường mới, wander đổi hướng đi.
- 14 kịch bản Phase 1–2 và 4 file test đơn vị phải sửa đáp án. Lý do từng chỗ ở `docs/notes/p3-regression-changes.md`. Không có test nào bị skip.
- Đánh đổi: hành vi wander mới (đi về đèn tắt) làm Bóng Mực tụ quanh đèn tắt, nên vị trí đầu ra headless của Phase 2 thay đổi. Tôi chấp nhận vì ticket ghi rõ hành vi này.

## Phương án đã loại
- **Lưu fuel bằng số thực** (`float`): đơn giản hơn nhưng dễ lệch chữ số cuối, nguy hiểm cho yêu cầu so từng byte.
- **Thêm enum `state` cho đèn** (`unlit|lit|out`): dễ đọc hơn, nhưng phải đổi mọi chỗ đang đọc `lit`, kể cả codec và view. Dùng `lit` cộng `ever_lit` cho cùng thông tin mà không làm vỡ giao diện v1.1.
