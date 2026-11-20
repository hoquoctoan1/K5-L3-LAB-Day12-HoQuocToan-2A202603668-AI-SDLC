extends Node3D
const _SimState = preload("res://src/core/sim_state.gd")
const _Cfg = preload("res://src/core/game_config.gd")
## View thuan: ve SimState. Khong co logic gameplay. Entry: apply_state(state).

signal replay_requested

## Controller sau nay dat yaw (radian) de xoay camera quanh May.
var camera_yaw: float = 0.0
var camera_distance: float = 9.0
var camera_height: float = 5.0

var _env: Environment
var _cam: Camera3D
var _player: Node3D
var _lantern_nodes: Array = []
var _mote_root: Node3D
var _shade_root: Node3D
var _mote_pool: Array = []
var _shade_pool: Array = []
var _mote_mesh: SphereMesh
var _mote_mat: StandardMaterial3D
var _shade_mesh: SphereMesh
var _shade_mat: StandardMaterial3D
var _shade_stun_mat: StandardMaterial3D
var _lantern_lit_mat: StandardMaterial3D
var _lantern_dim_mat: StandardMaterial3D
var _lit_count: int = 0

var _hud_label: Label
var _hint_label: Label
var _result_panel: PanelContainer
var _result_label: Label

func _ready() -> void:
	_build_world()
	_build_hud()

func _mat(c: Color, emis: float = 0.0, ec: Color = Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = ec
		m.emission_energy_multiplier = emis
	return m

func _mesh(parent: Node, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _sphere(rad: float, h: float = -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = rad
	s.height = rad * 2.0 if h < 0.0 else h
	s.radial_segments = 12
	s.rings = 6
	return s

func _build_world() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.04, 0.02, 0.07)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.3, 0.2, 0.45)
	_env.ambient_light_energy = 0.35
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.07, 0.04, 0.12)
	_env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-50, -30, 0)
	moon.light_color = Color(0.5, 0.4, 0.8)
	moon.light_energy = 0.5
	add_child(moon)

	var r := _Cfg.ISLAND_RADIUS
	var top := CylinderMesh.new()
	top.top_radius = r
	top.bottom_radius = r
	top.height = 1.0
	top.radial_segments = 32
	_mesh(self, top, _mat(Color(0.16, 0.22, 0.2)), Vector3(0, -0.5, 0))
	var base := CylinderMesh.new()
	base.top_radius = r
	base.bottom_radius = r * 0.35
	base.height = 14.0
	base.radial_segments = 32
	_mesh(self, base, _mat(Color(0.13, 0.09, 0.2)), Vector3(0, -8.0, 0))

	_lantern_lit_mat = _mat(Color(1, 0.75, 0.35), 4.0, Color(1, 0.6, 0.15))
	_lantern_dim_mat = _mat(Color(0.2, 0.15, 0.2))
	for i in 5:
		_lantern_nodes.append(_make_lantern())

	_mote_mesh = _sphere(0.18)
	_mote_mat = _mat(Color(1, 0.85, 0.4), 3.0, Color(1, 0.8, 0.3))
	_mote_root = Node3D.new()
	add_child(_mote_root)
	_shade_mesh = _sphere(0.9, 1.6)
	_shade_mat = _mat(Color(0.1, 0.02, 0.18), 0.6, Color(0.35, 0.05, 0.6))
	_shade_stun_mat = _mat(Color(0.45, 0.4, 0.6), 0.3, Color(0.5, 0.5, 0.8))
	_shade_root = Node3D.new()
	add_child(_shade_root)

	_player = _make_player()
	add_child(_player)
	_cam = Camera3D.new()
	_cam.fov = 65.0
	_cam.far = 300.0
	add_child(_cam)
	_cam.current = true

func _make_lantern() -> Node3D:
	var n := Node3D.new()
	var post := CylinderMesh.new()
	post.top_radius = 0.12
	post.bottom_radius = 0.18
	post.height = 2.2
	_mesh(n, post, _mat(Color(0.25, 0.16, 0.12)), Vector3(0, 1.1, 0))
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 1.0, 0.9)
	var body := _mesh(n, box, _lantern_dim_mat, Vector3(0, 2.7, 0))
	body.name = "Body"
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 2.7, 0)
	light.light_color = Color(1.0, 0.7, 0.3)
	light.omni_range = 16.0
	light.light_energy = 0.0
	n.add_child(light)
	add_child(n)
	return n

func _make_player() -> Node3D:
	var p := Node3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.5
	_mesh(p, body, _mat(Color(0.55, 0.3, 0.25)), Vector3(0, 0.85, 0))
	_mesh(p, _sphere(0.3), _mat(Color(0.9, 0.7, 0.55)), Vector3(0, 1.8, 0))
	var hat := CylinderMesh.new()
	hat.top_radius = 0.0
	hat.bottom_radius = 0.75
	hat.height = 0.55
	hat.radial_segments = 16
	_mesh(p, hat, _mat(Color(0.85, 0.7, 0.35)), Vector3(0, 2.2, 0))
	_mesh(p, _sphere(0.2), _mat(Color(1, 0.7, 0.3), 3.0, Color(1, 0.65, 0.2)), Vector3(0.5, 1.05, 0.2))
	var l := OmniLight3D.new()
	l.position = Vector3(0.5, 1.05, 0.2)
	l.light_color = Color(1, 0.75, 0.4)
	l.light_energy = 1.2
	l.omni_range = 9.0
	p.add_child(l)
	return p

