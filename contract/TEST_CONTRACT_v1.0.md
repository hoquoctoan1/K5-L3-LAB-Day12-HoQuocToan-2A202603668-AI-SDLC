# ĐẢO ĐÈN LỒNG — TEST CONTRACT v1.0

**Trạng thái:** Đặc tả chính thức do người dùng cung cấp trong đề bài (phần “Test Contract v1.0”).  
**Phạm vi:** Phase 1 — Đêm 1: Đảo Bến.  
**Mục đích:** Chuẩn chung để thực thi và chấm game ở chế độ headless, không phụ thuộc công nghệ.

> **Phân biệt hai file:** Tài liệu này (`TEST_CONTRACT_v1.0.md`) ghi **yêu cầu kỹ thuật**. File `game.contract.json` đặt ở **gốc repository** là **cấu hình của game được triển khai**, với giá trị `tuning` phải khớp **code chạy thực tế**. Không được dùng dữ liệu ước đoán chỉ để vượt kiểm thử.

## I. Yêu cầu sản phẩm liên quan

- Game 3D **Đảo Đèn Lồng**; nhân vật **Mây**, đội nón lá có treo đèn lồng nhỏ.
- Màn duy nhất: **Đêm 1 – Đảo Bến**, đảo tròn có **5 Đèn Lồng Lớn**.
- Di chuyển, nhảy, camera 3D; thu thập đom đóm; nạp ánh sáng để thắp đèn.
- **Bóng Mực** đuổi theo Mây; chạm vào làm mất máu; Mây tỏa sáng để xua chúng, có chi phí ánh sáng; Bóng Mực sợ đèn.
- Thắp hết 5 đèn → **thắng**; hết máu → **thua**. Có điểm số, HUD, chơi lại.
- Phong cách đêm cổ tích ấm áp; vàng cam là tốt, tím đen là nguy hiểm; đảo sáng dần khi thắp đèn; không máu me.
- Được sáng tạo thêm **chỉ khi** không thay đổi hành vi/output headless theo contract. Nêu mục **“Sáng tạo của tôi”** và bằng chứng trong `README.md`. Ưu tiên lõi đúng trước.
- Game chạy được trên laptop **macOS hoặc Linux**. Nếu phát triển ở Windows, phải có cách chạy cho giảng viên trên macOS/Linux (ví dụ Docker hoặc bản web).
- Nộp repository **public** có git tag **`phase-1`**; game chơi được từ đầu đến thắng/thua; `README.md` nêu cách cài/chạy tối đa **3 lệnh**, điều khiển và cách tính điểm; có bằng chứng, giả định/nhật ký dùng AI; nộp AI harness (`AGENTS.md` hoặc tương đương).

---

## A. File `game.contract.json` ở gốc repo

Đúng các khóa chính sau:

```json
{
  "contract_version": "1.0",
  "team": "mssv-ho-ten",
  "build_cmd": "lệnh cài đặt/biên dịch",
  "run_cmd": "lệnh mở game có giao diện",
  "headless_cmd": "lệnh chạy headless (sẽ được nối thêm tham số)",
  "tuning": {
    "player_speed": 0,
    "carry_capacity": 0,
    "lantern_cost": 0,
    "lantern_count_night1": 5,
    "pickup_radius": 0,
    "interact_radius": 0,
    "pulse_cost": 0,
    "pulse_radius": 0,
    "night1_duration_s": 0,
    "flames": 0,
    "invuln_s": 0,
    "hit_drop_ratio": 0,
    "pulse_stun_s": 0,
    "pulse_push_m": 0,
    "pulse_cooldown_s": 0,
    "safe_radius": 0,
    "shade_speed": 0,
    "shade_hit_radius": 0,
    "fall_enabled": false,
    "score": {
      "per_mote": 0,
      "per_lantern": 0,
      "per_stun": 0,
      "per_second_left": 0,
      "per_flame_left": 0
    }
  }
}
```

