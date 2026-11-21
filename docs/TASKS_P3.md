# Kế hoạch Phase 3 — "Đèn cạn dầu" (tag `phase-3`, contract v1.2)

Nguồn: TICKET-03, bản nguyên văn ở `docs/notes/ticket-03.md` (Product Owner dán ngày 2026-11-21). Thứ tự ưu tiên: Test Contract v1.2 (chỉ có phần tóm tắt trong ticket mục 7) > TICKET-03 > TICKET-02 > PRD. Hiện chưa có file `contract/TEST_CONTRACT_v1.2.md`. Tên trường lấy từ ticket mục 7; chỗ nào ticket không nói rõ thì ghi **[GIẢ ĐỊNH]**.
Thời lượng phase: khoảng 30 phút, nên làm phần **lõi, headless và regression trước**, phần hiển thị sau.

## 0. Luật bị thay thế và phạm vi ảnh hưởng
| Luật cũ (Phase 1–2) | Luật mới (TICKET-03) | Code bị ảnh hưởng | Test, kịch bản bị ảnh hưởng |
|---|---|---|---|
| Đèn đã sáng không nhận thêm đom đóm | Đèn có nhiên liệu; châm dầu; hết dầu thì tắt; thắp lại tốn 5 | `lantern_system.gd`, `sim_state.gd`, `sim.gd` (bước 2) | `test_mote_lantern`, P2 `l01`, `l02` |
| Bóng Mực không bao giờ vào vùng an toàn | Đèn có fuel < 30 mất vùng an toàn; có trạng thái `drain` | `shade_system.gd`, `lantern_system.gd` (`in_safe_zone`) | `test_shade_system`, P2 `z01`, `z02` |
| Thắng ngay khi mọi đèn sáng (`all_lit`) | Thắng ở bình minh nếu số đèn sáng ≥ ceil(0.6·N) (`dawn_survived`) | `lifecycle_system.gd` | P1 `s10`; P2 `v01`, `v02`, `v03`, `tb02`, `tb03`; `test_lifecycle_system`, `test_sim` |
| Đêm dài 300 / 330 / 360 s | 240 / 270 / 300 s | `game_config.gd`, `game.contract.json` | mọi snapshot có `time_left_s`, các test dawn, `n3_timing` |
| Điểm: +10 khi nhặt, +100 mỗi đèn, thưởng giây ×2 | +5 mỗi đom đóm nạp, +100 thắp lần đầu, +40 thắp lại, +5/+15 khi pulse, thưởng bình minh | `mote_system.gd`, `lantern_system.gd`, `pulse_system.gd`, `lifecycle_system.gd` | mọi expected có `score` |
| Sức chứa cố định 10 | 10 + 2 × successful_lights, tối đa 20 | `mote_system.gd`, `sim_state.gd` | P2 `m01`, `test_mote_lantern` |

Quy tắc regression: test nào bị luật mới làm sai thì **sửa expected hoặc xóa, kèm lý do** trong `docs/notes/p3-regression-changes.md`. Không được skip âm thầm. Test Phase 1–2 không bị thay thế thì vẫn phải đạt.

