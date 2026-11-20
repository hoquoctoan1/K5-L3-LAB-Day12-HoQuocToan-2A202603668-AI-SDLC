# MAPS (P2-B1)

Files: `maps/map_builder.gd` (`MapBuilder.build(night)`), `maps/map_geometry.gd` (static queries).
Use `const MapBuilder = preload("res://src/core/maps/map_builder.gd")` (no class_name).
All data pure/deterministic, no randomness. Units meters, Y up.

## Angle convention (ASSUMPTION, forced by ticket data)
`x = cx + r*cos(a)`, `z = cz + r*sin(a)`, a in degrees from +X.
Justification: the ticket says tier1 is the half z>0 and its mote ring is 20..160 deg; ramps at 30/150 and the jump pad (0,3,13) are on tier1, so sin(a)>0 must give z>0. This is counter-clockwise in a math XZ plot (X right, Z up); seen from above with Y up and Z toward the viewer it appears clockwise. The ticket wording "CCW seen from above" is ambiguous/inconsistent with that; the data wins. Lantern coords are literal from the ticket (night1 L1..L5 sit at 90, 18, -54, -126, 162 deg under this formula, 72 deg apart). Night3 shade ring start angle is not given: ASSUMPTION start 0.

## MapData keys
- `night:int`, `name:String`, `void_y:float` (-10)
- `islands:Array[{id:String, center:Vector3, radius:float}]` (night2: "A","B")
- `tiers:Array[{tier:int, y:float, kind:"island"|"annulus"|"disc", r_min, r_max, z_positive_only}]` (kind island has no r_*; tier0 = whole island at y0)
- `ramps:Array[{angle_deg, width, foot_r, foot_y, top_r, top_y, dir:Vector3}]` (night3: 30, 150; foot r30 y0 -> top r24 y3, linear)
- `bridge:Dictionary` ({} if none; night2 `{x_min:26,x_max:44,z_half:2,y:0,railing:false}`)
- `jump_pads:Array[{pos, radius, launch_vy, launch_horizontal, direction:Vector3 (unit, XZ), lands_on:String}]`
- `bell_tower:Dictionary` ({} if none; `{center:(0,6,0) base, radius:2, height:8, climbable:false}`; occupies y 6..14)
- `start:{pos:Vector3, facing:Vector3(0,0,1)}`
- `lanterns:Array[{id:"L1".., pos:Vector3}]` (5/6/7)
- `mote_points:Array[Vector3]` (24/24/30, y = surface height)
- `shade_spawn_points:Array[Vector3]` (12/16/16; night2 island A points first, then B)
- `charm_positions:Array[Vector3]`

## Queries (MapGeometry static)
- `ground_height(map,x,z,y_hint=INF)->float|NAN`: highest surface at (x,z) with height <= y_hint+0.5 (STEP_UP). NAN = void. Tier edges are walls: stepping off tier1 at y3 yields tier0 height 0 (fall). Bridge has no railing: |z|>2 outside islands = NAN. Pass feet y as y_hint.
- `is_walkable(map,pos)`: ground exists and pos not inside bell tower.
- `inside_island(map,pos)`, `closest_island_index(map,pos,only_inside=false)` (XZ; -1 if none)
- `blocked_by_obstacle(map,from,to)->bool`: 3D segment vs bell-tower cylinder (XZ circle, Y in [6,14]); `blocked_at(map,pos)`.
- `jump_pad_at(map,pos)->int`: pad index or -1 (XZ<=radius, |dy|<=1.0 ASSUMPTION).
- `free_mote_points(map,motes)->Array[int]`: indices of mote_points not occupied (motes = Vector3 or {pos}; XZ<0.05, |dy|<0.5).
- `facing_start(map)->Vector3`.

## Assumptions
- Night2 pad direction is the horizontal unit vector from pad toward the target island center. Night2 pads/bridge/mote points at y0.
- Tier2 under the bell tower is walkable surface in ground_height; tower blocking is separate.
- Ramp surface only counts within its rectangle (|side|<=1.5, 24<=along<=30); its top at r24 meets the tier1 outer edge (y3).
