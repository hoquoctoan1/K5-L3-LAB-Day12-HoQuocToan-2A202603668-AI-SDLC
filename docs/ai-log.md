# Nhật ký dùng AI

Mọi số token dưới đây là **ước tính**. Không có số đo từ tài khoản trong phiên này. Mục nào chưa có số thì ghi "chưa có số liệu" thay vì đoán.

## 1. Công cụ và mô hình

| Công cụ | Vai trò | Ghi chú |
|---|---|---|
| Claude Code (CLI) | Công cụ chính để code, chạy test, viết tài liệu | Harness: `AGENTS.md` và `CLAUDE.md` trong repo |
| Claude Sonnet 5.5 | Orchestrator (điều phối, review, tích hợp) | Theo ghi nhận của người điều phối |
| Claude Haiku 5.5 | Subagent cho việc cơ học (codec, test, tài liệu) | Task D4 (tài liệu) trong phiên này chạy trên Haiku 5.5 |
| Claude Sonnet (subagent) | Subagent cho việc có độ phức tạp cao hơn | Phân công theo task, xem `docs/TASKS.md` |

Harness AI (`AGENTS.md`, `CLAUDE.md`, file lệnh) giữ nguyên trong repo và lịch sử git.

## 2. Ước tính token theo task

| Task | Mô hình | Ước tính token | Nguồn số liệu |
|---|---|---|---|
| B1–B8 (mỗi agent) | Haiku/Sonnet | khoảng 45k–80k mỗi agent; tổng 8 agent ước tính 360k–640k | Agent tự báo cáo, chưa đối chiếu với tài khoản |
| Orchestrator (điều phối và review) | Sonnet 5.5 | chưa có số liệu | Không có số đo |
| A0, C1, C2, D1, D2, D3, E1–E3 | các mô hình khác nhau | chưa có số liệu | Không có số đo |
| D4 (tài liệu, phiên này) | Haiku 5.5 | chưa có số liệu | Không có số đo |

Ghi chú: con số tổng ở trên chỉ cộng các báo cáo của từng agent. Không bao gồm token của orchestrator, token của lượt đọc lại, hay lượt chạy lại bị hủy.

## 3. Cách tiết kiệm token

- **Chọn mô hình theo độ khó.** Việc cơ học (codec, test, tài liệu) dùng Haiku. Việc tích hợp và quyết định kiến trúc dùng Sonnet.
- **Quyền sở hữu file hẹp.** Mỗi file có đúng một owner. Agent chỉ sửa file trong cột "Sở hữu" của `docs/TASKS.md`.
- **Giao diện đóng băng.** `sim_state.gd` và `interfaces.md` được tạo một lần ở Wave 0, nên các agent Wave 1 không cần đọc code của nhau.
- **Không đọc toàn repo.** Mỗi agent chỉ đọc mục 0–3 của `docs/TASKS.md`, file contract liên quan, và `interfaces.md`.
- **Kiểm chứng nhanh.** Dùng `--ticks` nhỏ khi chạy headless. Chạy test theo từng system bằng `--only` là cách đã được lên kế hoạch trong `docs/TASKS.md`, chưa xác nhận lại trong D4.

## 4. Prompt chính

Trích nguyên văn các prompt gửi cho agent không có trong repo. Dưới đây là mẫu prompt (tóm tắt) theo cấu trúc trong `docs/TASKS.md`:

- **Mẫu giao task:** "Task `<ID>`. Việc: `<mô tả>`. Sở hữu: `<danh sách file>`. Test phải có: `<tiêu chí>`. Đọc `docs/TASKS.md` mục 0–3 và `interfaces.md`. Không sửa file ngoài cột sở hữu. Báo cáo: ID, file đã đổi, lệnh test và output thật, vấn đề tồn đọng, giả định mới."
- **Mẫu yêu cầu tài liệu (D4):** viết README (tối đa 3 lệnh cài và chạy, điều khiển, điểm, giải thích `null`/`false`, mục "Sáng tạo của tôi", giới hạn đã biết), `docs/assumptions.md`, `docs/ai-log.md`, `LICENSE`, `CHANGELOG.md`, `Dockerfile`. Không ghi "pass" cho test chưa chạy. Chưa có bằng chứng thì ghi là chưa có.

## 5. Điều đáng ghi nhận

- Báo cáo của agent cần được kiểm tra lại. `docs/TASKS.md` mục 6 yêu cầu mọi báo cáo kèm lệnh đã chạy và output thật. Khi nhận báo cáo, cần đối chiếu với output đó trước khi tin.
- Tài liệu dùng nhiều ngôn ngữ cùng lúc (tiếng Việt cho người chấm, tên kỹ thuật tiếng Anh). Chấp nhận được, nhưng cần nhất quán trong từng file.
- Một số chi tiết trong README (điều khiển, scripts test) chưa tồn tại trong repo khi viết. README phải ghi rõ điều đó thay vì mô tả như đã có.