## 1. Câu hỏi mở và giả định
**Đã chốt ngày 2026-11-21:** Product Owner chọn **Q1 = A**. Q2–Q9 dùng theo đề xuất bên dưới, vì Product Owner không phản đối.
| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | Ticket ghi "Không có [đèn yếu] thì đi về đèn tắt gần nhất **như trước**". Nhưng PRD và Phase 2 **chưa từng có** luật này: wander hiện là đi ngẫu nhiên (`shade_system.gd`). | **Đề xuất A:** wander đi về đèn tắt gần nhất (XZ, hòa thì id nhỏ hơn). Nếu không còn đèn tắt nào thì giữ đi ngẫu nhiên. Cách này làm đổi output wander của Phase 2, cần ghi trong regression. **Phương án B:** giữ đi ngẫu nhiên, chỉ thêm việc nhắm đèn yếu. |
| Q2 | Sự kiện `fuel_drain` "ghi mỗi 60 tick khi đang hút": đếm theo từng con hay theo đồng hồ chung? | Đếm theo từng con, tính từ lúc vào `drain`. Phát ở tick hút thứ 60, 120, … `fuel` là giá trị sau khi trừ dầu ở tick đó. |
| Q3 | `deposit` có còn phát khi thắp mới hoặc thắp lại không? Châm dầu thì phát gì? | Thắp mới và thắp lại vẫn phát `deposit` (giữ v1.1). Châm dầu chỉ phát `refuel{lantern_id, amount, fuel}`, không phát `deposit`. |
| Q4 | Đẩy Bóng Mực khi châm dầu lên ≥ 30: chỉ khi vượt ngưỡng từ < 30, hay mọi lần châm? | Mọi con đang ở trong 6 m của một đèn có fuel ≥ 30 đều bị đẩy, dùng chung cơ chế `safe_push_ticks` hiện có. Như vậy tự đúng cả cho lúc vượt ngưỡng lẫn lúc vừa thắp. |
| Q5 | Scenario đặt `lit:true` nhưng thiếu `ever_lit` | `ever_lit` mặc định bằng `lit`. `fuel` mặc định 100 (ticket đã ghi). `relit_count` mặc định 0. |
| Q6 | Làm tròn `fuel` khi xuất | Lưu `fuel_ticks` là số nguyên, 1 đơn vị = 1/60 fuel (đầy = 6000). Xuất `round_half_up(fuel_ticks / 6) / 10` với 1 chữ số thập phân. Đèn tắt xuất `0.0`. |
| Q7 | Bóng Mực đang `drain` thì có chạm làm Mây mất lửa không? | Không. Chỉ `wander` và `chase` gây hit (giữ v1.1). Mây vào trong 6 m thì nó chuyển sang `chase` trước. |
| Q8 | Đèn tắt giữa lúc hút, hoặc fuel ≤ 0 đúng tick bình minh | Ở bước 2, đèn có fuel ≤ 0 tắt ngay, phát `lantern_out` trong cùng tick. Thắng hay thua xét **sau** đó, ở bước 11. |
| Q9 | Điểm pulse "+15 nếu ngay trước đó đang drain" | Con đang ở trạng thái `drain` lúc bị pulse thì +15, còn lại +5. Không cộng dồn hai mức. |

## 2. Task (mỗi file chỉ có một owner)
### Wave 0 — chặn mọi việc khác (một agent)
| ID | Việc | Sở hữu | Tiêu chí nghiệm thu |
|---|---|---|---|
| A0-P3 | Đổi số chuẩn v1.2: `CONTRACT_VERSION "1.2"`, thời gian Đêm 240/270/300, `FUEL_MAX`, `FUEL_DECAY_PER_S`, `FUEL_PER_MOTE`, `RELIGHT_COST`, `WIN_RATIO`, `DRAIN_PER_S`, `LOW_FUEL_THRESHOLD`, `CAPACITY_MAX`, điểm mới. Thêm vào `tuning_dict()` và `game.contract.json`. Mở rộng `SimState`: lantern `fuel_ticks, ever_lit, relit_count`; player `successful_lights`; shade `target_lantern_id, drain_ticks`; helper `capacity(state)`. Viết mục v1.2 trong `interfaces_v2.md` (khung, tên trường, thứ tự bước 2). | `game_config.gd`, `game.contract.json`, `sim_state.gd`, `interfaces_v2.md`, `tests/core/test_config.gd` | `test_config` đạt (JSON khớp config). Các test khác **được phép đỏ** chờ Wave 1, nhưng phải ghi danh sách test đỏ. |

