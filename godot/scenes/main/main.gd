extends Node
## P2-D1: flow controller. Menu -> Intro -> Play -> Result -> Next night -> Binh Minh.
## Phim/chuot -> FrameInput v2 -> Sim.step -> GameView.apply_state / Hud / Audio.
## PAUSE: bam Esc/P -> gui MOT frame {pause:true} (canh len) roi DUNG goi sim.step trong luc tam dung
## (sim dong bang theo interfaces_v2 muc 1; main khong tu tien tick). Bam lai -> gui MOT frame pause:true nua de tiep tuc.
## CLI (sau "--"): --night=N --auto-demo --shot=<abs png> --smoke --seed=<n> --fps-test
##   --cam-yaw=<deg> --cam-focus=x,y,z --cam-dist=<m> --cam-height=<m> --demo-ticks=<n>
const SimScript = preload("res://src/core/sim.gd")
const _Cfg = preload("res://src/core/game_config.gd")
const View = preload("res://src/adapters/view/game_view.gd")
const Hud = preload("res://src/adapters/view/ui/hud.gd")
const Menu = preload("res://src/adapters/view/ui/menu_screen.gd")
const Intro = preload("res://src/adapters/view/ui/intro_screen.gd")
const Pause = preload("res://src/adapters/view/ui/pause_screen.gd")
const SettingsScreen = preload("res://src/adapters/view/ui/settings_screen.gd")
const Result = preload("res://src/adapters/view/ui/result_screen.gd")
const Dawn = preload("res://src/adapters/view/ui/dawn_screen.gd")
const SettingsCls = preload("res://src/adapters/view/ui/settings.gd")
const Bus = preload("res://src/adapters/view/audio/audio_bus.gd")

const BASE_SENS := 0.004
const KEY_YAW_SPEED := 1.8

enum Mode { MENU, INTRO, PLAY, RESULT, DAWN }

var sim
var view
var mode: int = Mode.MENU
var night: int = 1
var total_score: int = 0
var paused: bool = false
var settings
var bus
var _seed: int = 1
var _fixed_seed := false
var _acc := 0.0
var _pending := {"jump": false, "interact": false, "pulse": false, "dash": false}
var _yaw := 0.0
var _demo := false
var _smoke := false
var _fps_test := false
var _shot := ""
var _cli_night := 0
var _demo_ticks := 900
var _cam_focus = null
var _hud
var _menu
var _intro
var _pause
var _settings_screen
var _result
var _dawn
var _ui: CanvasLayer
var _settings_return := "menu"
var _result_won := false
var _last_cd_sec := -1
var _prev_grounded := true
var _result_wait := 0.0
var _score_counted := false

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	_register_actions()
	view = $GameView
	for a in OS.get_cmdline_user_args():
		if a == "--auto-demo":
			_demo = true
		elif a == "--smoke":
			_smoke = true
		elif a == "--fps-test":
			_fps_test = true
			_demo = true
		elif a.begins_with("--shot="):
			_shot = a.substr(7)
			_demo = true
		elif a.begins_with("--seed="):
			_seed = int(a.substr(7))
			_fixed_seed = true
		elif a.begins_with("--night="):
			_cli_night = clampi(int(a.substr(8)), 1, 3)
		elif a.begins_with("--cam-yaw="):
			_yaw = deg_to_rad(float(a.substr(10)))
		elif a.begins_with("--cam-dist="):
			view.camera_distance = float(a.substr(11))
		elif a.begins_with("--cam-height="):
			view.camera_height = float(a.substr(13))
		elif a.begins_with("--demo-ticks="):
			_demo_ticks = int(a.substr(13))
		elif a.begins_with("--cam-focus="):
			var p := a.substr(12).split(",")
			if p.size() == 3:
				_cam_focus = Vector3(float(p[0]), float(p[1]), float(p[2]))
	if _demo or _smoke or DisplayServer.get_name() == "headless":
		_fixed_seed = true
	elif not _fixed_seed:
		_seed = int(Time.get_unix_time_from_system()) & 0x7fffffff
	view.focus_override = _cam_focus
	settings = SettingsCls.new()
	settings.load_settings()
	bus = Bus.new()
	bus.settings = settings
	add_child(bus)
	_build_ui()
	if _smoke:
		_run_smoke()
		return
	if _demo or _cli_night > 0:
		_begin_game(maxi(_cli_night, 1), false)
		if _demo:
			_run_demo()
	else:
		_show_menu()

