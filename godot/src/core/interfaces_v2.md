# Giao dien core v2 (contract v1.1) - DONG BANG boi A0-P2

Nguon: `docs/notes/ticket-02.json` (tom tat JSON; file Test Contract v1.1 goc CHUA co trong repo). Moi ten truong danh dau **[ASSUMPTION]** la suy ra tu tom tat va phai doi chieu khi co file goc. Chi A0 sua `sim_state.gd`, `game_config.gd`, file nay. Giu quy uoc `interfaces.md` (system = `static func step(state, input, events)`, preload file moi, khong chay `--import`).

## 1. Don vi & thoi gian
- 60 tick/s, `GameConfig.DT = 1/60`; so tick nguyen la nguon su that (`GameConfig.*_TICKS`). Y huong len. Goc tu +X nguoc chieu kim dong ho nhin tu tren (mat phang XZ).
- `state.tick`: tang MOI `Sim.step`, ke ca khi `paused`. `state.steps` (= `state.sim_ticks`, alias) chi tang khi KHONG paused; thoi gian, hoi chieu, spawn, TTL dung yen khi paused. Event `tick` = `state.tick` sau khi tang.
- `time_left_s = time_left_initial - steps*DT`. `time_left_initial = GameConfig.night_duration_s(state.night)` (300/330/360 s; 18000/19800/21600 tick).

## 2. SimState (xem `sim_state.gd`)
Root: `night:int(1..3)`, `paused:bool`, `status playing|won|lost`, `loss_reason no_flames|dawn|""`, `score`, `map:Dictionary`, `map_height_fn:Callable`, co `random_motes/random_shades/random_drifters/wind_enabled`, id tiep theo `next_mote_id (m) next_shade_id (S) next_drifter_id (D) next_charm_id (C)`, `extras:Dictionary` (nhap tam, khong vao snapshot).
- **player**: `pos:V3, vel:V3, grounded:bool, facing:Vector2 (XZ, mac dinh +Z = (0,1)), flames:int, carried:int, invuln_ticks:int, dash_cd_ticks:int, dash_ticks_left:int, dash_dir:Vector2, pulse_cd_ticks:int, charm_ticks:int, fall_wait_ticks:int (>0 = dang cho hoi sinh: khong nhat, khong bi cham), launched:bool (bay do bục nhảy)`. **[ASSUMPTION]** ten `dash_dir`, `launched`, `facing`, `fall_wait_ticks`. LEGACY (Phase 1, xoa khi owner viet lai): `vy, on_ground, invuln_left (s), pulse_cd_left (s)`.
- **mote**: `{id "m<n>", pos, kind "random"|"dropped", ttl_ticks:int (-1 = vo han), point_index:int (-1 = khong co)}` (`SimState.make_mote`).
- **shade**: `{id "S<n>", pos, state "spawning|wander|chase|recoil|stunned", state_ticks_left:int, knock_dir:Vector2, knock_ticks_left:int, recoil_dir:Vector2, safe_push_ticks:int}` + LEGACY `stun_left (s)`. **[ASSUMPTION]** cac truong knock/recoil/safe_push (B5 co the dung `extras` neu can them).
- **lantern**: `{id "L<n>", pos, lit, deposited:int, safe_timer:int}` **[ASSUMPTION]** `safe_timer` (nghia do B4 chon; khong dung thi de 0).
- **drifter**: `{id "D<n>", pos, state "idle|chase|flee|removed", stolen:int, has_stolen:bool, flee_ticks_left:int, flee_dir:Vector2, drop_after_ticks:int}` **[ASSUMPTION]** cac truong ngoai id/pos/state/stolen.
- **charm**: `{id "C<n>", pos, available:bool, respawn_ticks:int}`.
- **wind**: `{active:bool, dir_deg:float, ticks_left:int, next_ticks:int, warn_ticks:int}` **[ASSUMPTION]** `ticks_left/next_ticks/warn_ticks`. Snapshot chi phat `active, dir_deg`.
- Bo dem lich: `shade_spawn_ticks_left, shade_first_spawned, shade_island_cursor, drifter_spawn_ticks_left, mote_respawn_ticks_left` (dem theo sim tick; dung khi paused).
- Helper: `SimState.make_default_player/make_mote/make_shade/make_drifter/make_charm/make_lantern/make_default_wind`, `seed_streams(seed)`, `height_at(x,z,from_y)`.