### Wave 1 — làm song song
| ID | Việc | Sở hữu | Tiêu chí nghiệm thu (test đơn vị) |
|---|---|---|---|
| P3-B1 | Lantern v3: chọn đèn nhận được (đèn chưa sáng, hoặc sáng nhưng chưa đầy); thắp mới (10) và thắp lại (5, với `ever_lit`); châm dầu `used = min(carried, ceil((6000−ft)/600))`; `lantern_lit{relight}`, `refuel`; điểm +5/mote, +100/+40; `successful_lights += 1`; `in_safe_zone` chỉ tính đèn có fuel ≥ 30; hàm mới `tick_fuel(state, events)` (bước 2: hao 1 đơn vị/tick, mỗi con drain trừ 5 đơn vị/tick; fuel ≤ 0 thì tắt, `deposited = 0`, `lantern_out`). | `systems/lantern_system.gd`, `tests/core/test_lantern_v3.gd` | Châm từ 73,4 lên 100 dùng 3 mote. Đèn đầy không được chọn, không có event. Hai đèn cách bằng nhau thì chọn id nhỏ hơn. 6000 tick thì tắt đúng tick. Thắp lại tốn 5. fuel đúng 30 vẫn còn vùng an toàn, 29,98 thì mất. |
| P3-B2 | Shade v3: wander nhắm đèn sáng có fuel < 30 gần nhất (xem Q1); trạng thái `drain` khi ≤ 2 m (đứng yên); chuyển trạng thái drain → chase (Mây ≤ 6 m), → stunned, → wander (đèn tắt, fuel ≥ 30, hoặc > 2 m); `fuel_drain` mỗi 60 tick; `_zone_of` dùng fuel ≥ 30; hết choáng thì về `wander`. Pulse: +15 nếu con bị trúng đang `drain`. | `systems/shade_system.gd`, `systems/pulse_system.gd`, `tests/core/test_shade_v3.gd` | 2 con hút thì mỗi tick trừ 10+1 đơn vị. Đi vào đúng đèn yếu, hòa thì id nhỏ hơn. Mây đi vào 6 m thì chuyển `chase`. Châm lên ≥ 30 thì bị đẩy ra trong ≤ 30 tick, không gây hit. Pulse con đang drain cho +15. |
| P3-B3 | Lifecycle v3 và điểm khi nhặt: bỏ `all_lit`; ở tick cuối, lửa ≤ 0 thì `no_flames`; số đèn sáng ≥ ceil(0.6·N) thì `won/dawn_survived` kèm thưởng Σ(50 + floor(fuel)) + 50·lửa, ngược lại `lost/dawn`. `mote_system`: bỏ điểm khi nhặt, sức chứa dùng `capacity(state)`. `sim.gd`: gọi `LanternSys.tick_fuel` ngay sau bước 2. | `systems/lifecycle_system.gd`, `systems/mote_system.gd`, `sim.gd`, `tests/core/test_lifecycle_system.gd`, `tests/core/test_sim.gd` | Đêm 1 với 3/5 đèn sáng ở tick 14400 thì thắng. 2/5 thì `dawn`. Đủ 5/5 sớm thì **không** kết thúc. Lửa = 0 ở tick cuối thì `no_flames`. Thưởng tính đúng. |
| P3-B4 | Codec và loader v1.2: snapshot lantern `fuel` (1 chữ số thập phân), `ever_lit`, `relit_count`; player `capacity`; shade state `drain`; scenario lantern `lit, fuel, ever_lit`, player `successful_lights`, shade `target_lantern_id`, state `drain` hợp lệ; dữ liệu sai thì thoát mã 2. | `adapters/headless/*`, `tests/headless/test_codec.gd` | Snapshot mẫu đúng thứ tự khóa. Đặt `fuel:-1` hoặc `fuel:101` thì thoát mã 2 [GIẢ ĐỊNH: hợp lệ là 0..100]. `lit:true` thiếu `fuel` thì ra `fuel:100.0`. |

