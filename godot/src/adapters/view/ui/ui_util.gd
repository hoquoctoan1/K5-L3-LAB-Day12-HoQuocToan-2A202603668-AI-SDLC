extends RefCounted
## Tien ich dung chung cho man hinh UI.
const C_TEXT := Color("#F5F1E6")
const C_DANGER := Color("#FF5A5F")
const C_GOLD := Color("#F2C14E")
const C_SKY := Color("#0E1430")
const C_MIST := Color("#1B2350")

static func label(text: String, size: int = 24, col: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align as HorizontalAlignment
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

static func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 46)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b

## Nen toi + cot giua. Tra VBoxContainer de them noi dung.
static func panel_root(host: Control, bg_alpha: float = 1.0) -> VBoxContainer:
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(C_SKY, bg_alpha)
	host.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	host.add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	cc.add_child(v)
	return v
