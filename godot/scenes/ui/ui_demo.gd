extends Control
## Demo: hien tung man hinh UI. CLI (sau "--"): --shot=<abs png> -> chup moi man vao <dir>/p2_ui_<ten>.png roi thoat.
const Menu = preload("res://src/adapters/view/ui/menu_screen.gd")
const Intro = preload("res://src/adapters/view/ui/intro_screen.gd")
const Pause = preload("res://src/adapters/view/ui/pause_screen.gd")
const SettingsScreen = preload("res://src/adapters/view/ui/settings_screen.gd")
const Result = preload("res://src/adapters/view/ui/result_screen.gd")
const Dawn = preload("res://src/adapters/view/ui/dawn_screen.gd")
const Hud = preload("res://src/adapters/view/ui/hud.gd")
const SettingsCls = preload("res://src/adapters/view/ui/settings.gd")
const Synth = preload("res://src/adapters/view/audio/synth.gd")
const Bus = preload("res://src/adapters/view/audio/audio_bus.gd")

var _screens := {}

func _ready() -> void:
	var shot := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
	var settings = SettingsCls.new()
	settings.load_settings()
	var bus = Bus.new()
	bus.settings = settings
	add_child(bus)
	# nen scene gia lap (cat tu game) de HUD nhin ro
	var world := ColorRect.new()
	world.color = Color("#12384A")
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(world)
	var hud = Hud.new()
	hud.update_values({"flames": 2, "lit": 1, "total": 3, "score": 420, "time_left": 24.0, "carried": 7,
		"dash_cd": 0.4, "pulse_cd": 0.0, "near_lantern": true,
		"arrow_screen_pos": Vector2(1700, 300)})
	_screens["hud"] = hud
	var menu = Menu.new()
	_screens["menu"] = menu
	var intro = Intro.new()
	_screens["intro"] = intro
	var pause = Pause.new()
	_screens["pause"] = pause
	var st = SettingsScreen.new()
	st.settings = settings
	_screens["settings"] = st
	var res = Result.new()
	_screens["result"] = res
	var dawn = Dawn.new()
	_screens["dawn"] = dawn
	for k in _screens:
		_screens[k].visible = false
		add_child(_screens[k])
	intro.show_night(2)
	res.show_result(true, 1250, 1)
	dawn.show_total(3870)
	menu.play_pressed.connect(func(): _show("intro"))
	intro.continue_pressed.connect(func(): _show("hud"))
	menu.settings_pressed.connect(func(): _show("settings"))
	st.back_pressed.connect(func(): _show("menu"))
	menu.quit_pressed.connect(func(): get_tree().quit())
	_show("menu")
	if shot != "":
		await _run_shots(shot.get_base_dir())
		_check_audio()
		get_tree().quit()

func _show(n: String) -> void:
	for k in _screens:
		_screens[k].visible = (k == n)

func _run_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for n in ["menu", "intro", "pause", "settings", "hud", "result", "dawn"]:
		_show(n)
		for i in 6:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var p := "%s/p2_ui_%s.png" % [dir, n]
		print("saved ", p, " err=", img.save_png(p), " size=", img.get_size())

func _check_audio() -> void:
	var ok := true
	for n in Synth.SFX_NAMES:
		var s := Synth.sfx(n)
		var pk := Synth.peak(s)
		print("sfx %s samples=%d peak=%.3f" % [n, s.size(), pk])
		ok = ok and s.size() > 500 and pk > 0.05 and pk <= 1.0
	var m := Synth.music()
	print("music samples=%d peak=%.3f" % [m.size(), Synth.peak(m)])
	ok = ok and m.size() > Synth.RATE * 10 and Synth.peak(m) > 0.05
	print("AUDIO ", "PASS" if ok else "FAIL")
