extends Control
## Ket qua dem: show_result(won, score, night, reason). Signals: next_pressed (chi khi thang), retry_pressed.
const U = preload("res://src/adapters/view/ui/ui_util.gd")
signal next_pressed
signal retry_pressed
var _title: Label
var _score: Label
var _next: Button
var _retry: Button

func _ready() -> void:
	var v := U.panel_root(self, 0.9)
	_title = U.label("", 48)
	_score = U.label("", 28, U.C_GOLD)
	v.add_child(_title)
	v.add_child(_score)
	_next = U.button("Đêm kế tiếp", func(): next_pressed.emit())
	_retry = U.button("Chơi lại", func(): retry_pressed.emit())
	v.add_child(_next)
	v.add_child(_retry)

func show_result(won: bool, score: int, night: int, reason: String = "") -> void:
	_title.text = ("ĐÊM %d — ĐÈN ĐÃ SÁNG" % night) if won else ("ĐÊM %d — BÓNG TỐI THẮNG" % night)
	_title.add_theme_color_override("font_color", U.C_GOLD if won else U.C_DANGER)
	_score.text = "Điểm: %d" % score + (("\n" + reason) if reason != "" else "")
	_next.visible = won
	(_next if won else _retry).grab_focus()
