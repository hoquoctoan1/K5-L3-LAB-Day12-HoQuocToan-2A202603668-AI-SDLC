extends CanvasLayer

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.name = "PreviewPanel"
	panel.position = Vector2(24.0, 24.0)
	panel.custom_minimum_size = Vector2(350.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 18)
	margins.add_theme_constant_override("margin_top", 14)
	margins.add_theme_constant_override("margin_right", 18)
	margins.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margins.add_child(content)
	content.add_child(_make_label("ĐẢO ĐÈN LỒNG", 24, Color(1.0, 0.86, 0.58)))
	content.add_child(_make_label("Đêm 1 — Đảo Bến | VISUAL PREVIEW", 14, Color(0.78, 0.73, 0.92)))
	content.add_child(HSeparator.new())
	content.add_child(_make_stat_row("Máu", "--"))
	content.add_child(_make_stat_row("Năng lượng ánh sáng", "--"))
	content.add_child(_make_stat_row("Đèn đã thắp", "-- / 5"))
	content.add_child(_make_stat_row("Điểm", "--"))
	content.add_child(HSeparator.new())
	content.add_child(_make_label("Tương tác: chưa hoạt động", 13, Color(0.87, 0.82, 0.96)))
	content.add_child(_make_label("Tỏa sáng: chưa hoạt động", 13, Color(0.87, 0.82, 0.96)))
	content.add_child(_make_label("GameSession / gameplay chưa kết nối", 12, Color(1.0, 0.69, 0.43)))

	var footer := _make_label(
		"Mây, đèn và HUD là placeholder tĩnh. Chưa có di chuyển, đom đóm hay Bóng Mực.",
		13,
		Color(0.92, 0.88, 1.0)
	)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(footer)

func _make_stat_row(caption: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := _make_label(caption, 16, Color(0.93, 0.91, 1.0))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(_make_label(value, 16, Color(1.0, 0.78, 0.39)))
	return row

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.035, 0.11, 0.91)
	style.border_color = Color(0.66, 0.48, 0.86, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style
