extends Node
## D1: controller. Ban phim/chuot -> FrameInput (cung dinh dang headless) -> Sim.step -> GameView.apply_state.
## CLI (sau "--"): --auto-demo | --shot=<abs png> | --smoke | --seed=<n>
const SimScript = preload("res://src/core/sim.gd")
const _Cfg = preload("res://src/core/game_config.gd")

const MOUSE_SENS := 0.004
const KEY_YAW_SPEED := 1.8  # rad/s cho Q/R

var sim
var view
var _seed: int = 1
var _gui_random := true
var _acc := 0.0
var _pending := {"jump": false, "interact": false, "pulse": false}
var _yaw := 0.0
var _demo := false
var _smoke := false
var _shot := ""
var _args := {}

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	_register_actions()
	view = $GameView
	for a in OS.get_cmdline_user_args():
		if a == "--auto-demo":
			_demo = true
		elif a == "--smoke":
			_smoke = true
		elif a.begins_with("--shot="):
			_shot = a.substr(7)
			_demo = true
		elif a.begins_with("--seed="):
			_seed = int(a.substr(7))
			_gui_random = false
	if _demo or _smoke or DisplayServer.get_name() == "headless":
		_gui_random = false
	elif _gui_random:
		_seed = int(Time.get_unix_time_from_system()) & 0x7fffffff
	sim = SimScript.new(_seed)
	view.replay_requested.connect(replay)
	view.camera_yaw = _yaw
	view.apply_state(sim.state)
	if _smoke:
		_run_smoke()
	elif _demo:
		_run_demo()

func _register_actions() -> void:
	var map := {
		"mv_fwd": [KEY_W, KEY_UP], "mv_back": [KEY_S, KEY_DOWN],
		"mv_left": [KEY_A, KEY_LEFT], "mv_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "interact": [KEY_E], "pulse": [KEY_F],
		"yaw_l": [KEY_Q], "yaw_r": [KEY_R], "replay": [KEY_ENTER, KEY_KP_ENTER],
	}
	for act in map:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for k in map[act]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(act, ev)

func replay(new_seed: int = -1) -> void:
	if new_seed < 0:
		new_seed = (_seed + 1) if not _gui_random else (int(Time.get_ticks_usec()) & 0x7fffffff)
	_seed = new_seed
	sim.reset(_seed)
	_acc = 0.0
	for k in _pending:
		_pending[k] = false
	view.apply_state(sim.state)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * MOUSE_SENS
	for a in ["jump", "interact", "pulse"]:
		if event.is_action_pressed(a, false, true):
			_pending[a] = true
	if event.is_action_pressed("replay", false, true) and sim.state.status != "playing":
		replay()

## Chuyen raw (x=phai, z=sau) + yaw -> move da xoay & chuan hoa (cung cong thuc InputDecoder).
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
	}
	for k in _pending:
		_pending[k] = false
	return f

func _process(delta: float) -> void:
	_yaw += (Input.get_action_strength("yaw_r") - Input.get_action_strength("yaw_l")) * KEY_YAW_SPEED * delta
	view.camera_yaw = _yaw
	if sim.state.status == "playing" and not _demo and not _smoke:
		view.apply_state(sim.state)

func _physics_process(delta: float) -> void:
	if _demo or _smoke:
		return
	_acc += delta
	var n := 0
	while _acc >= _Cfg.DT and n < 5:
		_acc -= _Cfg.DT
		n += 1
		step_frame(_build_frame())
	if n == 5:
		_acc = 0.0

func step_frame(frame: Dictionary) -> Array:
	var ev: Array = sim.step(frame)
	view.apply_state(sim.state)
	return ev

# ---------------- scripted demo / smoke ----------------
func _bot_frame() -> Dictionary:
	var st = sim.state
	var pp: Vector3 = st.player["pos"]
	var target := Vector3.ZERO
	var inter := false
	var best := 1e9
	if st.player["carried"] >= _Cfg.CARRY_CAPACITY or st.motes.is_empty():
		for l in st.lanterns:
			if not l["lit"]:
				var d: float = (l["pos"] - pp).length()
				if d < best:
					best = d
					target = l["pos"]
		inter = best <= _Cfg.INTERACT_RADIUS * 0.8
	else:
		for m in st.motes:
			var d: float = (m["pos"] - pp).length()
			if d < best:
				best = d
				target = m["pos"]
	var dir := target - pp
	var mv := Vector2.ZERO
	if not inter and dir.length() > 0.2:
		mv = Vector2(dir.x, dir.z).normalized()
	return {"move": mv, "cam_yaw_deg": 0.0, "jump": false, "interact": inter, "pulse": false}

func _run_demo() -> void:
	var counts := {}
	for i in 600:
		for e in sim.step(_bot_frame()):
			counts[e["name"]] = counts.get(e["name"], 0) + 1
		if sim.state.status != "playing":
			break
	view.apply_state(sim.state)
	var p = sim.state.player
	print("demo done steps=%d status=%s score=%d carried=%d flames=%d events=%s" % [
		sim.state.steps, sim.state.status, sim.state.score, p["carried"], p["flames"], str(counts)])
	if _shot != "":
		for i in 8:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(_shot.get_base_dir())
		var err := img.save_png(_shot)
		print("saved ", _shot, " err=", err)
		get_tree().quit()

func _run_smoke() -> void:
	var ok := true
	var idle := {"move": Vector2.ZERO, "cam_yaw_deg": 0.0, "jump": false, "interact": false, "pulse": false}
	# 1) thua dawn: het gio
	sim.state.time_left_initial = 2.0
	var n := 0
	while sim.state.status == "playing" and n < 10000:
		step_frame(idle)
		n += 1
	print("lose-dawn: steps=%d status=%s reason=%s" % [n, sim.state.status, sim.state.loss_reason])
	ok = ok and sim.state.status == "lost" and sim.state.loss_reason == "dawn"
	# replay
	replay(2)
	print("replay: status=%s steps=%d score=%d" % [sim.state.status, sim.state.steps, sim.state.score])
	ok = ok and sim.state.status == "playing" and sim.state.steps == 0
	# 2) thang: bot choi that den khi thang / het gio, toi da 18000 tick
	var res_bot := ""
	n = 0
	while sim.state.status == "playing" and n < 18000:
		step_frame(_bot_frame())
		n += 1
	res_bot = "bot-run: steps=%d status=%s reason=%s score=%d" % [n, sim.state.status, sim.state.loss_reason, sim.state.score]
	print(res_bot)
	var bot_status: String = sim.state.status
	# 3) thang cuong buc: dat tat ca den sang
	replay(3)
	sim.step(idle)
	for l in sim.state.lanterns:
		l["lit"] = true
	step_frame(idle)
	print("force-win: status=%s score=%d" % [sim.state.status, sim.state.score])
	ok = ok and sim.state.status == "won"
	replay(4)
	ok = ok and sim.state.status == "playing"
	# 4) thua no_flames: dat 1 flame, shade tai cho nguoi choi
	sim.step(idle)
	sim.state.player["flames"] = 1
	sim.state.shades.append({"id": "Sx", "pos": sim.state.player["pos"], "state": "chase", "stun_left": 0.0})
	for i in 10:
		step_frame(idle)
	print("force-lose: status=%s reason=%s" % [sim.state.status, sim.state.loss_reason])
	ok = ok and sim.state.status == "lost"
	# 5) frame sau khi het game khong lam crash
	for i in 100:
		step_frame(idle)
	replay(5)
	print("SMOKE ", "PASS" if ok else "FAIL", " (bot_status=", bot_status, ")")
	get_tree().quit(0 if ok else 1)
