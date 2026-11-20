extends Control
## HUD tai su dung. Goi update_values(dict). Khoa (deu tuy chon, thieu = giu gia tri cu):
##  flames:int, flames_max:int      - Ngon Lua (tren-trai)
##  time_left:float (giay)          - dong ho mm:ss (tren-giua), do + nhap nhay khi <= 30 s
##  lit:int, total:int, score:int   - den k/n va diem (tren-phai)
##  carried:int, capacity:int       - thanh dom dom (duoi-giua, capacity o)
##  dash_cd, pulse_cd:float 0..1    - phan hoi chieu con lai (0 = san sang)
##  near_lantern:bool               - hien prompt "E — Nap anh sang (x/10)"
##  arrow_screen_pos:Vector2|null, arrow_behind:bool - mui ten toi den chua sang gan nhat (null = an)
const L = preload("res://src/adapters/view/ui/hud_logic.gd")
const U = preload("res://src/adapters/view/ui/ui_util.gd")
const FLAME := Color("#FFB347")
const MOTE := Color("#FFF6C2")
const DIM := Color("#1B2350")

var values := {"flames": 3, "flames_max": 3, "time_left": 180.0, "lit": 0, "total": 3, "score": 0,
	"carried": 0, "capacity": 10, "dash_cd": 0.0, "pulse_cd": 0.0, "near_lantern": false,
	"arrow_screen_pos": null, "arrow_behind": false}
var _t := 0.0
var _flames_box: HBoxContainer
var _clock: Label
var _lan: Label
var _score: Label
var _motes_box: HBoxContainer
var _prompt: Label
var _dash: Control
var _pulse: Control
var _arrow: Control
var _arrow_info := {"visible": false, "angle": 0.0, "pos": Vector2.ZERO}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# tren-trai
	var tl := _corner(Control.PRESET_TOP_LEFT)
	tl.add_child(U.label("Ngọn Lửa", 16, U.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	_flames_box = HBoxContainer.new()
	tl.add_child(_flames_box)
	# tren-giua
	_clock = U.label("00:00", 40)
	_clock.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_clock.offset_left = -80
	_clock.offset_right = 80
	_clock.offset_top = 12
	add_child(_clock)
	# tren-phai
	var tr := _corner(Control.PRESET_TOP_RIGHT)
	_lan = U.label("", 26, U.C_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_score = U.label("", 26, U.C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	tr.add_child(_lan)
	tr.add_child(_score)
	# duoi-giua
	var bc := VBoxContainer.new()
	bc.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bc.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bc.offset_bottom = -18
	bc.alignment = BoxContainer.ALIGNMENT_END
	add_child(bc)
	_prompt = U.label("", 22, U.C_GOLD)
	bc.add_child(_prompt)
	_motes_box = HBoxContainer.new()
	_motes_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_motes_box.add_theme_constant_override("separation", 4)
	bc.add_child(_motes_box)
	# duoi-phai
	var br := HBoxContainer.new()
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	br.grow_vertical = Control.GROW_DIRECTION_BEGIN
	br.offset_right = -18
	br.offset_bottom = -18
	br.add_theme_constant_override("separation", 10)
	add_child(br)
	_dash = _cd_icon("Lướt", br)
	_pulse = _cd_icon("Tỏa Sáng", br)
	_arrow = Control.new()
	_arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)
	_apply()

func _corner(preset: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(preset as Control.LayoutPreset)
	if preset == Control.PRESET_TOP_RIGHT:
		v.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		v.offset_right = -18
	else:
		v.offset_left = 18
	v.offset_top = 12
	add_child(v)
	return v

func _cd_icon(txt: String, parent: Control) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(76, 76)
	var bg := ColorRect.new()
	bg.name = "bg"
	bg.color = DIM
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(bg)
	var fill := ColorRect.new()  # phan hoi chieu con lai, tu day len
	fill.name = "fill"
	fill.color = Color(0, 0, 0, 0.65)
	c.add_child(fill)
	var l := U.label(txt, 15)
	l.name = "lbl"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(l)
	parent.add_child(c)
	return c

func update_values(d: Dictionary) -> void:
	for k in d:
		if values.has(k):
			values[k] = d[k]
	_apply()

func _apply() -> void:
	_rebuild(_flames_box, int(values["flames_max"]), int(values["flames"]), FLAME, Vector2(22, 22))
	_rebuild(_motes_box, int(values["capacity"]), int(values["carried"]), MOTE, Vector2(26, 18))
	_lan.text = "Đèn %d/%d" % [int(values["lit"]), int(values["total"])]
	_score.text = "Điểm %d" % int(values["score"])
	_prompt.text = L.prompt_text(int(values["carried"]), int(values["capacity"])) if values["near_lantern"] else ""
	_set_cd(_dash, float(values["dash_cd"]))
	_set_cd(_pulse, float(values["pulse_cd"]))
	_update_clock()
	if _arrow:
		_arrow.queue_redraw()

func _rebuild(box: HBoxContainer, n: int, filled: int, col: Color, cell: Vector2) -> void:
	while box.get_child_count() > n:
		var c := box.get_child(box.get_child_count() - 1)
		box.remove_child(c)
		c.free()
	while box.get_child_count() < n:
		var r := ColorRect.new()
		r.custom_minimum_size = cell
		box.add_child(r)
	for i in n:
		(box.get_child(i) as ColorRect).color = col if i < filled else DIM

func _set_cd(icon: Control, rem: float) -> void:
	rem = clampf(rem, 0.0, 1.0)
	var fill: ColorRect = icon.get_node("fill")
	fill.position = Vector2(0, 76.0 * (1.0 - rem))
	fill.size = Vector2(76, 76.0 * rem)
	(icon.get_node("bg") as ColorRect).color = Color("#3A3450") if rem > 0.0 else Color("#2F5D50")

func _update_clock() -> void:
	var t := float(values["time_left"])
	_clock.text = L.format_clock(t)
	var urgent := L.clock_urgent(t)
	_clock.add_theme_color_override("font_color", U.C_DANGER if urgent else U.C_TEXT)
	_clock.visible = (not urgent) or L.blink_on(_t)

func _process(delta: float) -> void:
	_t += delta
	_update_clock()

func _draw_arrow() -> void:
	var sp = values["arrow_screen_pos"]
	if not (sp is Vector2):
		return
	_arrow_info = L.edge_arrow(sp, _arrow.size, bool(values["arrow_behind"]))
	if not _arrow_info["visible"]:
		return
	var pos: Vector2 = _arrow_info["pos"]
	var a: float = _arrow_info["angle"]
	var pts := PackedVector2Array([Vector2(22, 0), Vector2(-14, -16), Vector2(-6, 0), Vector2(-14, 16)])
	var xf := Transform2D(a, pos)
	var out := PackedVector2Array()
	for p in pts:
		out.append(xf * p)
	_arrow.draw_colored_polygon(out, U.C_GOLD)