### Wave 2
| ID | Việc | Sở hữu |
|---|---|---|
| P3-C1 | Regression: chạy lại P1 (18) và P2 (39). Mỗi kịch bản bị luật mới làm sai thì sửa expected hoặc xóa, ghi lý do trong `docs/notes/p3-regression-changes.md`. Kịch bản mới ở `tests/scenarios/p3/` (ít nhất: hao dầu đến tắt, châm dầu, đèn đầy bị bỏ qua, thắp lại 5, drain 1 con và 2 con, drain → chase, drain → pulse +15, châm lên ≥ 30 đẩy ra, thắng 3/5, thua 2/5, `no_flames` ở tick bình minh, capacity 10 → 20, `fuel_drain` mỗi 60 tick, scenario sai thoát mã 2). Script `scripts/run_scenarios_p3.sh`. Chạy `verify_determinism.sh`. | `tests/scenarios/**`, `scripts/run_scenarios*.sh`, `scripts/verify_determinism.sh`, `docs/notes/p3-regression-changes.md` |
| P3-D1 | View/HUD: thanh dầu; nhấp nháy 1 Hz khi fuel < 30; HUD `đang mang/sức chứa`; ánh sáng môi trường giảm khi đèn tắt; cài đặt "Bảng màu dễ phân biệt" được lưu (Bóng Mực #00B3FF, cảnh báo #FFFFFF kèm ⚠); đèn tắt xẹp 20% và giấy rách. | `adapters/view/**`, `scenes/**`, `tests/core/test_ui_logic.gd` |
| P3-D2 | Tài liệu: ADR `docs/adr/ADR-003-lantern-fuel-and-dawn-win.md` (mô hình trạng thái đèn chưa sáng → sáng(fuel) → tắt(ever_lit); luật thắng mới; lý do dùng đơn vị nguyên 1/60); `CHANGELOG.md` mục Phase 3 **Breaking changes**; README; `docs/assumptions.md` (Q1–Q9); `docs/ai-log.md`; retro Phase 2 và Phase 3. | các file đã nêu |

### Wave 3
E1: reviewer độc lập (không phải agent đã viết code) đối chiếu với ticket mục 1–7. E2: chạy thật toàn bộ test và lưu log ở `docs/evidence/phase-3/`. E3: tag `phase-3` sau khi Product Owner đồng ý.

## 3. Lệnh kiểm chứng (phải chạy thật, lưu output)
```
GODOT --headless --path godot --script res://tests/run_core_tests.gd   > docs/evidence/phase-3/core_tests.txt
sh scripts/run_scenarios.sh      # P1, sau khi cập nhật regression
sh scripts/run_scenarios_p2.sh   # P2, sau khi cập nhật regression
sh scripts/run_scenarios_p3.sh   # P3 mới
bash scripts/verify_determinism.sh
```
Hiệu năng: Đêm 3 đủ 18000 tick, chạy hai lần giống hệt, ≤ 30 s.

## 4. Quy tắc (giữ từ Phase 1–2)
Mỗi file một owner. Không chạy `--import`/`--editor`. File mới tham chiếu bằng `preload`. Chọn model theo độ khó. Không nói "pass" khi chưa chạy thật. Push vào `main` chỉ khi test, kịch bản và kiểm tra tất định đạt thật.

## 5. Trạng thái
| ID | Trạng thái |
|---|---|
| A0-P3 | TESTING → REVIEW: `test_config` đạt. Core 3142 checks, 10 failures; cả 10 là test luật cũ bị thay (thời gian Đêm 300/330/360 s, thưởng giây): `test_lifecycle_system` 6, `test_sim` 1, `test_e2e` 3. Log ở `docs/evidence/phase-3/a0_core_tests.txt`. Chưa chạy kịch bản P1/P2 (việc của C1). |
| P3-B1..B4 | TODO (đã có thể bắt đầu). `test_e2e.gd` giao cho P3-B4. |
| P3-C1, D1, D2 | TODO |
| E1–E3 | TODO |
