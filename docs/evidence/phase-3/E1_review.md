# E1: review độc lập Phase 3 (contract v1.2)

- **Người review:** một subagent Claude Sonnet riêng, không phải agent đã viết code Phase 3.
- **Ngày:** 2026-11-21.
- **Cách làm:** chỉ đọc. Không sửa file, không chạy Godot. Đối chiếu `git diff 8ab02c7..HEAD` với `docs/notes/ticket-03.md` mục 1–5 và 7, rồi tính lại bằng tay một số đáp án trong kịch bản.

## Kết luận
**Không có lỗi nghiêm trọng.** Không có chỗ nào trái với ticket mục 1–5 và 7.

## Lỗi nhỏ và cách xử lý
| # | Phát hiện | Xử lý |
|---|---|---|
| 1 | Kịch bản `f02_refuel` không cover ở mức headless hai trường hợp "đèn đầy bị bỏ qua" và "hòa thì chọn id nhỏ hơn" | Hai trường hợp này đã có trong `godot/tests/core/test_lantern_v3.gd` ("bo qua den day dau", "hoa -> L1 (id nho) -> refuel"). Ở headless, đèn sáng luôn bị hao dầu ở bước 2b trước bước 5, nên gần như không bao giờ đầy lúc tương tác. Giữ nguyên. |
| 2 | Comment đầu `shade_system.gd` còn ghi "Hết stunned: chase nếu ≤ 18" | Đã sửa comment (hết choáng về `wander`; hết recoil giữ luật v1.1) |
| 3 | Scenario đặt `lit:false` mà không có `ever_lit` thì `ever_lit = false` | Đúng theo giả định Q5, đã ghi trong `docs/assumptions.md` |
| 4 | `LanternSystem.step` và `_safe_zone` là code chỉ còn test cũ dùng | Giữ lại cho test đơn vị cũ; Sim không gọi |

## Điểm mơ hồ (không phải lỗi, đã ghi giả định)
- Q7: Bóng Mực đang `drain` không gây sát thương.
- Q2: `fuel_drain` đếm 60 tick theo từng con.
- `drain` chuyển `chase` (Mây ≤ 6 m) trước khi xét điều kiện châm dầu; cơ chế đẩy ra và không gây sát thương vẫn áp dụng.

## Đã xác nhận đúng (tóm tắt)
- Dầu tính bằng đơn vị nguyên, công thức châm dầu, chọn đèn khi tương tác, tắt và thắp lại.
- Vùng an toàn ở đúng 30; Bóng Mực nhắm mục tiêu, vào và thoát `drain`; điểm pulse +5/+15.
- Thời gian Đêm 240/270/300 s; ngưỡng thắng `(3N+4)/5`; không thắng sớm; `no_flames` được ưu tiên; thứ tự tick.
- Sức chứa; codec và loader v1.2; `game.contract.json` 1.2.
- Đáp án tính tay đúng: f02, f04, d01–d05, w01, w03, w05, P1 s10/s17, P2 v01.
- Các test cũ được sửa đều có lý do trong `docs/notes/p3-regression-changes.md`. Không có test bị skip hay bị nới điều kiện.