# ---------------- UI ----------------
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	_hud = Hud.new()
	_ui.add_child(_hud)
	_menu = Menu.new()
	_menu.play_pressed.connect(func(): _begin_game(1, true))
	_menu.settings_pressed.connect(func(): _open_settings("menu"))
	_menu.quit_pressed.connect(func(): get_tree().quit())
	_intro = Intro.new()
	_intro.continue_pressed.connect(_on_intro_continue)
	_settings_screen = SettingsScreen.new()
	_settings_screen.settings = settings
	_settings_screen.back_pressed.connect(_close_settings)
	_result = Result.new()
	_result.next_pressed.connect(_on_next)
	_result.retry_pressed.connect(func(): _start_night(night, false))
	_dawn = Dawn.new()
	_dawn.menu_pressed.connect(_show_menu)
	_pause = Pause.new()
	_pause.resume_pressed.connect(func(): pass)
	_pause.restart_pressed.connect(func(): _start_night(night, false))
	_pause.settings_pressed.connect(func(): _open_settings("pause"))
	_pause.menu_pressed.connect(_show_menu)
	_pause.toggled.connect(_on_pause_toggled)
	for s in [_menu, _intro, _settings_screen, _result, _dawn]:
		_ui.add_child(s)
		s.visible = false
	_pause.visible = false
	_hud.visible = false

func _hide_all() -> void:
	for s in [_menu, _intro, _settings_screen, _result, _dawn, _hud]:
		s.visible = false
	if _pause.get_parent() != null:
		_ui.remove_child(_pause)
	_pause.visible = false
	paused = false

func _show_menu() -> void:
	_hide_all()
	mode = Mode.MENU
	_menu.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	bus.play_music()

func _open_settings(ret: String) -> void:
	_settings_return = ret
	_settings_screen.bind(settings)
	_settings_screen.visible = true
	if ret == "menu":
		_menu.visible = false

func _close_settings() -> void:
	bus.apply_volume()
	_settings_screen.visible = false
	if _settings_return == "menu":
		_menu.visible = true

func _begin_game(n: int, with_intro: bool) -> void:
	total_score = 0
	night = n
	_start_night(n, with_intro)

## Vao dem n: co intro (menu/next) hoac chay thang.
func _start_night(n: int, with_intro: bool) -> void:
	_hide_all()
	night = n
	sim = SimScript.new(_seed, n)
	sim.begin()
	_acc = 0.0
	_score_counted = false
	_last_cd_sec = -1
	_prev_grounded = true
	for k in _pending:
		_pending[k] = false
	view.apply_state(sim.state)
	if with_intro:
		mode = Mode.INTRO
		_intro.show_night(n)
		_intro.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_enter_play()

func _on_intro_continue() -> void:
	if mode == Mode.INTRO:
		_enter_play()

func _enter_play() -> void:
	_hide_all()
	mode = Mode.PLAY
	_hud.visible = true
	_ui.add_child(_pause)
	_pause.visible = false
	bus.play_music()
	_update_hud()

func _on_pause_toggled(open: bool) -> void:
	if mode != Mode.PLAY:
		return
	paused = open
	if sim != null and sim.state.status == "playing":
		sim.step(_pause_frame())   # canh len pause: bat/tat dong bang trong core
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_settings_screen.visible = false

func _pause_frame() -> Dictionary:
	return {"move": Vector2.ZERO, "cam_yaw_deg": rad_to_deg(_yaw), "jump": false, "interact": false,
		"pulse": false, "dash": false, "pause": true}

func _on_next() -> void:
	if night >= 3:
		_hide_all()
		mode = Mode.DAWN
		_dawn.show_total(total_score)
		_dawn.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_start_night(night + 1, true)