- `tuning`: điền **đúng giá trị đang dùng trong game**. Nếu game không có khái niệm nào đó, điền `null` (hoặc `false`) **và giải thích trong README**. Test Phase 1 dựa trên các giá trị này; khai sai sẽ trượt test.
- `hit_drop_ratio`: tỉ lệ đom đóm đánh rơi khi bị chạm (`0` nếu không rơi).
- `safe_radius`: bán kính vùng quanh đèn mà Bóng Mực không vào được.
- `fall_enabled`: rơi khỏi đảo có bị phạt hay không.
- `score.*`: số điểm tương ứng với từng loại sự kiện.
- Các lệnh `build_cmd`, `run_cmd`, `headless_cmd` **phải chạy trên macOS/Linux sau `build_cmd`**. Docker được phép.

**Chú ý:** Các giá trị `0` trong khung trên là **vị trí điền mẫu**, không có nghĩa game phải dùng bằng 0.

---

## B. Giao diện lệnh headless

```text
<headless_cmd> --seed <int> --night 1 [--scenario <file.json>] [--inputs <file.json>]
               --ticks <int> --out <file.jsonl> [--snapshot-every <int, mặc định 10>]
```

### B1. Thực thi, thời gian, lỗi

- Chạy logic ở **60 tick/giây cố định** (`1 tick = 1/60 s`), không cần cửa sổ hay GPU, nhanh nhất có thể.
- Dừng khi đã chạy đủ `--ticks` **hoặc** khi game kết thúc (thắng/thua). Thành công có **exit code 0**.
- Lỗi: **exit code khác 0**, thông báo lỗi ghi vào **stderr**.
- File `--inputs` hoặc `--scenario` sai định dạng: **exit code 2**.
- Đơn vị khoảng cách: **mét**; trục **Y hướng lên**; mặt đất của đảo ở **Y = 0**; người chơi xuất phát ở **(0, 0, 0)**.

### B2. Quy ước tick (bắt buộc)

- Snapshot **tick 0** là trạng thái **sau khi dựng scenario, trước khi áp dụng bất cứ input nào**.
- Bước `k` (với `k = 0 ... N−1`) đọc input tick `k` rồi cập nhật sang trạng thái `k+1`.
- Sự kiện phát sinh trong bước đó có `tick = k+1`.
- `--ticks N` nghĩa là thực hiện **đúng N bước** (trừ khi game kết thúc sớm).
- `time_left_s = night_duration_s − (số bước đã chạy) / 60` (nếu scenario đặt thời gian còn lại thì trạng thái khởi đầu dùng giá trị scenario theo cơ chế override).

### B3. Quy ước vị trí và khoảng cách

- `player.pos`: **vị trí chân** nhân vật.
- `shade.pos`: **tâm** Bóng Mực.
- `lantern.pos`: **chân cột đèn**.
- `mote.pos`: điểm trên **mặt đất**; độ cao bay của đom đóm chỉ là hiển thị.
- Tất cả khoảng cách bán kính `tuning` dùng **mặt phẳng ngang XZ**, không tính kích thước nhân vật.
- “Trong bán kính r” nghĩa là **khoảng cách ≤ r** (bao gồm biên).

---

## C. File inputs

Ví dụ:

```json
{
  "frames": [
    { "tick": 0, "move": [0, 1], "cam_yaw_deg": 0 },
    { "tick": 120, "move": [0, 0], "interact": true },
    { "tick": 121, "interact": false },
    { "tick": 200, "pulse": true },
    { "tick": 201, "pulse": false }
  ]
}
```

### C1. Trạng thái input

- Trước frame đầu tiên: `move = [0,0]`, `cam_yaw_deg = 0`, tất cả nút `false`.
- Mỗi frame **chỉ cập nhật các trường có mặt**; trường không xuất hiện **giữ nguyên giá trị trước đó**.
- `tick` trong `frames` phải **tăng nghiêm ngặt** (không trùng, không giảm).
- Nếu **không có file inputs**, người chơi đứng yên.

### C2. Di chuyển

- `move = [x, z]` với từng thành phần thuộc `[-1, 1]`.
- Đổi `cam_yaw_deg` sang góc radian `θ`.
- Công thức hướng trong thế giới:

