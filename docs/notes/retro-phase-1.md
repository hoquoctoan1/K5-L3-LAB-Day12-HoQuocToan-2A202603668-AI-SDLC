# Retro Phase 1

## Đã làm tốt
- Đối chiếu Test Contract với PRD trước khi code, chốt các luật mơ hồ sớm (`docs/notes/test-contract-mapping.md`, `docs/assumptions.md`).
- Core thuần, tất định, tách khỏi render; một `Sim` dùng chung cho GUI và headless.
- Chia việc song song với quyền sở hữu file riêng; mỗi task có test chạy được; reviewer độc lập (E1) tìm ra lỗi đường dẫn tương đối mà các agent khác bỏ sót.

## Chưa tốt / bài học
- Hiểu sai ban đầu (giả định Node/Three.js, mô hình "ánh sáng/máu") rồi phải đổi sang Godot và mô hình mang-nạp của contract.
- Godot không đăng ký `class_name` mới nếu không chạy import (hay treo); phải dùng `preload`.
- Báo cáo "pass" của agent không đủ: harness test ban đầu để lọt lỗi nạp script, đã sửa; mọi con số trong README là kết quả tôi chạy lại.
- Bot demo chưa tự thắng; chưa có người chơi thử phím/chuột thật khi tag; CI/Docker/macOS/Linux chưa chạy.

## Token
Xem `docs/ai-log.md` (số liệu agent tự báo, phần điều phối là ước tính).

## Việc để dành
- Sửa scenario `random_*:true` kèm danh sách rỗng; `headless.cmd` dùng đường dẫn tương đối.
- Ảnh so sánh trước/sau cho hiệu ứng ánh sáng; chơi thử trên macOS/Linux.
