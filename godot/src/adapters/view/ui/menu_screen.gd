extends Control
## Menu chinh. Signals: play_pressed, settings_pressed, quit_pressed.
const U = preload("res://src/adapters/view/ui/ui_util.gd")
signal play_pressed
signal settings_pressed
signal quit_pressed

func _ready() -> void:
	var v := U.panel_root(self)
	v.add_child(U.label("ĐẢO ĐÈN LỒNG", 56, U.C_GOLD))
	v.add_child(U.label("Thắp sáng ba đêm trên biển mây", 20))
	v.add_child(Control.new())
	var b := U.button("Chơi", func(): play_pressed.emit())
	v.add_child(b)
	v.add_child(U.button("Cài đặt", func(): settings_pressed.emit()))
	v.add_child(U.button("Thoát", func(): quit_pressed.emit()))
	b.grab_focus()
