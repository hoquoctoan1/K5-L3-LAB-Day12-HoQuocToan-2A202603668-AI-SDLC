Video demo: (se bo sung o Phase 4)

# Đảo Đèn Lồng

Game 3D góc nhìn thứ ba làm bằng Godot 4.7 (GDScript). Bạn là người giữ đèn nhỏ tuổi trên một hòn đảo giữa sương đen. Gom đom đóm, mang về thắp đủ 5 Đèn Lồng Lớn trước khi trời sáng, và né hoặc làm choáng Bóng Mực đang đuổi theo. Thua khi hết máu (flames) hoặc hết đêm (dawn).

Trạng thái: **Phase 1, đang thực hiện.** Các mục chưa xác minh được ghi trong "Giới hạn đã biết".

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
| `E` | Nạp đom đóm đang mang vào Đèn Lồng gần nhất trong bán kính tương tác |
| `F` | Tỏa sáng (pulse): tốn đom đóm, làm choáng và đẩy lùi Bóng Mực trong bán kính |
| Chuột, `Q`, `R` | Xoay camera |
| `Enter` | Chơi lại (Replay) từ màn kết quả |

Đom đóm được nhặt tự động khi đi đủ gần (bán kính 1.2 m), không cần phím.

## Điểm số

Lấy từ `godot/src/core/game_config.gd`:

- Nhặt một đom đóm: **+10** (tính khi nhặt, không tính khi nạp).
- Thắp một Đèn Lồng: **+100**.
- Mỗi Bóng Mực bị pulse làm choáng: **+5** (kể cả Bóng Mực đang choáng bị choáng lại).
- Chỉ khi thắng: **+50** cho mỗi máu còn lại.
- Chỉ khi thắng: **+1** cho mỗi giây còn lại (làm tròn xuống theo giây).

Thắng khi thắp đủ 5 đèn. Thua khi hết máu (`no_flames`) hoặc hết 300 giây đêm (`dawn`). Nếu đèn thứ 5 sáng cùng tick với điều kiện thua thì tính là thắng.

## Chạy test

```bash
GODOT --headless --path godot --script res://tests/run_core_tests.gd
```

Trên Windows (cmd): `"%GODOT%" --headless --path godot --script res://tests/run_core_tests.gd`. Runner thoát với mã khác 0 khi có test fail.

Kịch bản có đáp án tính tay (18 bộ, `tests/scenarios/`): `sh scripts/run_scenarios.sh` (cần `GODOT`, `PYTHON`; trên Windows chạy qua Git Bash).

Kiểm tra tất định (chạy mỗi tổ hợp hai lần, so từng byte): `bash scripts/verify_determinism.sh`. Log thật ở `docs/evidence/phase-1/determinism/run.txt`.

Kết quả lần chạy gần nhất trên máy phát triển (Windows, Godot 4.7.2): bộ test lõi `checks=304 failures=0`; kịch bản `passed=18 failed=0`; tất định 7/7 tổ hợp giống hệt. Chưa chạy trên macOS/Linux hay CI.

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