## 3. MapData (chi dinh nghia hinh dang; module `src/core/maps/*` do P2-B1 tao va gan vao `state.map`)
`Dictionary`:
```
{ name:String, night:int,
  islands:[{id:String, center:V3, radius:float}],
  tiers:[{tier:int, y:float, shape:Dictionary}],            # Dem 3; Dem 1,2: []
  ramps:[{angle_deg, width, foot_r, foot_y, top_r, top_y}], # Dem 3; else []
  bridge:{x_range:[a,b], z_range:[a,b]} | {},               # Dem 2
  jump_pads:[{pos:V3, radius, launch_vy, launch_horizontal, dir:Vector2 (XZ don vi)}],
  lantern_positions:[V3...], mote_points:[V3...], shade_spawn_points:[V3...],
  charm_positions:[V3...], start:{pos:V3, facing:Vector2}, bell_tower:{center, radius, height} | {} }
```
**[ASSUMPTION]** ten khoa cua `ramps`, `jump_pads.dir`, `bell_tower`; B1 duoc them khoa, KHONG doi/xoa khoa tren.
`height_at(x, z, from_y)`: `SimState.height_at` goi `map_height_fn(x,z,from_y)` neu hop le; map rong => dao tron ban kinh `GameConfig.island_radius(night)`, y=0. Tra y cua be mat CAO NHAT co y <= from_y + 0.5 tai (x,z) (doc/cau/tang noi suy); tra `SimState.VOID_Y` (-1e9) neu khong co be mat (ngoai dao => se roi). Tieu chi roi: `pos.y < GameConfig.FALL_Y`.

## 4. FrameInput v2
`{move:Vector2 (da xoay theo cam, |move|<=1), cam_yaw_deg:float, jump:bool, interact:bool, pulse:bool, dash:bool, pause:bool}`; cac nut la CANH LEN (false->true) do `InputDecoder` tinh. File inputs them `dash`, `pause` (bool) nhu `jump/interact/pulse`; `move` van la [x,z]. (B8 owner; `input_decoder.gd` chua cap nhat o A0.)

## 5. Event (data theo contract v1.1) `{"name","data"}`
Phase 1: `mote_picked{carried}`, `deposit{lantern_id,amount,deposited}`, `lantern_lit{lantern_id}`, `pulse{stunned_ids}`, `player_hit{by,flames,dropped}`, `shade_spawned{id}`, `game_over{result,reason}`.
Moi: `dash{}`, `charm_picked{charm_id,charm_ticks}`, `drifter_steal{drifter_id,amount,carried}`, `drifter_drop{drifter_id,amount}`, `night_start{night}`, `paused{}`, `resumed{}`. `player_hit` them `lost` (so mote mat) khi `by=="fall"` (`dropped` = 0 o truong hop do **[ASSUMPTION]**). `by` thuoc `shade|fall`.
Thu tu event trong tick: theo thu tu goi system (muc 8).

## 6. Snapshot v1.1 (dong JSONL `type:"snapshot"`)
`tick, sim_tick, state ("playing|won|lost|paused"), time_left_s, score, night, wind{active,dir_deg}, player{pos, vel, grounded, invuln (s), dash_cd_s, pulse_cd_s, charm_s, flames, carried}, lanterns[{id,pos,lit,deposited}], shades[{id,pos,state}], motes_active, motes[{id,pos,kind,ttl_s}], drifters[{id,pos,state,stolen}], charms[{id,available,respawn_s}]`. `x_s = x_ticks / 60`. `ttl_s` cua mote `random` = -1 **[ASSUMPTION]**. Thu tu key chinh xac la **[ASSUMPTION]** (codec giu co dinh de byte-on-dinh). Dong `end` giu `{"type":"end","ticks","state","score"}`.

