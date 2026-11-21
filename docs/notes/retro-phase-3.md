# Retro Phase 3 ("Đèn cạn dầu")

## Số liệu
- 6 commit cho Phase 3: A0, B1–B4, C1, D1, D2 và một commit sửa nhỏ.
- Test lõi: 3055 lượt kiểm tra (Phase 2) → 3178. Kịch bản: 18 (P1) + 39 (P2) + **17 mới** (P3). Tất cả đạt ở lần chạy cuối.
- Phải sửa đáp án vì luật bị thay: 5 kịch bản P1, 9 kịch bản P2, 7 file test đơn vị. Không có test nào bị skip.
- Token: không có số đo (xem `docs/ai-log.md` mục 6).

## Đánh giá theo yêu cầu
- **Đạt:** mục 1–5 và 7 của ticket, có kịch bản đáp án tính tay; review độc lập không có lỗi nghiêm trọng.
- **Đạt một phần:** mục 6. Logic và cài đặt có test, có ảnh chụp, nhưng chưa có người chơi thử bằng tay.
- **Hỏng phase trước?** Không. Những luật ticket không thay thế vẫn đạt toàn bộ. Có thay đổi hành vi mà test cũ không bắt: Bóng Mực wander đi về đèn tắt (Q1 = A), và hết choáng thì về wander.

## Điều làm tốt
- Lập kế hoạch và liệt kê luật bị thay **trước** khi code (`docs/TASKS_P3.md` mục 0). Đưa câu hỏi mơ hồ (Q1) cho Product Owner, không tự quyết.
- Tính dầu bằng số nguyên 1/60 nên không có lỗi làm tròn; tất định giữ được 7/7.
- Đáp án kịch bản tính tay trước khi chạy. Khi mọi kịch bản đạt ngay lần đầu, kiểm tra ngược bằng output sai để chắc checker thật sự soi.

## Điều chưa tốt
- Đo hiệu năng không ổn định: cùng code, Đêm 3 lúc mất 17 s, lúc mất 31 s (laptop chạy pin). Chưa có cách đo tách khỏi trạng thái máy.
- Script `verify_determinism.sh` ghi output vào thư mục bằng chứng Phase 1, nên chạy lại là làm bẩn bằng chứng cũ. Đã khôi phục bằng git; cần sửa script ở Phase 4 để ghi ra thư mục riêng.
- Chưa có file `TEST_CONTRACT_v1.2.md` gốc, nên tên khóa `score`, thứ tự khóa snapshot và nhịp đếm `fuel_drain` vẫn là giả định.
- Harness: quoting của heredoc trong bash hỏng hai lần; chuyển sang ghi script Python ra file.

## Việc cho Phase 4
- Sửa `verify_determinism.sh` để không ghi đè bằng chứng Phase 1. Đo hiệu năng khi cắm sạc, ghi cấu hình máy.
- Chơi thử bằng tay (camera, nhảy, pulse, châm dầu, chế độ mù màu) và quay video.
- Thêm hook hoặc skill chặn agent kết thúc khi test đỏ (hạng mục C và B của rubric).
- Bổ sung retro Phase 2 (vẫn còn thiếu).
