Video demo: (se bo sung o Phase 4)

# Đảo Đèn Lồng

Game 3D góc nhìn thứ ba làm bằng Godot 4.7 (GDScript). Bạn là người giữ đèn nhỏ tuổi trên một hòn đảo giữa sương đen. Gom đom đóm, thắp Đèn Lồng Lớn và **giữ chúng sáng tới bình minh**: đèn hao dầu và Bóng Mực tìm đến hút dầu đèn yếu. Thắng khi còn sống lúc bình minh với ít nhất 60% số đèn đang sáng. Thua khi hết Ngọn Lửa (`no_flames`) hoặc bình minh mà thiếu đèn (`dawn`).

Trạng thái: **Phase 3 ("Đèn cạn dầu", contract v1.2).** Đã có tag `phase-1` và `phase-2`. Quyết định thiết kế ở `docs/adr/ADR-001-den-can-dau.md`, thay đổi phá vỡ tương thích ở `CHANGELOG.md`. Các mục chưa xác minh được ghi trong "Giới hạn đã biết".

## Cài đặt và chạy

Yêu cầu: Godot 4.7 đã cài. Nếu lệnh `godot` không có trong PATH, đặt biến môi trường `GODOT` trỏ tới file thực thi.

```bash
git clone <link-repo> && cd <thu-muc-repo>
godot --path godot
scripts/headless.sh --seed 1 --night 1 --ticks 600 --out out.jsonl
```

Windows: thay dòng cuối bằng `scripts\headless.cmd --seed 1 --night 1 --ticks 600 --out out.jsonl` (wrapper đọc biến `GODOT`, mặc định là `godot`).

Lưu ý GPU: project dùng renderer `gl_compatibility` (OpenGL). Trên máy Intel UHD, cửa sổ game có thể đen hoặc lỗi do driver OpenGL; chưa kiểm tra trên máy này. Chế độ headless không mở cửa sổ render.

## Điều khiển

> Điều khiển do `godot/scenes/main/main.gd` đăng ký (task D1). Đã chạy thật: demo tự động và bộ kiểm tra không cửa sổ (nhặt, nạp, thắp đèn, thua, chơi lại). **Chưa có người chơi thử bằng phím và chuột thật**, nên hướng đi theo camera, xoay camera, nhảy, pulse và nút Replay trong cửa sổ chưa được xác minh bằng tay.

| Phím | Tác dụng |
|---|---|
| `W` `A` `S` `D` | Di chuyển, theo hướng camera |
| `Space` | Nhảy |
| `E` | Nạp đom đóm vào Đèn Lồng gần nhất trong 2 m: thắp đèn chưa sáng (10, hoặc 5 nếu đèn từng sáng) hoặc châm dầu đèn đang sáng chưa đầy (mỗi đom đóm +10 dầu) |
| `F` | Tỏa sáng (pulse): tốn đom đóm, làm choáng và đẩy lùi Bóng Mực trong bán kính |
| Chuột, `Q`, `R` | Xoay camera |
| `Shift` | Lướt (dash) |
| `Esc` / `P` | Tạm dừng |
| `Enter` | Xác nhận / chơi lại từ màn kết quả |

Đom đóm được nhặt tự động khi đi đủ gần (1.0 m theo mặt phẳng, chênh cao ≤ 1.5 m), không cần phím. Sức chứa bắt đầu ở 10, mỗi lần thắp thành công +2, tối đa 20 (HUD hiện số ô).

