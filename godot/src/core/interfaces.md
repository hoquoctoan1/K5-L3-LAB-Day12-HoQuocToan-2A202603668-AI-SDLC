# Giao diện core (đóng băng bởi A0)

- `GameConfig` (const, `DT = 1/60`), `Rng` (mulberry32: `next_u32/next_float/next_int`), `SimState` (xem `sim_state.gd`).
- Id: lantern `"L1".."L5"`, mote `"m<n>"` từ `next_mote_id`, shade `"S<n>"` từ `next_shade_id`; tăng sau mỗi lần sinh.
- Shade `state` tối thiểu: `"chase"`, `"stunned"` (có thể thêm `"wander"`). `stun_left` > 0 khi stunned.
- `FrameInput`: Dictionary `{move:Vector2, cam_yaw_deg:float, jump:bool, interact:bool, pulse:bool}`; jump/interact/pulse đã là cạnh lên; `move` đã xoay và chuẩn hóa.
- System: `static func step(state: SimState, input: Dictionary, events: Array) -> void`. Event: `{"name":String,"data":Dictionary}` (không có tick; Sim gắn `tick = steps+1`).
- Thứ tự trong `Sim.step`: player → mote(pick) → lantern(interact) → pulse → shade(move+hit) → spawn → lifecycle. `Sim` tăng `steps`/`tick` sau cùng.
- Core không `extends Node`, không dùng `Input`, `randf()`, thời gian thực. Chỉ `Rng` và `DT`.
- Tick `k`: input tick k → trạng thái k+1, event `tick = k+1`.
- Khi `status != "playing"` mọi system không làm gì (lifecycle đặt status, `loss_reason`).
- Mỗi system có `class_name` riêng (`PlayerSystem`, `MoteSystem`, `LanternSystem`, `PulseSystem`, `ShadeSystem`, `SpawnSystem`, `LifecycleSystem`); `InputDecoder` ở `src/core/input_decoder.gd`.
- Event data (khớp Test Contract mục E): `mote_picked{carried}`, `deposit{lantern_id,amount,deposited}`, `lantern_lit{lantern_id}`, `pulse{stunned_ids}`, `player_hit{by,flames,dropped}`, `shade_spawned{id}`, `game_over{result,reason}` (mục E2 của contract; không thêm trường khác).

## Quy ước bổ sung (A0, đã kiểm chứng)
- Cache `class_name` của Godot chỉ có GameConfig, Rng, SimState, TS. File MỚI không được dựa vào `class_name` của file mới khác: tham chiếu bằng `const X = preload("res://src/core/....gd")`. Không chạy `--import`/`--editor` (treo, tranh chấp giữa các agent).
- Test: mỗi `tests/**/test_*.gd` là `extends RefCounted` với `func run(t: TS) -> void` (KHÔNG static). Chạy: `GODOT --headless --path godot --script res://tests/run_core_tests.gd [-- --only <tên>]`.
- System là script có `static func step(state, input, events)`; gọi qua preload.