```text
x' = x*cos(θ) + z*sin(θ)
z' = -x*sin(θ) + z*cos(θ)
```

- Khi `θ = 0`, `x` tương ứng +X, `z` tương ứng +Z.
- Vector di chuyển có độ dài > 1 phải **chuẩn hóa về độ dài 1**.

### C3. Nút kích hoạt theo cạnh lên

- `jump`, `interact`, `pulse` và `dash` (nếu có) là boolean.
- Một hành động chỉ kích hoạt khi nút **chuyển từ `false` sang `true`**.
- Giữ `true` nhiều tick liên tiếp không được tính là nhấn mới.

---

## D. File scenario

Ví dụ:

```json
{
  "player": { "pos": [0, 0, 0], "carried": 0, "flames": 3 },
  "random_motes": false,
  "random_shades": false,
  "motes": [[0, 0, 5]],
  "shades": [{ "pos": [10, 0, 0] }],
  "lanterns": [{ "id": "L1", "pos": [0, 0, 25], "deposited": 0 }],
  "time_left_s": 300
}
```

### D1. Quy tắc dựng scenario

- `random_motes: false`: không tự sinh đom đóm, chỉ dùng những con trong danh sách chỉ định.
- `random_shades: false`: không tự sinh Bóng Mực, chỉ dùng những con trong danh sách chỉ định; các Bóng Mực đó **hoạt động bình thường ngay lập tức**.
- `lanterns`: **cập nhật theo `id`** cho các đèn cố định `L1`…`L5`. Đèn không được đề cập giữ nguyên. Có `pos` thì đổi vị trí; có thể đặt `lit: true`.
- `motes`, `shades`: khi cung cấp thì **thay thế** danh sách ban đầu tương ứng; `[]` nghĩa là không có con nào.
- Các phần tử `shades[]` có thể có `id` để test tham chiếu.
- Trường bị bỏ qua: dùng **mặc định của game**.
- Dựng scenario **không sinh event và không cộng điểm**. Ví dụ đặt đèn `lit: true` sẵn không được cộng điểm thắp đèn.

---

## E. Đầu ra JSONL

- Output có định dạng **JSON Lines (`.jsonl`)**, **mỗi dòng là một object JSON độc lập**.
- Có ba loại dòng: **snapshot**, **event**, **end**.

### E1. Snapshot

Ghi mỗi `--snapshot-every` tick, bắt đầu **tick 0**; mặc định `--snapshot-every = 10`.

Ví dụ:

```json
{"type":"snapshot","tick":120,"sim_tick":120,"state":"playing","time_left_s":298.0,"score":20,"player":{"pos":[0.0,0.0,12.0],"flames":3,"carried":2},"lanterns":[{"id":"L1","pos":[0,0,25],"lit":false,"deposited":0}],"shades":[{"id":"S1","pos":[30.1,1.0,2.0],"state":"chase"}],"motes_active":19}
```

- `state` thuộc: `playing`, `won`, `lost`.
- `sim_tick` là số bước gameplay đã chạy, ở Phase 1 bằng `tick`.
- Tọa độ được **làm tròn 3 chữ số thập phân**.
- Mảng `motes` với phần tử `{ "id": ..., "pos": ... }` trong snapshot **được khuyến nghị** (không bắt buộc ở v1.0).

### E2. Event

Ghi **ngay khi sự kiện xảy ra**. Ví dụ:

```json
{"type":"event","tick":131,"name":"mote_picked","data":{"carried":3}}
```

| `name` | `data` bắt buộc khi event đó xảy ra |
|---|---|
| `mote_picked` | `{"carried": n}` |
| `deposit` | `{"lantern_id": "L1", "amount": n, "deposited": n}` |
| `lantern_lit` | `{"lantern_id": "L1"}` |
| `pulse` | `{"stunned_ids": ["S1"]}` |
| `player_hit` | `{"by": "shade" \| "fall", "flames": n, "dropped": n}` |
| `shade_spawned` | `{"id": "S3"}` |
| `game_over` | `{"result": "won" \| "lost", "reason": "all_lit" \| "dawn" \| "no_flames"}` |