func _finish_night() -> void:
	var st = sim.state
	_result_won = st.status == "won"
	if _result_won and not _score_counted:
		_score_counted = true
		total_score += st.score
	bus.play_sfx("win" if _result_won else "lose")
	_hide_all()
	mode = Mode.RESULT
	var reason: String = "" if _result_won else ("Hết Ngọn Lửa" if st.loss_reason == "no_flames" else "Trời đã sáng")
	_result.show_result(_result_won, st.score, night, reason)
	_result.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ---------------- input ----------------
func _register_actions() -> void:
	var map := {
		"mv_fwd": [KEY_W, KEY_UP], "mv_back": [KEY_S, KEY_DOWN],
		"mv_left": [KEY_A, KEY_LEFT], "mv_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "dash": [KEY_SHIFT], "interact": [KEY_E], "pulse": [KEY_F],
		"yaw_l": [KEY_Q], "yaw_r": [KEY_R],
	}
	for act in map:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for k in map[act]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(act, ev)

func _input(event: InputEvent) -> void:
	if mode != Mode.PLAY or paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * BASE_SENS * settings.mouse_sensitivity
	for a in _pending:
		if event.is_action_pressed(a, false, true):
			_pending[a] = true

static func rotate_move(raw: Vector2, yaw_deg: float) -> Vector2:
	var th := deg_to_rad(yaw_deg)
	var c := cos(th)
	var s := sin(th)
	var w := Vector2(raw.x * c + raw.y * s, -raw.x * s + raw.y * c)
	if w.length() > 1.0:
		w = w.normalized()
	return w

func _build_frame() -> Dictionary:
	var raw := Vector2(
		Input.get_action_strength("mv_right") - Input.get_action_strength("mv_left"),
		Input.get_action_strength("mv_back") - Input.get_action_strength("mv_fwd"))
	var yaw_deg := rad_to_deg(_yaw)
	var f := {
		"move": rotate_move(raw, yaw_deg), "cam_yaw_deg": yaw_deg,
		"jump": _pending["jump"], "interact": _pending["interact"], "pulse": _pending["pulse"],
		"dash": _pending["dash"], "pause": false,
	}
	for k in _pending:
		_pending[k] = false
	return f

func _process(delta: float) -> void:
	if mode == Mode.PLAY and not paused:
		_yaw += (Input.get_action_strength("yaw_r") - Input.get_action_strength("yaw_l")) * KEY_YAW_SPEED * delta
	view.camera_yaw = _yaw
	if mode == Mode.RESULT or mode == Mode.INTRO or mode == Mode.MENU or mode == Mode.DAWN:
		return
	if sim != null and not _demo and not _smoke:
		view.apply_state(sim.state)
		_update_hud()
	if _result_wait > 0.0:
		_result_wait -= delta
		if _result_wait <= 0.0:
			_finish_night()

func _physics_process(delta: float) -> void:
	if _demo or _smoke or mode != Mode.PLAY or paused or sim == null or sim.state.status != "playing":
		return
	_acc += delta
	var n := 0
	while _acc >= _Cfg.DT and n < 5:
		_acc -= _Cfg.DT
		n += 1
		step_frame(_build_frame())
		if sim.state.status != "playing":
			break
	if n == 5:
		_acc = 0.0

func step_frame(frame: Dictionary) -> Array:
	var ev: Array = sim.step(frame)
	_handle_events(ev)
	var st = sim.state
	var g: bool = st.player.get("grounded", true)
	if _prev_grounded and not g and float(st.player.get("vel", Vector3.ZERO).y) > 0.5:
		bus.play_sfx("jump")
	_prev_grounded = g
	var left := int(ceil(st.time_left_s()))
	if left != _last_cd_sec:
		_last_cd_sec = left
		if left <= 10 and left > 0 and st.status == "playing":
			bus.play_sfx("countdown_tick")
	view.apply_state(st)
	if st.status != "playing" and mode == Mode.PLAY and _result_wait <= 0.0 and not _demo and not _smoke:
		_result_wait = 1.2
	return ev

