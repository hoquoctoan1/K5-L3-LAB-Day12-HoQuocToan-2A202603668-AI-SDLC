extends RefCounted
## Ham thuan cho HUD (khong node, khong SimState).

static func format_clock(sec: float) -> String:
	var s := int(ceil(maxf(sec, 0.0)))
	return "%02d:%02d" % [s / 60, s % 60]

static func clock_urgent(sec: float) -> bool:
	return sec <= 30.0

## Nhap nhay 2 Hz theo thoi gian t.
static func blink_on(t: float) -> bool:
	return fmod(t, 0.5) < 0.25

## Goc (rad, 0 = +X, chieu kim dong ho trong toa do man hinh) tu `from` toi `to`.
static func screen_angle(from: Vector2, to: Vector2) -> float:
	return (to - from).angle()

## Mui ten ria man hinh. screen_pos: den chieu len man hinh; behind: den sau camera.
## Tra {visible, angle, pos}; visible=false neu den trong man hinh va khong o sau.
static func edge_arrow(screen_pos: Vector2, size: Vector2, behind: bool, margin: float = 40.0) -> Dictionary:
	var rect := Rect2(Vector2.ZERO, size)
	if not behind and rect.has_point(screen_pos):
		return {"visible": false, "angle": 0.0, "pos": Vector2.ZERO}
	var c := size * 0.5
	var d := screen_pos - c
	if behind:
		d = -d
	if d.length() < 0.001:
		d = Vector2(0, 1)
	var half := c - Vector2(margin, margin)
	var k := minf(half.x / maxf(absf(d.x), 0.001), half.y / maxf(absf(d.y), 0.001))
	return {"visible": true, "angle": d.angle(), "pos": c + d * k}

static func prompt_text(carried: int, capacity: int) -> String:
	return "E — Nạp ánh sáng (%d/%d)" % [carried, capacity]
