extends Control
## Man cai dat: bind(settings) roi keo slider -> settings doi + luu. Signal back_pressed.
const U = preload("res://src/adapters/view/ui/ui_util.gd")
signal back_pressed
var settings
var _vol: HSlider
var _sens: HSlider
var _vl: Label
var _sl: Label
var _cb: CheckButton

func _ready() -> void:
	var v := U.panel_root(self)
	v.add_child(U.label("CÀI ĐẶT", 44, U.C_GOLD))
	_vl = U.label("", 22)
	v.add_child(_vl)
	_vol = _slider(0.0, 1.0, 0.01)
	v.add_child(_vol)
	_sl = U.label("", 22)
	v.add_child(_sl)
	_sens = _slider(0.25, 3.0, 0.05)
	v.add_child(_sens)
	_cb = CheckButton.new()
	_cb.text = "Bảng màu dễ phân biệt"
	_cb.add_theme_font_size_override("font_size", 22)
	v.add_child(_cb)
	_cb.toggled.connect(_on_cb)
	v.add_child(U.button("Quay lại", func(): back_pressed.emit()))
	_vol.value_changed.connect(_on_vol)
	_sens.value_changed.connect(_on_sens)
	if settings:
		bind(settings)
	else:
		_refresh()

func _on_vol(x: float) -> void:
	if settings:
		settings.set_volume(x)
		settings.save_settings()
	_refresh()

func _on_cb(on: bool) -> void:
	if settings:
		settings.set_colorblind(on)
		settings.save_settings()

func _on_sens(x: float) -> void:
	if settings:
		settings.set_mouse_sensitivity(x)
		settings.save_settings()
	_refresh()

func _slider(lo: float, hi: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.custom_minimum_size = Vector2(360, 28)
	return s

func bind(s) -> void:
	settings = s
	if _vol:
		_vol.set_value_no_signal(s.volume)
		_sens.set_value_no_signal(s.mouse_sensitivity)
		_cb.set_pressed_no_signal(bool(s.colorblind))
		_refresh()

func _refresh() -> void:
	var vol: float = settings.volume if settings else _vol.value
	var sens: float = settings.mouse_sensitivity if settings else _sens.value
	_vl.text = "Âm lượng: %d%%" % int(round(vol * 100.0))
	_sl.text = "Độ nhạy chuột: %.2fx" % sens
