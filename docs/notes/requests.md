# Yeu cau / xung dot can quyet dinh (A0-P2)

| # | Xung dot | Hien trang | De xuat / owner |
|---|---|---|---|
| R1 | Diem `per_mote`: ticket cong khi NAP (P6), Phase 1 cong khi NHAT (`mote_system.gd`) | Giu hanh vi Phase 1 (test + s02/s10 van cong khi nhat) | B3 bo cong diem o nhat; B4 cong `amount*SCORE_PER_MOTE` o `deposit`; sua s02 (score 0), s10 (100+100+150+198 = 548) |
| R2 | Pickup ticket co dy<=1.5; `mote_system.gd` bo qua Y | Chua sua (gameplay) | B3 |
| R3 | `FALL_ENABLED=true` (gia dinh) nhung `player_system.gd` van kep trong dao | Chua sua | B2 |
| R4 | Shade dau: ticket 2 con tai tick 300; Phase 1 sinh 3 con luc begin + 1 con / interval | `INITIAL_SHADES=0`, interval 8 s (1 con/lan) | B5 (`SHADE_FIRST_SPAWN_*`) |
| R5 | Phase 1 dung `invuln_left`/`pulse_cd_left`/`stun_left` (giay float) song song truong tick v2 | Ca hai ton tai; v2 chua he thong nao cap nhat | Moi owner chuyen sang truong tick va xoa legacy; B8 doi snapshot |
| R6 | Shade Phase 1 sinh quanh `ISLAND_RADIUS-1..-5` (ticket: vong 37 m, 12 diem) | Chua sua | B1/B5 |
| R7 | Test Contract v1.1 goc chua co trong repo | Ten truong lay tu tom tat ticket (ASSUMPTION trong interfaces_v2.md) | Product Owner cung cap file |
| R8 | `input_decoder.gd`, `scenario_loader.gd`, `contract_codec.gd`, `headless_runner.gd` chua ho tro dash/pause, truong v2, `--night` > 1 | Khong sua o A0 (thuoc B8) | B8 |

## P2-C1 (Sim 12 buoc + lifecycle v2)
| # | Xung dot | Hien trang | De xuat / owner |
|---|---|---|---|
| R1+ | Product Owner CHOT: `per_mote` cong luc NHAT (giu `mote_system.gd`) | Da ap dung; lifecycle khong cong per_mote | Dong R1 (khong can B3/B4 sua) |
| R9 | Vung an toan bi xu ly 2 lan: `lantern_system._safe_zone` (buoc 6) VA `shade_system._update` deu day shade ra + giam `safe_push_ticks` (=> giam 2 lan/tick, day 2 lan) | `sim.gd` chi goi `LanternSystem._interact` (ham "private") o buoc 5; buoc 6 do ShadeSystem lam (sau di chuyen, truoc hit) | B4/B5 chon 1 owner; B4 nen co ham public `interact()` de sim khong goi `_interact` |
| R10 | `tests/scenarios/check.py` (Phase 1) so sanh danh sach event chinh xac; Sim v1.1 phat `night_start{night}` tai tick 1 => 16/18 kich ban FAIL chi vi event nay | Da kiem: loc dong `night_start` thi 17/17 kich ban co output deu PASS check.py (s18 PASS exit 2) | P2-C2/A0: check.py bo qua `night_start` (hoac them `(1,'night_start')`); PO xac nhan test an Phase 1 co chap nhan event moi khong |
| R11 | Dem 3: `start.pos` = (0,0,0) nam DUOI dia tang 2 (y=6, r=8) va thap chuong; May bat dau o y=0 "trong long nui" | Chua sua (khong thuoc C1) | B1 chon diem xuat phat Dem 3 (ticket khong ghi) |
| R12 | `charm_ticks` cua May: PlayerSystem da giam o buoc 2; `CharmSystem.decrement_player_charm` neu goi them se giam 2 lan | Sim KHONG goi `decrement_player_charm` | B6: xoa ham hoac ghi chu "khong dung" |
| R13 | Scenario `charms: []` khong tat duoc charm mac dinh (loader dat `[]` = giong khong co khoa; `Sim.begin` -> `CharmSystem.init_charms` nap tu map khi rong) | Chua sua | B8: khi scenario co khoa `charms`, loader dat `state.extras["charms_init"] = true` |
| R14 | DrifterSystem gop di chuyen + cuop + sinh (8/9/10) trong 1 step | Sim goi DrifterSystem TRUOC ShadeSystem => cuop truoc hit (dung ticket); sinh drifter truoc sinh shade/mote (khong anh huong vi rng/stream rieng) | Thong tin |

| R-C2-1 | (P2-C2, possible bug) scenario `"charms": []` does NOT replace the default charms: `CharmSystem.init_charms` refills from the map when `state.charms` is empty (contract: `arrays_replace_defaults`). Night 2 shows C1 at tick 0 | Failing set `n04_charms_replace` (hand-derived expectation kept) | sim/charm owner: track "scenario supplied charms" flag (e.g. extras["charms_init"]=true in loader) |
| R-C2-2 | (P2-C2, note) `no_flames beats win` cannot be produced by a shade hit in the same tick as lantern lighting: lighting creates a 6 m safe zone around the player so the shade does not hit; set `v03` uses a fall instead | Behaviour matches ticket | none |
