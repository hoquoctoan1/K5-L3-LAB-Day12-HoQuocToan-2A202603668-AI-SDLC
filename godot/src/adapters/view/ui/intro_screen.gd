extends Control
## The dem: show_night(n, island, line). Signal continue_pressed (nut hoac Enter).
const U = preload("res://src/adapters/view/ui/ui_util.gd")
signal continue_pressed
const ISLANDS := {1: "Đảo Bến", 2: "Đảo Cau", 3: "Đảo Chuông"}
const LINES := {
	1: "Gió còn hiền, cháu à. Nhặt đom đóm, thắp từng ngọn đèn nhé.",
	2: "Đêm nay mây dày hơn. Đừng để Bóng Mực lại gần đèn.",
	3: "Đêm cuối rồi. Giữ vững ngọn lửa, bình minh sắp tới.",
}
var _n: Label
var _isl: Label
var _line: Label

static func island_name(night: int) -> String:
	return ISLANDS.get(night, "Đảo ?")

static func keeper_line(night: int) -> String:
	return LINES.get(night, "")

func _ready() -> void:
	var v := U.panel_root(self)
	_n = U.label("", 30, U.C_GOLD)
	_isl = U.label("", 52)
	_line = U.label("", 22)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size = Vector2(640, 0)
	v.add_child(_n)
	v.add_child(_isl)
	v.add_child(_line)
	v.add_child(U.label("— Ông Đăng, người giữ đèn", 18, U.C_GOLD))
	var b := U.button("Tiếp tục (Enter)", func(): continue_pressed.emit())
	v.add_child(b)
	b.grab_focus()

func show_night(night: int, island: String = "", line: String = "") -> void:
	_n.text = "ĐÊM %d" % night
	_isl.text = island if island != "" else island_name(night)
	_line.text = "“%s”" % (line if line != "" else keeper_line(night))

func _unhandled_key_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER):
		continue_pressed.emit()