## 7. Scenario v1.1 (them)
`player: invuln_ticks, dash_cd_ticks, pulse_cd_ticks, charm_ticks` (int>=0); `shades[]: state, state_ticks_left`; `drifters[]` va `charms[]` THAY THE mac dinh khi co mat (drifter: `id?,pos,state?,stolen?`; charm: `id?,pos,available?,respawn_ticks?`); co `random_drifters`, `wind_enabled` (bool). CLI: `--night 1|2|3`. `random_*=false` => dung danh sach scenario (nhu Phase 1). Tat ca la **[ASSUMPTION]** ve ten phu.

## 8. Thu tu tick (12 buoc ticket) -> file (owner theo TASKS_P2)
| # | Buoc | File | Owner |
|---|---|---|---|
| 1 | Doc input; pause xu ly truoc (vua pause thi dung tai day; `tick+=1`, `steps` khong tang) | `sim.gd` | B7/C1 |
| 2 | Giam bo dem: thoi gian, hoi chieu, bat tu, choang, bua, TTL mote roi, hoi bua | `sim.gd` goi ham timer cua tung system | B7 (phoi hop B2-B6) |
| 3 | Di chuyen May (nhay, luot, bục nhảy, gio) roi kiem tra roi dao | `player_system.gd`, `jump_pad_system.gd`, `wind_system.gd` | B2, B6 |
| 4 | Nhat mote va bua | `mote_system.gd`, `charm_system.gd` | B3, B6 |
| 5 | Tuong tac den | `lantern_system.gd` | B4 |
| 6 | Cap nhat vung an toan | `lantern_system.gd` (B4; shade doc ket qua) | B4 |
| 7 | Toa Sang | `pulse_system.gd` | B5 |
| 8 | Di chuyen Bong Muc va Gio Lac | `shade_system.gd`, `drifter_system.gd` | B5, B6 |
| 9 | Cham: Gio Lac cuop truoc, roi Bong Muc hit (id tang dan) | `drifter_system.gd`, `shade_system.gd` | B6, B5 |
| 10 | Sinh mote, Bong Muc, Gio Lac theo lich (the moi chi tuong tac tu tick sau) | `mote_system.gd`, `spawn_system.gd`, `drifter_system.gd` | B3, B5, B6 |
| 11 | Xet thang/thua (no_flames > all_lit > dawn) | `lifecycle_system.gd` | B7 |
| 12 | Ghi snapshot neu toi luot | `headless_runner.gd` + `contract_codec.gd` | B8 |

Hien tai `sim.gd` van chay thu tu Phase 1 cho toi khi B7/C1 ghep.

## 9. RNG
Mot `Rng` (mulberry32) seed tu `--seed`. `state.seed_streams(seed)` tao `state.rng` (chinh; Phase 1 con dung cho mote/shade cho toi khi B3/B5 doi), `rng_mote`, `rng_shade`, `rng_drifter`, `rng_wind` = `Rng(Rng(seed ^ SALT).next_u32())`, `SALT` trong `SimState.STREAM_SALTS` (mote 0x1001, shade 0x2002, drifter 0x3003, wind 0x4004). He thong moi PHAI dung stream rieng cua minh (khong `randf()`); can stream moi thi bao A0. Khong tieu thu rng khi paused.

## 10. Gia dinh chot (P3/P6)
- **P6**: diem `per_mote` (10) cong khi mote duoc NAP vao den (delivered), cung luc `deposit`. Phase 1 cong khi nhat: xung dot, xem `docs/notes/requests.md` R1. Bonus thang: `floor(giay con lai)*2 + 50*flames`.
- Pulse trung Gio Lac khong cong diem (chi Bong Muc +5 moi lan, ke ca dang choang).
- Mote Gio Lac tha: `kind "dropped"`, TTL 120 tick (`DRIFTER_DROPPED_MOTE_TTL_TICKS`); player bi hit tha: TTL 480; nhat duoc tu tick sau.
- Dem 2/3: 2 Bong Muc tai tick 300 roi theo interval rieng (480/420/360), `max_alive` chung ca ban do, luan phien dao (Dem 2), >=15 m tu nguoi choi moi Dem.
- `fall_enabled` = true trong contract v1.1 **[ASSUMPTION]** (Phase 1: false).
- Thang/thua sau moi tick: no_flames > all_lit (ke ca dung tick het gio) > dawn.