const SFX_MAP := {"mote_picked": "pickup", "lantern_lit": "light_lantern", "pulse": "pulse", "player_hit": "hit",
	"dash": "dash", "shade_spawned": "shade_spawn", "charm_picked": "pickup"}

func _handle_events(evs: Array) -> void:
	for e in evs:
		var nm: String = e.get("name", "")
		if SFX_MAP.has(nm):
			bus.play_sfx(SFX_MAP[nm])
		view.play_event(e)

# ---------------- HUD ----------------
func _update_hud() -> void:
	if sim == null:
		return
	var st = sim.state
	var p: Dictionary = st.player
	var pp: Vector3 = p.get("pos", Vector3.ZERO)
	var lit := 0
	var near := false
	var best = null
	var best_d := 1e9
	for l in st.lanterns:
		if l["lit"]:
			lit += 1
			continue
		var d: float = (l["pos"] - pp).length()
		if d <= _Cfg.INTERACT_RADIUS:
			near = true
		if d < best_d:
			best_d = d
			best = l["pos"]
	var vals := {
		"flames": int(p.get("flames", 0)), "flames_max": _Cfg.FLAMES,
		"time_left": st.time_left_s(), "lit": lit, "total": st.lanterns.size(), "score": st.score,
		"carried": int(p.get("carried", 0)), "capacity": _Cfg.CARRY_CAPACITY,
		"dash_cd": clampf(float(p.get("dash_cd_ticks", 0)) / float(_Cfg.DASH_COOLDOWN_TICKS), 0.0, 1.0),
		"pulse_cd": clampf(float(p.get("pulse_cd_ticks", 0)) / float(_Cfg.PULSE_COOLDOWN_TICKS), 0.0, 1.0),
		"near_lantern": near, "arrow_screen_pos": null, "arrow_behind": false,
	}
	var cam: Camera3D = view.camera
	if best != null and cam != null and cam.is_inside_tree():
		var tp: Vector3 = best + Vector3(0, 2.7, 0)
		vals["arrow_screen_pos"] = cam.unproject_position(tp)
		vals["arrow_behind"] = cam.is_position_behind(tp)
	_hud.update_values(vals)

# ---------------- bot / demo ----------------
func _bot_frame() -> Dictionary:
	var st = sim.state
	var pp: Vector3 = st.player["pos"]
	var target = null
	var inter := false
	var best := 1e9
	var carried: int = st.player["carried"]
	if carried >= _Cfg.CARRY_CAPACITY or st.motes.is_empty():
		for l in st.lanterns:
			if not l["lit"] and absf(l["pos"].y - pp.y) < 1.5 and _same_island(st, l["pos"], pp):
				var d: float = (l["pos"] - pp).length()
				if d < best:
					best = d
					target = l["pos"]
		inter = target != null and best <= _Cfg.INTERACT_RADIUS * 0.8
	if target == null:
		for m in st.motes:
			if absf(m["pos"].y - pp.y) < 1.5 and _same_island(st, m["pos"], pp):
				var d: float = (m["pos"] - pp).length()
				if d < best:
					best = d
					target = m["pos"]
	var mv := Vector2.ZERO
	if target != null and not inter:
		var dir: Vector3 = target - pp
		if dir.length() > 0.2:
			mv = Vector2(dir.x, dir.z).normalized()
	var pulse := false
	if int(st.player.get("pulse_cd_ticks", 0)) == 0 and carried >= 3:
		for s in st.shades:
			if (s["pos"] - pp).length() < 3.5:
				pulse = true
	return {"move": mv, "cam_yaw_deg": 0.0, "jump": false, "interact": inter, "pulse": pulse, "dash": false, "pause": false}

func _same_island(st, a: Vector3, b: Vector3) -> bool:
	var isl: Array = st.map.get("islands", [])
	if isl.size() < 2:
		return true
	for i in isl:
		var c: Vector3 = i["center"]
		if Vector2(a.x - c.x, a.z - c.z).length() <= i["radius"] and Vector2(b.x - c.x, b.z - c.z).length() <= i["radius"]:
			return true
	return false

