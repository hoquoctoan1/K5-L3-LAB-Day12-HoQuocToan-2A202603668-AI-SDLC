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