## 11. Contract v1.2 (A0-P3, TICKET-03 "Den can dau") - DONG BANG boi A0-P3
Nguon: `docs/notes/ticket-03.md`, ke hoach `docs/TASKS_P3.md` (Q1 = A da duoc Product Owner chot; Q2-Q9 theo de xuat).
**SimState them** (xem `sim_state.gd`):
- lantern: `fuel_units:int` (1 unit = 1/60 fuel; day = `FUEL_MAX_UNITS` 6000; den tat = 0), `ever_lit:bool`, `relit_count:int`.
- player: `successful_lights:int` (thap moi + thap lai trong Dem; den dat san bang scenario KHONG tinh; ve 0 dau Dem).
- shade: state them `drain`; `target_lantern_id:String` ("" = khong co), `drain_ticks:int` (dem tick hut lien tuc).
- helper: `SimState.capacity_of(player)` / `state.capacity()` = min(20, 10 + 2*successful_lights); `fuel_of(l)`, `is_low_fuel(l)` (sang va < 1800 units), `has_safe_zone(l)` (sang va >= 1800 units), `fuel_out(l)` (1 chu so thap phan, round half up, so nguyen).
**GameConfig them**: `FUEL_*`, `RELIGHT_COST`, `WIN_RATIO`, `DRAIN_*`, `LOW_FUEL_*`, `CAPACITY_MAX`, `CAPACITY_PER_LIGHT`, `FUEL_DRAIN_EVENT_EVERY_TICKS`, `win_threshold(n)` = ceil(0.6n); diem `SCORE_PER_MOTE` 5 (khi NAP), `SCORE_PER_RELIGHT` 40, `SCORE_PER_STUN_DRAIN` 15, `SCORE_PER_LIT_LANTERN_DAWN` 50; `SCORE_PER_SECOND_LEFT` = 0 (LEGACY, P3-B3 xoa). Dem 240/270/300 s.
**Thu tu tick v1.2** (bo sung muc 8):
- Buoc 2b (ngay sau buoc 2, `sim.gd` goi `LanternSystem.tick_fuel(state, events)` - P3-B1 viet, P3-B3 noi): moi den sang tru `FUEL_DECAY_UNITS_PER_TICK` + `FUEL_DRAIN_UNITS_PER_TICK` x (so shade state `drain` co `target_lantern_id` = den do); `fuel_drain{lantern_id,shade_id,fuel}` khi `drain_ticks % 60 == 0` (ShadeSystem tang `drain_ticks` o buoc 8, LanternSystem doc o buoc 2b cua tick sau) **[GIA DINH Q2]**; den `fuel_units <= 0` -> `lit=false, deposited=0, fuel_units=0`, event `lantern_out{lantern_id}`.
- Buoc 5: chon den "nhan duoc" (chua sang, hoac sang va `fuel_units < FUEL_MAX_UNITS`); thap moi `deposit` + `lantern_lit{lantern_id,relight:false}`; thap lai (ever_lit, can `RELIGHT_COST`) `deposit` + `lantern_lit{...,relight:true}`; cham dau `refuel{lantern_id,amount,fuel}` (khong phat `deposit`) **[GIA DINH Q3]**.
- Buoc 6/8: vung an toan chi tinh den `has_safe_zone`. Shade wander: nham den `is_low_fuel` gan nhat (hoa id nho), khong co thi den TAT gan nhat (Q1 = A), khong co nua thi di ngau nhien nhu v1.1. `drain` khi XZ <= `DRAIN_RANGE_M`.
- Buoc 11: `no_flames` > (het gio: lit >= `win_threshold` -> `won/dawn_survived`, else `lost/dawn`). Bo `all_lit`.
**Snapshot v1.2**: lantern `{id,pos,lit,deposited,fuel,ever_lit,relit_count}` (`fuel` 1 chu so thap phan); player them `capacity` (sau `carried`) **[GIA DINH thu tu khoa]**.
**Scenario v1.2**: lantern `lit, fuel (0..100), ever_lit` (`lit:true` thieu `fuel` -> 100; thieu `ever_lit` -> = `lit` **[GIA DINH Q5]**); player `successful_lights:int>=0`; shades[] `target_lantern_id`; state `drain` hop le.