Đèn: thanh dầu trên đỉnh đèn; dầu < 30 thì đèn nhấp nháy chậm và mất vùng an toàn; đèn tắt bị xẹp và có vết rách. Cài đặt có mục "Bảng màu dễ phân biệt" (Bóng Mực xanh #00B3FF, cảnh báo trắng kèm ⚠), được lưu lại.

## Điểm số

Lấy từ `godot/src/core/game_config.gd` (contract v1.2, TICKET-03 mục 5):

- Mỗi đom đóm **nạp** vào đèn (thắp mới, thắp lại, châm dầu): **+5**. Nhặt không có điểm.
- Thắp lần đầu: **+100**. Thắp lại đèn đã tắt: **+40**.
- Mỗi Bóng Mực trúng Tỏa Sáng: **+5**, hoặc **+15** nếu nó đang hút dầu (`drain`).
- Chỉ khi thắng, ở bình minh: mỗi đèn đang sáng **+50 + floor(dầu)**, mỗi Ngọn Lửa còn lại **+50**. Không còn thưởng theo thời gian.

Đêm dài 240 / 270 / 300 giây (Đêm 1 / 2 / 3). Thắp đủ đèn **không** kết thúc Đêm. Ở bình minh: còn Ngọn Lửa và số đèn đang sáng ≥ ceil(0,6 × tổng đèn) (3/5, 4/6, 5/7) thì thắng (`dawn_survived`), không thì thua (`dawn`). Hết Ngọn Lửa luôn thua ngay (`no_flames`), kể cả ở tick bình minh.

## Chạy test

```bash
GODOT --headless --path godot --script res://tests/run_core_tests.gd
```

Trên Windows (cmd): `"%GODOT%" --headless --path godot --script res://tests/run_core_tests.gd`. Runner thoát với mã khác 0 khi có test fail.

Kịch bản có đáp án tính tay (18 bộ, `tests/scenarios/`): `sh scripts/run_scenarios.sh` (cần `GODOT`, `PYTHON`; trên Windows chạy qua Git Bash).

Kiểm tra tất định (chạy mỗi tổ hợp hai lần, so từng byte): `bash scripts/verify_determinism.sh`. Log thật ở `docs/evidence/phase-1/determinism/run.txt`.

Kịch bản Phase 2 (39 bộ): `sh scripts/run_scenarios_p2.sh`. Kịch bản Phase 3 / contract v1.2 (17 bộ, `tests/scenarios/p3/`): `sh scripts/run_scenarios_p3.sh`.

Kết quả lần chạy gần nhất (2026-11-21, Windows 11, Godot 4.7.2, log ở `docs/evidence/phase-3/`): test lõi `checks=3178 failures=0`; kịch bản P1 `passed=18 failed=0`, P2 `passed=39 failed=0`, P3 `passed=17 failed=0`; tất định 7/7 tổ hợp giống hệt. Chưa chạy trên macOS/Linux; CI có workflow nhưng chưa xác nhận chạy xanh.

## Chế độ headless

```bash
scripts/headless.sh --seed N --night 1 [--scenario F] [--inputs F] --ticks N --out F [--snapshot-every 10]
```

- Mô phỏng 60 tick mỗi giây, không cửa sổ, không GPU. Dừng khi đủ `--ticks` hoặc game đã kết thúc. Thoát với mã 0.
- Tham số sai hoặc file `--inputs` / `--scenario` sai định dạng: thoát với mã **2** và in lỗi ra stderr.
- Output là JSONL. Dòng `snapshot` ở tick 0 (sau scenario, trước input) và sau mỗi N tick. Dòng `event` gồm `mote_picked`, `deposit`, `lantern_lit`, `pulse`, `player_hit`, `shade_spawned`, `game_over`, với `tick = k+1`. Dòng `end` luôn là dòng cuối. Tọa độ làm tròn 3 chữ số.
- Input là `frames[]` có `tick` tăng nghiêm ngặt. `move [x,z]` được chuẩn hóa nếu dài hơn 1 và xoay theo `cam_yaw_deg`. `jump`, `interact`, `pulse` kích theo cạnh lên.
- Cùng seed, scenario và inputs thì output phải giống hệt từng byte (yêu cầu của Test Contract). Đã kiểm tra bằng `scripts/verify_determinism.sh` (xem mục Chạy test).

Tuning khai báo trong `game.contract.json` khớp với `game_config.gd` (có test đối chiếu trong `test_config`).

## Giải thích giá trị `null` / `false` trong tuning

- `fall_enabled: false`: Phase 1 không có chuyện rơi xuống đất làm mất máu. Vì vậy không có event `player_hit` với `by: "fall"`. Cờ này được khai báo để đúng schema contract, không phải một tính năng bị tắt.
- Không có giá trị `null` nào trong tuning hiện tại.

## Cấu trúc thư mục

- `godot/src/core/`: luật chơi thuần (RefCounted, không dùng Node, Input hay scene tree).
- `godot/src/adapters/headless/`: CLI và codec JSONL.
- `godot/src/adapters/view/` và `godot/scenes/`: hiển thị, chỉ đọc state.
- `scripts/`: wrapper gọi Godot headless.
- `game.contract.json`: tuning theo Test Contract v1.0. Bản nháp cũ ở `docs/notes/game.contract.draft.json`.
- `docs/`: kế hoạch (`TASKS.md`), giả định (`assumptions.md`), nhật ký dùng AI (`ai-log.md`), `LAB_README.md` là README gốc của lab.
- `CREDITS.md`, `LICENSE` (MIT), `CHANGELOG.md`, `Dockerfile`.
- Scaffold Node/Vite ở gốc repo (`package.json`, `src/`, `index.html`) là môi trường CP0, không liên quan đến game Godot.

## Docker (chưa kiểm chứng)

```bash
docker build -t dao-den-long .
docker run --rm -v "$PWD/out:/app/out" dao-den-long --seed 1 --night 1 --ticks 600 --out /app/out/out.jsonl
```

Dockerfile chưa được build hay chạy thử. Máy phát triển không có Docker.

## Sáng tạo của tôi

- Ánh sáng môi trường của đảo ấm dần khi số Đèn Lồng được thắp tăng lên. Đây chỉ là hiệu ứng hiển thị trong `godot/src/adapters/view/`, không ảnh hưởng output headless.
  - Hiện trạng: `game_view.gd` nội suy màu ánh sáng môi trường và sương từ tím lạnh sang cam ấm theo số đèn đã thắp (B8).
  - Bằng chứng: ảnh `evidence/screenshots/b8_game_view.png` và `d1_gameplay.png` (một đèn sáng). **Chưa có ảnh so sánh trước/sau**.

## Giới hạn đã biết

Phase 3:
- Chưa có file `TEST_CONTRACT_v1.2.md` gốc. Tên khóa `score` trong `game.contract.json`, thứ tự khóa snapshot mới và nhịp `fuel_drain` (đếm theo từng Bóng Mực) là giả định (`docs/assumptions.md` mục Phase 3).
- Hiệu năng: Đêm 3 (18000 tick) mất 17,1 s ở lần chạy cuối, nhưng các lần trước trên cùng laptop chạy pin mất 30,8–31,6 s, vượt ngưỡng 30 s. Bản `phase-2` đo cùng lúc cũng chậm tương tự.
- Chưa chơi thử bằng tay luật dầu đèn, chế độ mù màu và nhấp nháy 1 Hz; mới có test logic và ảnh chụp demo tự động.

Từ các phase trước:

- `scripts/headless.sh` đổi đường dẫn tương đối của `--scenario/--inputs/--out` thành tuyệt đối (theo thư mục gọi). `scripts/headless.cmd` chưa làm điều này: trên Windows hãy dùng đường dẫn tuyệt đối với bản `.cmd`.
- Scenario có `random_motes:true` kèm `motes:[]` (hoặc `random_shades:true` kèm `shades:[]`) vẫn sinh ngẫu nhiên lúc đầu, trái với cách đọc "mảng rỗng = không có con nào" của contract mục D. Chưa sửa; chỉ ảnh hưởng khi test ghép đúng hai trường này.
- `--night` ngoài 1 được chấp nhận mà không báo lỗi.
- Chưa có người chơi thử bằng phím/chuột thật; hướng đi theo camera, nhảy, pulse và nút Replay trong GUI chưa xác minh bằng tay. Bot demo chưa tự thắng; thắng mới được thử bằng cách đặt sẵn đèn sáng (trong kịch bản headless s10 thì thắng đúng).
- Đo 18000 tick: kịch bản không Bóng Mực chạy đủ 18000 tick (kết thúc `dawn`) trong khoảng 2,5 giây trên máy phát triển.
- Chưa đối chiếu độc lập (E1) với checklist mục F của Test Contract.
- Chưa kiểm tra headless trên macOS hoặc Linux. Tính tất định chỉ được đảm bảo trên cùng máy và cùng build, vì sin/cos có thể lệch ở chữ số cuối giữa các nền tảng.
- Dockerfile chưa được build hay chạy.
- Tuning là giá trị tạm (provisional), chưa được Product Owner duyệt.
- Render Forward+ bị crash trên Intel UHD 620 (driver); project dùng `gl_compatibility` và đã chụp ảnh thành công ở chế độ này.
- Chưa có tag `phase-1`, Release `v1.0.0`, hay video demo.
- Hiệu ứng "Sáng tạo của tôi" chưa có ảnh so sánh trước/sau.
- Diễn giải Test Contract nằm trong `docs/notes/test-contract-mapping.md`. Chưa đối chiếu lại toàn bộ với `contract/TEST_CONTRACT_v1.0.md` trong README này.

## Phase 2 — ba hòn đảo (tóm tắt)

- Ba Đêm: Đảo Bến (5 đèn), Đảo Cau (hai đảo nối cầu tre, hai bục nhảy, Gió Lạc, Bùa Gió, 6 đèn), Đảo Chuông (3 tầng, dốc, bục nhảy, tháp chuông, gió mạnh, 7 đèn). Menu → giới thiệu Đêm → chơi → kết quả → Đêm kế → màn Bình Minh. Âm thanh tổng hợp bằng code.
- Headless: `--night 1|2|3`; snapshot/scenario/event theo contract v1.1 (tên trường là **giả định** từ bản tóm tắt ticket, vì file contract v1.1 không có trong repo).
- Chạy kiểm tra: `sh scripts/run_scenarios_p2.sh` (39 bộ), `sh scripts/run_scenarios.sh` (18 bộ Phase 1), `bash scripts/verify_determinism.sh`.
- Kết quả lần chạy gần nhất (Windows, Godot 4.7.2): test lõi `checks=3055 failures=0`; kịch bản Phase 2 `passed=39 failed=0`; Phase 1 `passed=18 failed=0`; tất định 7/7; Đêm 3 đủ 21600 tick chạy khoảng 21,7 giây (mục tiêu ≤ 30 giây) và hai lần chạy giống hệt. Log ở `docs/evidence/phase-2/`.
- Điểm đom đóm cộng **khi nhặt** (giữ như Phase 1). Góc bản đồ dùng `z = r·sin(a)` theo tọa độ ticket.
- Chưa xác minh: chơi bằng phím/chuột thật, nghe âm thanh, hiệu ứng gió/Gió Lạc/bùa/lướt trên màn hình, CI GitHub, Docker, macOS/Linux. FPS trung bình đo khoảng 57 ở 1280×720 trên Intel UHD 620 (có thể bị vsync giới hạn).
- Điểm xuất phát Đêm 3 là (0,0,0), trùng đĩa tầng 2 và tháp chuông (xem `docs/notes/requests.md` R11).
