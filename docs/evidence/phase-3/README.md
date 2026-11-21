# Bằng chứng Phase 3 ("Đèn cạn dầu", contract v1.2)

Mọi file ở đây là output thật, không sửa tay; riêng dòng `#` đầu file là ghi chú của người chạy. Máy chạy: Windows 11, Godot 4.7.2, laptop chạy pin.

| Yêu cầu (TICKET-03) | Cách kiểm chứng | Bằng chứng | Kết quả |
|---|---|---|---|
| Mục 1: dầu đèn, châm dầu, tắt, thắp lại | Kịch bản `f01`, `f02`, `f04`; test `test_lantern_v3`, `test_mote_lantern` | `scenarios_p3.txt`, `core_tests.txt` | Đạt |
| Mục 2: Bóng Mực hút dầu, mất vùng an toàn khi fuel < 30, đẩy ra khi châm lên ≥ 30 | Kịch bản `d01`–`d05`; `test_lantern_v3` (mục tiêu, hòa id, fuel 30 và 29,98) | `scenarios_p3.txt`, `core_tests.txt` | Đạt |
| Mục 3: luật thắng ở bình minh, Đêm 240/270/300 s, `no_flames` ưu tiên | Kịch bản `w01`–`w05`, P1 `s10`/`s17`, P2 `v01`/`v02`; `test_lifecycle_system` | `scenarios_p1.txt`, `scenarios_p2.txt`, `scenarios_p3.txt` | Đạt |
| Mục 4: sức chứa 10 + 2n, tối đa 20 | Kịch bản `c01`, `f04`; `test_config` | `scenarios_p3.txt` | Đạt |
| Mục 5: điểm mới | Đáp án tính tay trong mọi kịch bản (`end.score`) | các file `scenarios_*.txt` | Đạt |
| Mục 6: chế độ mù màu, thanh dầu, nhấp nháy 1 Hz, đèn tắt xẹp và rách | `test_ui_logic` (màu, lưu cài đặt, 1 Hz); ảnh chụp game thật | `evidence/screenshots/p3_fuel_n1.png`, `p3_colorblind_n1.png`, `p3_fuel_bar_n1.png` | Đạt một phần: **chưa có ảnh rõ đèn đang nhấp nháy**, chưa chơi thử bằng tay |
| Mục 7: Test Contract v1.2 (snapshot, scenario, event, tuning) | `test_codec`, `test_config`, kịch bản P3 `e01`–`e03` (thoát mã 2) | `core_tests.txt`, `scenarios_p3.txt` | Đạt theo cách tôi hiểu ticket; file `TEST_CONTRACT_v1.2.md` gốc chưa có |
| Phase 1–2 không bị thay thế vẫn đạt | Chạy lại toàn bộ kịch bản P1 (18) và P2 (39) | `scenarios_p1.txt`, `scenarios_p2.txt` | Đạt; 14 kịch bản bị thay đã sửa có lý do (`docs/notes/p3-regression-changes.md`) |
| Tất định | `bash scripts/verify_determinism.sh` (7 tổ hợp, mỗi tổ hợp chạy 2 lần, so từng byte) | `determinism.txt` | 7/7 giống hệt |
| Hiệu năng (Đêm 3 ≤ 30 s) | `test_e2e` | `core_tests.txt` | 17,1 s ở lần này; **các lần đo trước khi chạy pin là 30,8–31,6 s (fail)**. Bản `phase-2` đo trên cùng máy cùng lúc cũng chậm như vậy |
| Review độc lập | Subagent khác đọc diff, đối chiếu ticket | `E1_review.md` | Không có lỗi nghiêm trọng; 4 lỗi nhỏ đã xử lý hoặc ghi lại |

Tổng kết lần chạy cuối: test lõi `checks=3178 failures=0`; P1 `passed=18 failed=0`; P2 `passed=39 failed=0`; P3 `passed=17 failed=0`; tất định `PASS (7/7)`.

Lệnh chạy:
```
GODOT --headless --path godot --script res://tests/run_core_tests.gd
sh scripts/run_scenarios.sh ; sh scripts/run_scenarios_p2.sh ; sh scripts/run_scenarios_p3.sh
bash scripts/verify_determinism.sh
```
