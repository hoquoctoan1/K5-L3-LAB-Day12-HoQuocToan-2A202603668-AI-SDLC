# Regression Phase 2 → luật Phase 3 (contract v1.2)

Nguồn luật: `docs/notes/ticket-03.md`. Nguyên tắc: test nào bị luật mới làm sai thì sửa đáp án theo luật mới, đáp án **tính tay**, không chép output. Không có test nào bị skip hay xóa.
Kiểm bằng: `GODOT --headless --path godot --script res://tests/run_core_tests.gd`, `sh scripts/run_scenarios.sh`, `sh scripts/run_scenarios_p2.sh`, `sh scripts/run_scenarios_p3.sh`.

## Test đơn vị (`godot/tests`)
| File | Thay đổi | Luật bị thay (ticket) |
|---|---|---|
| core/test_config.gd | `contract_version` "1.2"; Đêm 14400/16200/18000 tick; kiểm 8 khóa tuning mới, đơn vị dầu, `win_threshold`, sức chứa, fuel làm tròn | mục 3, 4, 7 |
| core/test_lifecycle_system.gd | Viết lại: bỏ `all_lit`/thắng sớm/thưởng giây; thêm thắng 3/5, 4/6, 5/7, thua khi thiếu 1 đèn, `no_flames` ở tick bình minh, thưởng 50 + floor(fuel) | mục 3, 5 |
| core/test_sim.gd | "Thắp đèn cuối thì thắng cùng tick" thành "thắp đèn cuối, Đêm vẫn chạy" (điểm 100 + 5·10, `relight:false`); Đêm 2 hết giờ ở tick 16200 | mục 3, 5, 7 |
| core/test_mote_lantern.gd | Nhặt không cộng điểm; điểm thắp = 100 + 5·10; đèn sáng trong test có dầu đầy (đèn đầy không được chọn, giữ ý "bỏ qua đèn sáng") | mục 1, 5 |
| core/test_shade_system.gd | Đèn sáng trong test có `fuel_units` đầy, vì vùng an toàn giờ cần fuel ≥ 30 | mục 2 |
| headless/test_codec.gd | Snapshot mẫu có thêm `capacity`, `fuel`, `ever_lit`, `relit_count` | mục 7 |
| headless/test_e2e.gd | `time_left` theo Đêm 240 s; Đêm 3 hết giờ ở tick 18000 | mục 3 |

## Kịch bản Phase 1 (`tests/scenarios`, chi tiết ở `expected/<tên>.md`, mục "P3")
| Kịch bản | Cũ → mới | Lý do |
|---|---|---|
| s02_pick_mote | score 10 → 0 | nhặt không cộng điểm (mục 5) |
| s04_deposit_partial | score 0 → 15 | +5 mỗi đom đóm nạp |
| s05_deposit_lights | score 100 → 140; `lantern_lit` thêm `relight:false` | mục 5, 7 |
| s10_win_all_lit | won ở tick 1, 458 điểm → `playing` đến tick 600, 150 điểm; L1–L5 còn fuel 90,0 | bỏ thắng sớm (mục 3). Giữ tên file để lịch sử git liên tục; ý nghĩa mới: "thắp đủ đèn KHÔNG thắng sớm" |
| s17_win_beats_dawn | `won/all_lit` 250 → `won/dawn_survived` 1046 | luật thắng và thưởng bình minh mới |

## Kịch bản Phase 2 (`tests/scenarios/p2/check_p2.py`, chú thích "P3 (v1.2)")
| Kịch bản | Cũ → mới | Lý do |
|---|---|---|
| m01_capacity | score 10 → 0; thêm kiểm `capacity` 10 | mục 4, 5 |
| l01_partial_fill | score 0 → 20 | +5 mỗi đom đóm nạp |
| l02_complete_fill | score 100 → 115; `relight:false` | mục 5, 7 |
| pa01_pause | `time_left` 300 − x → 240 − x | Đêm 1 = 240 s |
| n01/n02/n03_night_start | `time_left` 300/330/360 → 240/270/300 | mục 3 |
| t01–t03 (không có trong `SETS`) | tick bình minh 18000/19800/21600 → 14400/16200/18000 | mục 3 |
| tb01_ticks0_n3 | 360 → 300 | mục 3 |
| v01_win_beats_dawn_n2 | `won/all_lit` 250 → `won/dawn_survived` 1160 | mục 3, 5 |
| v02_win_bonus_n3 | `won` ở tick 1, 398 → `playing` đến tick 10, 150 | bỏ thắng sớm |

Giữ nguyên mà vẫn đạt (đã chạy): các kịch bản còn lại của Phase 1 (13/18) và Phase 2 (30/39), gồm cả `z01_safe_block` và `z02_safe_push`. Hai kịch bản này đạt vì scenario đặt `lit:true` mà thiếu `fuel` thì mặc định fuel 100, nên đèn vẫn có vùng an toàn.

## Hành vi đổi nhưng không test cũ nào bắt
- Bóng Mực ở `wander` đi về đèn tắt gần nhất thay vì đi ngẫu nhiên (Q1 = A). Vị trí Bóng Mực trong các lần chạy dài sẽ khác bản Phase 2.
- Hết choáng thì về `wander`, thay cho "về `chase` nếu ≤ 18 m".