func _outlined(l: Label, size: int) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0, 0.1))
	l.add_theme_constant_override("outline_size", 6)

func _build_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	_hud_label = Label.new()
	_hud_label.position = Vector2(20, 14)
	_outlined(_hud_label, 22)
	cl.add_child(_hud_label)
	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_label.position = Vector2(-300, -140)
	_hint_label.custom_minimum_size = Vector2(600, 0)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outlined(_hint_label, 24)
	cl.add_child(_hint_label)
	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_result_panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	_result_panel.add_child(vb)
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 28)
	vb.add_child(_result_label)
	var btn := Button.new()
	btn.text = "Replay"
	btn.pressed.connect(func(): replay_requested.emit())
	vb.add_child(btn)
	cl.add_child(_result_panel)

func _sync_pool(pool: Array, root: Node3D, count: int, mesh: Mesh, mat: Material) -> void:
	while pool.size() < count:
		pool.append(_mesh(root, mesh, mat, Vector3.ZERO))
	for i in pool.size():
		pool[i].visible = i < count

## Entry duy nhat: ve lai theo state.
func apply_state(state: _SimState) -> void:
	if _cam == null:
		_ready()
	var pp: Vector3 = state.player.get("pos", Vector3.ZERO)
	_player.position = pp

	_lit_count = 0
	for i in _lantern_nodes.size():
		var n: Node3D = _lantern_nodes[i]
		var lit := false
		n.visible = i < state.lanterns.size()
		if i < state.lanterns.size():
			var d: Dictionary = state.lanterns[i]
			n.position = d["pos"]
			lit = d["lit"]
		if lit:
			_lit_count += 1
		(n.get_node("Body") as MeshInstance3D).material_override = _lantern_lit_mat if lit else _lantern_dim_mat
		(n.get_node("Light") as OmniLight3D).light_energy = 3.0 if lit else 0.0

	_sync_pool(_mote_pool, _mote_root, state.motes.size(), _mote_mesh, _mote_mat)
	for i in state.motes.size():
		_mote_pool[i].position = state.motes[i]["pos"] + Vector3(0, 0.6, 0)
	_sync_pool(_shade_pool, _shade_root, state.shades.size(), _shade_mesh, _shade_mat)
	for i in state.shades.size():
		var s: Dictionary = state.shades[i]
		var mi: MeshInstance3D = _shade_pool[i]
		var stunned: bool = s.get("state", "") == "stunned"
		mi.position = s["pos"] + Vector3(0, 0.8, 0)
		mi.material_override = _shade_stun_mat if stunned else _shade_mat
		mi.scale = Vector3(1.2, 0.6, 1.2) if stunned else Vector3.ONE

	# Sang tao: anh sang dao tang khi den duoc thap
	var k := float(_lit_count) / 5.0
	_env.ambient_light_energy = lerpf(0.35, 1.3, k)
	_env.ambient_light_color = Color(0.3, 0.2, 0.45).lerp(Color(0.9, 0.6, 0.35), k)
	_env.fog_light_color = Color(0.07, 0.04, 0.12).lerp(Color(0.3, 0.17, 0.12), k)

	_update_camera(pp)
	_update_hud(state, pp)

func _update_camera(pp: Vector3) -> void:
	var off := Vector3(sin(camera_yaw), 0, cos(camera_yaw)) * camera_distance + Vector3(0, camera_height, 0)
	_cam.position = pp + off
	_cam.look_at(pp + Vector3(0, 1.5, 0), Vector3.UP)

func _update_hud(state: _SimState, pp: Vector3) -> void:
	var p := state.player
	var cd: float = p.get("pulse_cd_left", 0.0)
	_hud_label.text = "Lua: %d    Mang: %d/%d    Den: %d/5    Diem: %d\nCon lai: %d s    Xung: %s" % [
		p.get("flames", 0), p.get("carried", 0), _Cfg.CARRY_CAPACITY, _lit_count,
		state.score, int(ceil(state.time_left_s())),
		"san sang" if cd <= 0.0 else "%.1fs" % cd]
	var hint := ""
	for d in state.lanterns:
		if not d["lit"] and (d["pos"] - pp).length() <= _Cfg.INTERACT_RADIUS:
			hint = "Nhan E de thap den (can %d dom dom)" % _Cfg.LANTERN_COST
			break
	_hint_label.text = hint
	_result_panel.visible = state.status != "playing"
	if state.status == "won":
		_result_label.text = "CHIEN THANG!\nDiem: %d" % state.score
	elif state.status == "lost":
		_result_label.text = "THUA (%s)\nDiem: %d" % [state.loss_reason, state.score]
