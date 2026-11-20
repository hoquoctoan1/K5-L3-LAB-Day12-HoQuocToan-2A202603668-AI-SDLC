extends Control
## Pause (Esc/P bat tat qua toggle()). Node chi hien/an va phat `toggled(open)`;
## chu so huu (main) dung toggled de dung han sim (get_tree().paused hoac ngung step).
const U = preload("res://src/adapters/view/ui/ui_util.gd")
signal resume_pressed
signal restart_pressed
signal settings_pressed
signal menu_pressed
signal toggled(open: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var v := U.panel_root(self, 0.82)
	v.add_child(U.label("TẠM DỪNG", 44, U.C_GOLD))
	var b := U.button("Tiếp tục", func(): resume_pressed.emit(); set_open(false))
	v.add_child(b)
	v.add_child(U.button("Chơi lại Đêm", func(): restart_pressed.emit(); set_open(false)))
	v.add_child(U.button("Cài đặt", func(): settings_pressed.emit()))
	v.add_child(U.button("Về menu", func(): menu_pressed.emit(); set_open(false)))

func set_open(o: bool) -> void:
	if visible == o:
		return
	visible = o
	toggled.emit(o)

func toggle() -> void:
	set_open(not visible)

static func is_toggle_key(e: InputEvent) -> bool:
	return e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_ESCAPE or e.keycode == KEY_P)

func _unhandled_key_input(e: InputEvent) -> void:
	if is_toggle_key(e):
		toggle()
