# Thiết lập môi trường — 2026-11-20

## Quyết định
- Lab cho phép tự chọn công nghệ. Chọn JavaScript, Node.js 24 LTS, Three.js và Vite.
- Giao diện chạy trong trình duyệt; logic thuần chạy bằng Node.js trên Windows/macOS/Linux.
- Node.js Windows đặt riêng ở thư mục lab/.tools, không đưa vào Git.
- Giữ nguyên README và tài liệu đề bài; hướng dẫn môi trường ở docs/SETUP.md.

## Giới hạn
- Chưa có nội dung PRD-0 / Test Contract trong repo. Không tự đoán luật chơi hoặc giao thức chấm.
- Headless hiện chỉ kiểm tra môi trường, chưa đáp ứng Test Contract.
- Chưa xác nhận repo public, đăng nhập lab board, thời gian buổi lab hoặc lớp L3A/L3B.
- Chưa thực hiện Phase 1, tạo tag, Release hoặc video.

## Nhật ký AI
- AI kiểm tra công cụ, tạo khung môi trường, logic độc lập giao diện và lệnh kiểm chứng.
- Token/chi phí: không có số liệu từ phiên công cụ; cần bổ sung từ thống kê tài khoản nếu có.

## Kết quả thực chạy
- Node.js v24.22.3; Three.js và Vite được ghim trong package-lock.json.
- Test, headless smoke, build: đạt (xem environment-check.txt).
- Dev server HTTP 200 tại localhost:5173.
- Build cảnh báo bundle >500 kB; chưa tối ưu ở CP0.
- Chưa quan sát WebGL bằng trình duyệt; chưa kiểm tra thực tế trên macOS/Linux.