- Trạng thái Bóng Mực tối thiểu có `stunned`; các trạng thái khác do người triển khai tự đặt tên.
- Nếu một loại sự kiện không thể xảy ra trong game (ví dụ không có rơi khỏi đảo), thì **không ghi sự kiện đó**.

### E3. End

**Dòng cuối cùng bắt buộc**:

```json
{"type":"end","ticks":4800,"state":"won","score":1730}
```

### E4. Tính tất định

- Cùng `--seed`, cùng `--scenario`, cùng `--inputs` → **toàn bộ output giống hệt nhau giữa hai lần chạy**, kể cả `id` được tự sinh.
- Không yêu cầu các nhóm dùng cùng chuỗi random, nhưng từng nhóm phải tái hiện được chính kết quả của mình.
- Thực thể/tính năng sáng tạo không được làm thay đổi output của bộ test headless.

---

## F. Checklist triển khai cho AI Agent (diễn giải để tránh bỏ sót; không thay đổi v1.0)

- [ ] Repo root có `game.contract.json` chứa đủ khóa A, `contract_version` là `"1.0"`.
- [ ] `team`, `build_cmd`, `run_cmd`, `headless_cmd` có giá trị **thực tế**.
- [ ] **Mỗi trường `tuning` khớp với code game**, kể cả `score.*`; các `null`/`false` được giải thích trong README.
- [ ] Có lệnh build + chạy UI trên macOS/Linux; hướng dẫn tối đa ba lệnh trong README.
- [ ] Chạy headless với đủ tham số B; không cần cửa sổ, GPU.
- [ ] Vòng lặp fixed 60 Hz; tích lũy vị trí/thời gian theo đúng `1/60` giây.
- [ ] Snapshot tick 0 trước input, sự kiện tại tick k+1, `--ticks N` tối đa N bước.
- [ ] Đọc inputs theo **stateful frames**; kiểm tra tick tăng; edge-trigger cho các nút.
- [ ] Dùng đúng phép xoay `cam_yaw_deg`, chuẩn hóa input chéo, khoảng cách ngang XZ và biên ≤.
- [ ] Scenario thay thế/cập nhật đúng danh sách, không tự phát event hoặc cộng điểm trong khởi tạo.
- [ ] JSONL có snapshot/event/end; end luôn cuối; mã thoát 0 / 2 / khác 0 đúng ngữ cảnh.
- [ ] Test chạy lặp lại cùng seed/scenario/inputs và so sánh **byte-for-byte**.
- [ ] Dùng kịch bản thắng, thua, đứng yên, nhặt đom đóm, deposit, pulse, bị đánh, scenario không có enemy/mote, tick biên.
- [ ] Bằng chứng thực chạy GUI và headless; công khai repo + tag `phase-1`.

## G. Những điều **chưa được định nghĩa** trong phần contract được gửi

Cần chốt với code/PRD và ghi trong README, không tự xem là nội dung giảng viên đã quy định:

- Số thực của `tuning` (tốc độ, bán kính, chi phí, thời lượng, cách chấm điểm...): do game định nghĩa, nhưng **khai báo phải khớp code**.
- Thứ tự nhiều event **cùng một tick** và cách tính thêm điểm khi xảy ra đồng thời: phải nhất quán, có test.
- Cách chọn đèn tương tác khi có nhiều đèn trong bán kính: xác định rõ và ổn định.
- Chi tiết triển khai hit, stun, cooldown, AI pathfinding, respawn và thắng-thua đồng thời: cần hành vi rõ, ổn định và tương thích với những quy tắc được nêu.
- Cách wrapper Godot nhận args: tham số `--seed`, `--night` ... phải thực sự được script/game phân tích; **Godot không tự cung cấp schema test này**.

**Ưu tiên:** Yêu cầu gốc v1.0 > giả định triển khai > phần sáng tạo. Không ghi một task đã đạt hợp đồng chấm tự động nếu chưa chạy lệnh headless với output thực và kiểm chứng kết quả.