func _run_demo() -> void:
	var counts := {}
	var fps_samples: Array = []
	if _fps_test:
		_demo_ticks = 600
	for i in _demo_ticks:
		var fr := _bot_frame()
		fr["cam_yaw_deg"] = 0.0
		for e in step_frame(fr):
			counts[e["name"]] = counts.get(e["name"], 0) + 1
		if _fps_test:
			await get_tree().process_frame
			if i >= 60 and i % 20 == 0:
				fps_samples.append(Engine.get_frames_per_second())
		if sim.state.status != "playing":
			break
		view.camera_yaw = _yaw
	_update_hud()
	var p = sim.state.player
	print("demo night=%d steps=%d status=%s score=%d carried=%d flames=%d pos=%s events=%s" % [
		night, sim.state.steps, sim.state.status, sim.state.score, p["carried"], p["flames"], str(p["pos"]), str(counts)])
	if _fps_test:
		var sum := 0.0
		for f in fps_samples:
			sum += f
		print("FPS samples=%d avg=%.1f min=%.1f res=%s" % [fps_samples.size(), sum / maxf(fps_samples.size(), 1), fps_samples.min() if fps_samples.size() > 0 else 0.0, str(get_viewport().get_visible_rect().size)])
	if _shot != "":
		for i in 8:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(_shot.get_base_dir())
		print("saved ", _shot, " err=", img.save_png(_shot))
	if _shot != "" or _fps_test:
		get_tree().quit()

# ---------------- smoke (headless) ----------------
func _idle() -> Dictionary:
	return {"move": Vector2.ZERO, "cam_yaw_deg": 0.0, "jump": false, "interact": false, "pulse": false, "dash": false, "pause": false}

func _run_smoke() -> void:
	var ok := true
	_begin_game(1, true)
	ok = ok and mode == Mode.INTRO
	for n in [1, 2, 3]:
		_intro.continue_pressed.emit()
		ok = ok and mode == Mode.PLAY and night == n
		# bot ngan
		for i in 900:
			step_frame(_bot_frame())
		print("night %d bot900: status=%s steps=%d score=%d" % [n, sim.state.status, sim.state.steps, sim.state.score])
		# pause: gui canh pause roi buoc them -> steps khong doi
		var s0: int = sim.state.steps
		_pause.set_open(true)
		var tk0: int = sim.state.tick
		for i in 20:
			sim.step(_idle())
		var frozen: bool = sim.state.steps == s0
		print("  pause: paused=%s steps %d->%d frozen=%s tick %d->%d" % [sim.state.paused, s0, sim.state.steps, frozen, tk0, sim.state.tick])
		ok = ok and frozen and paused
		_pause.set_open(false)
		ok = ok and not paused and not sim.state.paused
		# thua truoc o dem 1: retry
		if n == 1:
			sim.state.player["flames"] = 0
			step_frame(_idle())
			print("  force-lose: status=%s reason=%s" % [sim.state.status, sim.state.loss_reason])
			ok = ok and sim.state.status == "lost"
			_finish_night()
			ok = ok and mode == Mode.RESULT
			_result.retry_pressed.emit()
			ok = ok and mode == Mode.PLAY and sim.state.status == "playing" and night == 1
			for i in 5:
				step_frame(_idle())
		# thang cuong buc
		for l in sim.state.lanterns:
			l["lit"] = true
		step_frame(_idle())
		print("  force-win: status=%s score=%d" % [sim.state.status, sim.state.score])
		ok = ok and sim.state.status == "won"
		_finish_night()
		ok = ok and mode == Mode.RESULT
		_result.next_pressed.emit()
		if n < 3:
			ok = ok and mode == Mode.INTRO and night == n + 1
	ok = ok and mode == Mode.DAWN
	print("DAWN total_score=%d" % total_score)
	# het gio -> dawn
	_start_night(2, false)
	sim.state.time_left_initial = 1.0
	for i in 100:
		step_frame(_idle())
	print("lose-dawn: status=%s reason=%s" % [sim.state.status, sim.state.loss_reason])
	ok = ok and sim.state.status == "lost" and sim.state.loss_reason == "dawn"
	for i in 50:
		step_frame(_idle())
	print("SMOKE ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
