# Chạy môi trường bài lab

Đây là khung chuẩn bị CP0, chưa phải game Phase 1.

## Windows trên máy hiện tại
Mở PowerShell tại thư mục repo. lab.cmd dùng Node.js riêng, không cần đổi Execution Policy:
```powershell
.\lab.cmd ci
.\lab.cmd run verify
.\lab.cmd run dev
```
Mở địa chỉ localhost do Vite in ra. Bạn cần nhìn thấy khối lập phương quay.
Nếu PowerShell chặn activate.ps1, có thể gọi npm.cmd bằng đường dẫn đầy đủ trong lab/.tools/node-v24.*-win-x64, không cần đổi chính sách toàn máy.

## macOS / Linux hoặc máy khác
Cài Node.js 24 LTS từ https://nodejs.org rồi, tại thư mục repo:
```sh
npm ci
npm run verify
npm run dev
```

## Các lệnh
- `npm run verify`: test, headless smoke và build. Windows dùng `npm.cmd` thay `npm`.
- `npm run headless:smoke`: chạy logic không giao diện, kiểm tra đầu ra và tính lặp lại.
- `npm run build`: tạo bản web tĩnh trong dist/.
- `npm run preview`: xem bản build cục bộ.
- CI Ubuntu tự chạy khi push/PR; chưa được xác nhận cho tới khi chạy trên GitHub.

## Tiếp theo
1. Đưa PRD-0 và Test Contract chính thức vào ngữ cảnh làm việc.
2. Lập tiêu chí nghiệm thu và viết adapter headless đúng contract.
3. Triển khai game và lưu bằng chứng từng phase.
4. Kiểm tra tên repo, Public, LICENSE, tag, Release và video theo SUBMISSION.md.

Build thành công chưa chứng minh trình duyệt render được WebGL. Cần mở trang và quan sát khối lập phương.


