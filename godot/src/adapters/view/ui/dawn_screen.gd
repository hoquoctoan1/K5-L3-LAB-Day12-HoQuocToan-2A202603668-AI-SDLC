extends Control
## Man hinh Binh Minh sau Dem 3: show_total(total). Signal menu_pressed.
const U = preload("res://src/adapters/view/ui/ui_util.gd")
signal menu_pressed
var _total: Label

func _ready() -> void:
	var v := U.panel_root(self)
	v.add_child(U.label("BÌNH MINH", 64, U.C_GOLD))
	v.add_child(U.label("Ba ngọn đèn đã sáng. Biển mây đón ngày mới.", 22))
	_total = U.label("", 32)
	v.add_child(_total)
	v.add_child(U.button("Về menu", func(): menu_pressed.emit()))

func show_total(total: int) -> void:
	_total.text = "Tổng điểm: %d" % total
