extends Node3D
## View thuan (P2-D1): ve SimState v2 + map. Khong anh huong Sim. Entry: apply_state(state), play_event(ev).
const _Cfg = preload("res://src/core/game_config.gd")
const _HudL = preload("res://src/adapters/view/ui/hud_logic.gd")
const MapBuilder = preload("res://src/core/maps/map_builder.gd")

const SKY := Color("#0E1430")
const MIST := Color("#1B2350")
const GRASS := Color("#2F5D50")
const SAND := Color("#C9B48A")
const WOOD := Color("#6B4A2F")
const CLOUD := Color("#12384A")
const LANT_LIT := Color("#FFB347")
const LANT_CORE := Color("#FFE9B0")
const LANT_OFF := Color("#5B5F6E")
const MOTE_CORE := Color("#FFF6C2")
const MOTE_HALO := Color("#FFE58A")
const SHADE_BODY := Color("#120A1A")
const SHADE_LINE := Color("#7A3CFF")
const SHADE_STUN := Color("#3A3450")
const OUTFIT := Color("#E8E2D0")
const RED := Color("#C8102E")
const GOLD := Color("#F2C14E")
const DRIFT := Color("#8FA3B8")

## v1.2 che do mu mau (TICKET-03 muc 6): main.gd gan tu Settings.colorblind.
var colorblind: bool = false
var camera_yaw: float = 0.0
var camera_distance: float = 9.0
var camera_height: float = 5.0
## Chi view: neu khac null thi camera nhin vao diem nay (anh bao cao)
var focus_override = null
var camera: Camera3D

var _fx_on: bool = DisplayServer.get_name() != "headless"
var _env: Environment
var _world: Node3D
var _map_key: String = ""
var _player: Node3D
var _scarf: Node3D
var _charm_icon: Node3D
var _lanterns: Array = []
var _lantern_rings: Array = []
var _charm_nodes: Array = []
var _mote_pool: Array = []
var _shade_pool: Array = []
var _drifter_pool: Array = []
var _mote_root: Node3D
var _shade_root: Node3D
var _drifter_root: Node3D
var _fx_root: Node3D
var _leaves: Array = []
var _ghosts: Array = []
var _flash: ColorRect
var _wind_label: Label
var _time: float = 0.0
var _face: float = 0.0
var _mats := {}
var _last_pos: Vector3 = Vector3.ZERO
var _last_state = null

func _ready() -> void:
	_build_base()

func _mat(c: Color, emis: float = 0.0, ec: Color = Color.BLACK, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%s_%s_%s_%s" % [c.to_html(), emis, ec.to_html(), unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = ec
		m.emission_energy_multiplier = emis
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
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

func _cyl(rt: float, rb: float, h: float, seg: int = 32) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	return c

func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

# ---------------- base (khong doi theo dem) ----------------
func _build_base() -> void:
	if _env != null:
		return
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = SKY
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color("#8FA0D8")
	_env.ambient_light_energy = 0.15
	_env.fog_enabled = true
	_env.fog_light_color = MIST
	_env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-50, -30, 0)
	moon.light_color = Color(0.55, 0.6, 0.95)
	moon.light_energy = 0.55
	add_child(moon)
	_world = Node3D.new()
	add_child(_world)
	_mote_root = Node3D.new()
	add_child(_mote_root)
	_shade_root = Node3D.new()
	add_child(_shade_root)
	_drifter_root = Node3D.new()
	add_child(_drifter_root)
	_fx_root = Node3D.new()
	add_child(_fx_root)
	_player = _make_player()
	add_child(_player)
	camera = Camera3D.new()
	camera.fov = 65.0
	camera.far = 400.0
	add_child(camera)
	camera.current = true
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.2, 0.2, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_flash)
	_wind_label = Label.new()
	_wind_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wind_label.position = Vector2(-150, 80)
	_wind_label.custom_minimum_size = Vector2(300, 0)
	_wind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wind_label.add_theme_font_size_override("font_size", 24)
	_wind_label.add_theme_color_override("font_color", DRIFT)
	_wind_label.add_theme_color_override("font_outline_color", SKY)
	_wind_label.add_theme_constant_override("outline_size", 6)
	cl.add_child(_wind_label)
	if _fx_on:
		for i in 28:
			var leaf := _mesh(self, _box(0.25, 0.02, 0.14), _mat(Color("#7FA66A") if i % 2 == 0 else SAND, 0.4, Color("#7FA66A")), Vector3.ZERO)
			leaf.visible = false
			_leaves.append(leaf)
		for i in 5:
			var g := _mesh(self, _sphere(0.5), _mat(Color(1, 0.9, 0.6, 0.35), 1.5, LANT_CORE, true), Vector3.ZERO)
			g.visible = false
			_ghosts.append(g)

func _make_player() -> Node3D:
	var p := Node3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.5
	_mesh(p, body, _mat(OUTFIT), Vector3(0, 0.85, 0))
	_mesh(p, _sphere(0.3), _mat(Color(0.9, 0.72, 0.58)), Vector3(0, 1.8, 0))
	_mesh(p, _cyl(0.0, 0.75, 0.55, 16), _mat(WOOD), Vector3(0, 2.2, 0))
	_mesh(p, _cyl(0.43, 0.43, 0.12, 16), _mat(RED), Vector3(0, 1.5, 0))
	_scarf = _mesh(p, _box(0.18, 0.08, 0.7), _mat(RED), Vector3(0, 1.45, -0.55))
	_mesh(p, _sphere(0.2), _mat(LANT_LIT, 3.0, LANT_LIT), Vector3(0.5, 1.05, 0.25))
	var l := OmniLight3D.new()
	l.position = Vector3(0.5, 1.05, 0.25)
	l.light_color = LANT_LIT
	l.light_energy = 1.2
	l.omni_range = 9.0
	p.add_child(l)
	_charm_icon = Node3D.new()
	_mesh(_charm_icon, _box(0.34, 0.46, 0.04), _mat(GOLD), Vector3.ZERO)
	_mesh(_charm_icon, _box(0.26, 0.38, 0.06), _mat(RED), Vector3.ZERO)
	_charm_icon.position = Vector3(-0.55, 1.5, 0.1)
	_charm_icon.visible = false
	p.add_child(_charm_icon)
	return p

# ---------------- the gioi theo ban do ----------------
func _clear(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()

func _wedge(r_min: float, r_max: float, y0: float, y1: float, a0: float, a1: float, mat: Material) -> MeshInstance3D:
	# lang tru ban nguyet/vanh: goc a tu +X, x=r cos a, z=r sin a
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var n := 24
	var quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3):
		for v in [a, b, c, a, c, d]:
			st.add_vertex(v)
	for i in n:
		var t0 := deg_to_rad(lerpf(a0, a1, float(i) / n))
		var t1 := deg_to_rad(lerpf(a0, a1, float(i + 1) / n))
		var c0 := Vector2(cos(t0), sin(t0))
		var c1 := Vector2(cos(t1), sin(t1))
		var o0 := Vector3(c0.x * r_max, 0, c0.y * r_max)
		var o1 := Vector3(c1.x * r_max, 0, c1.y * r_max)
		var i0 := Vector3(c0.x * r_min, 0, c0.y * r_min)
		var i1 := Vector3(c1.x * r_min, 0, c1.y * r_min)
		var up := Vector3(0, y1, 0)
		var dn := Vector3(0, y0, 0)
		quad.call(i0 + up, i1 + up, o1 + up, o0 + up)
		quad.call(o0 + dn, o1 + dn, o1 + up, o0 + up)
		if r_min > 0.01:
			quad.call(i0 + dn, i1 + dn, i1 + up, i0 + up)
	if absf(a1 - a0) < 359.0:
		for t in [a0, a1]:
			var c := Vector2(cos(deg_to_rad(t)), sin(deg_to_rad(t)))
			quad.call(Vector3(c.x * r_min, y0, c.y * r_min), Vector3(c.x * r_max, y0, c.y * r_max),
				Vector3(c.x * r_max, y1, c.y * r_max), Vector3(c.x * r_min, y1, c.y * r_min))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m: StandardMaterial3D = (mat as StandardMaterial3D).duplicate()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	_world.add_child(mi)
	return mi

func _build_map(map: Dictionary, st) -> void:
	_clear(_world)
	_lanterns.clear()
	_lantern_rings.clear()
	_charm_nodes.clear()
	# bien may
	var sea := _mesh(_world, _box(900, 0.2, 900), _mat(CLOUD, 0.35, CLOUD), Vector3(0, -7.0, 0))
	sea.name = "CloudSea"
	for i in 14:
		var a := float(i) * 0.9
		var r := 55.0 + 13.0 * (i % 5)
		_mesh(_world, _sphere(9.0 + (i % 3) * 3.0, 6.0), _mat(Color("#1B4A5E"), 0.3, CLOUD), Vector3(cos(a) * r * 1.4, -6.0, sin(a) * r))
	for isl in map.get("islands", []):
		var c: Vector3 = isl["center"]
		var r: float = isl["radius"]
		_mesh(_world, _cyl(r, r, 1.0), _mat(GRASS), c + Vector3(0, -0.5, 0))
		_mesh(_world, _cyl(r + 0.4, r + 0.4, 0.3), _mat(SAND), c + Vector3(0, -1.0, 0))
		_mesh(_world, _cyl(r, r * 0.3, 14.0), _mat(WOOD.darkened(0.3)), c + Vector3(0, -8.0, 0))
	for t in map.get("tiers", []):
		if t.get("kind", "") == "island":
			continue
		var y: float = t["y"]
		var kind: String = t["kind"]
		var rmin: float = t.get("r_min", 0.0)
		var rmax: float = t.get("r_max", 8.0)
		var half: bool = t.get("z_positive_only", false)
		var mt := _mat(GRASS.lightened(0.08 * float(t["tier"])))
		_wedge(rmin, rmax, 0.0, y, 0.0, 180.0 if half else 360.0, mt)
	for rp in map.get("ramps", []):
		var d: Vector3 = rp["dir"]
		var foot := d * float(rp["foot_r"]) + Vector3(0, float(rp["foot_y"]), 0)
		var top := d * float(rp["top_r"]) + Vector3(0, float(rp["top_y"]), 0)
		var fw := (top - foot)
		var ln := fw.length()
		fw = fw.normalized()
		var rt := fw.cross(Vector3.UP).normalized()
		var up2 := rt.cross(fw).normalized()
		var rb := _mesh(_world, _box(float(rp["width"]), 0.3, ln), _mat(SAND), (foot + top) * 0.5 - up2 * 0.15)
		rb.basis = Basis(rt, up2, fw)
	var br: Dictionary = map.get("bridge", {})
	if not br.is_empty():
		var x0: float = br["x_min"]
		var x1: float = br["x_max"]
		var zh: float = br["z_half"]
		_mesh(_world, _box(x1 - x0, 0.4, zh * 2.0), _mat(WOOD), Vector3((x0 + x1) * 0.5, float(br["y"]) - 0.2, 0))
		for k in 7:
			_mesh(_world, _box(0.2, 0.1, zh * 2.0 + 0.2), _mat(WOOD.darkened(0.35)), Vector3(x0 + (x1 - x0) * (k + 0.5) / 7.0, float(br["y"]) + 0.02, 0))
	for jp in map.get("jump_pads", []):
		var pp: Vector3 = jp["pos"]
		var rad: float = maxf(float(jp["radius"]), 1.0) + 0.4
		_mesh(_world, _cyl(rad, rad, 0.15, 24), _mat(MOTE_HALO, 1.2, LANT_LIT), pp + Vector3(0, 0.07, 0))
		var dir: Vector3 = jp["direction"]
		var cone := _mesh(_world, _cyl(0.0, 0.5, 0.9, 12), _mat(LANT_LIT, 2.0, LANT_LIT), pp + Vector3(0, 0.7, 0))
		cone.basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(90))
	var bt: Dictionary = map.get("bell_tower", {})
	if not bt.is_empty():
		var c: Vector3 = bt["center"]
		var rr: float = bt["radius"]
		var h: float = bt["height"]
		_mesh(_world, _cyl(rr, rr * 1.15, h), _mat(WOOD), c + Vector3(0, h * 0.5, 0))
		_mesh(_world, _cyl(0.0, rr * 1.5, 2.2, 8), _mat(WOOD.darkened(0.3)), c + Vector3(0, h + 1.1, 0))
		_mesh(_world, _sphere(0.6), _mat(GOLD, 1.5, GOLD), c + Vector3(0, h - 1.2, rr + 0.3))
	# den
	var n_l: int = st.lanterns.size()
	for i in n_l:
		var ln := _make_lantern()
		_world.add_child(ln)
		_lanterns.append(ln)
	for i in st.charms.size():
		var ch := Node3D.new()
		_mesh(ch, _box(0.7, 0.95, 0.05), _mat(GOLD, 0.5, GOLD), Vector3.ZERO)
		_mesh(ch, _box(0.55, 0.8, 0.08), _mat(RED, 0.5, RED), Vector3.ZERO)
		_world.add_child(ch)
		_charm_nodes.append(ch)

func _make_lantern() -> Node3D:
	var n := Node3D.new()
	_mesh(n, _cyl(0.12, 0.18, 2.2, 10), _mat(WOOD), Vector3(0, 1.1, 0))
	var body := _mesh(n, _box(0.9, 1.0, 0.9), _mat(LANT_OFF), Vector3(0, 2.7, 0))
	body.name = "Body"
	var core := _mesh(n, _sphere(0.28), _mat(LANT_CORE, 4.0, LANT_CORE, true), Vector3(0, 2.7, 0))
	core.name = "Core"
	# v1.2: vet rach tren giay (chi hien khi den tat) - phan biet sang/tat khong can mau
	var tear := Node3D.new()
	tear.name = "Tear"
	tear.position = Vector3(0, 2.7, 0.46)
	n.add_child(tear)
	for k in 3:
		var sgn := 1.0 if k % 2 == 0 else -1.0
		var seg := _mesh(tear, _box(0.08, 0.32, 0.02), _mat(Color("#1A1C24")), Vector3(-0.12 + 0.12 * k, 0.06 * sgn, 0))
		seg.rotation.z = 0.6 * sgn
	# v1.2: thanh dau tren den dang sang
	var bar_bg := _mesh(n, _box(1.0, 0.1, 0.1), _mat(Color("#2A2A33")), Vector3(0, 3.55, 0))
	bar_bg.name = "FuelBg"
	var bar := _mesh(n, _box(1.0, 0.12, 0.12), _mat(LANT_LIT, 2.0, LANT_LIT, true), Vector3(0, 3.55, 0))
	bar.name = "FuelBar"
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 2.7, 0)
	light.light_color = LANT_LIT
	light.omni_range = 16.0
	light.light_energy = 0.0
	n.add_child(light)
	var ring := _mesh(n, _cyl(_Cfg.SAFE_RADIUS, _Cfg.SAFE_RADIUS, 0.03, 40), _mat(Color(1, 0.7, 0.3, 0.10), 0.0, Color.BLACK, true), Vector3(0, 0.04, 0))
	ring.name = "Ring"
	(ring.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return n

func _make_shade() -> Node3D:
	var n := Node3D.new()
	var body := _mesh(n, _sphere(0.9, 1.6), _mat(SHADE_BODY, 0.5, SHADE_LINE), Vector3(0, 0.8, 0))
	body.name = "Body"
	var ol := _mesh(n, _sphere(0.9, 1.6), _mat(SHADE_LINE, 0.0, Color.BLACK, true), Vector3(0, 0.8, 0))
	var om: StandardMaterial3D = (ol.material_override as StandardMaterial3D).duplicate()
	om.cull_mode = BaseMaterial3D.CULL_FRONT
	ol.material_override = om
	ol.scale = Vector3(1.1, 1.1, 1.1)
	ol.name = "Outline"
	for sx in [-0.3, 0.3]:
		var eye := _mesh(n, _sphere(0.1), _mat(SHADE_LINE, 2.0, SHADE_LINE, true), Vector3(sx, 1.0, 0.75))
		eye.name = "Eye" if sx < 0.0 else "Eye2"
	return n

func _make_drifter() -> Node3D:
	var n := Node3D.new()
	for i in 3:
		var r := _mesh(n, _box(0.28, 1.5, 0.03), _mat(DRIFT, 0.5, DRIFT), Vector3((i - 1) * 0.22, 0, 0))
		r.name = "R%d" % i
	return n

# ---------------- cap nhat ----------------
func _sync_pool(pool: Array, root: Node3D, count: int, maker: Callable) -> void:
	while pool.size() < count:
		var n: Node3D = maker.call()
		root.add_child(n)
		pool.append(n)
	for i in pool.size():
		pool[i].visible = i < count

func apply_state(state) -> void:
	if camera == null:
		_build_base()
	_last_state = state
	var map: Dictionary = state.map if not state.map.is_empty() else MapBuilder.build(state.night)
	var key := "%d|%s|%d|%d" % [state.night, str(map.get("name", "")), state.lanterns.size(), state.charms.size()]
	if key != _map_key:
		_map_key = key
		_build_map(map, state)
	var p: Dictionary = state.player
	var pp: Vector3 = p.get("pos", Vector3.ZERO)
	_last_pos = pp
	var falling: int = int(p.get("fall_wait_ticks", 0))
	_player.visible = falling <= 0
	_player.position = pp
	var fc: Vector2 = p.get("facing", Vector2(0, 1))
	if fc.length() > 0.01:
		_face = lerp_angle(_face, atan2(fc.x, fc.y), 0.3)
	_player.rotation.y = _face
	if int(p.get("invuln_ticks", 0)) > 0 and (state.tick / 5) % 2 == 0:
		_player.visible = false
	_charm_icon.visible = int(p.get("charm_ticks", 0)) > 0

	var lit := 0
	for i in _lanterns.size():
		var n: Node3D = _lanterns[i]
		var d: Dictionary = state.lanterns[i]
		n.position = d["pos"]
		var on: bool = d["lit"]
		if on:
			lit += 1
		# v1.2: fuel 0..100; sap het dau (< 30) nhap nhay 1 Hz va mat vung an toan
		var fuel: float = SimState.fuel_of(d)
		var low: bool = SimState.is_low_fuel(d)
		var glow: bool = on and (not low or _HudL.fuel_blink_on(_time))
		var body_n := n.get_node("Body") as MeshInstance3D
		body_n.material_override = _mat(LANT_LIT, 3.0, LANT_LIT) if glow else (_mat(LANT_LIT.darkened(0.5)) if on else _mat(LANT_OFF))
		body_n.scale = Vector3.ONE if on else Vector3(1.0, 0.8, 1.0)   # den tat xep 20%
		(n.get_node("Tear") as Node3D).visible = not on
		(n.get_node("Core") as MeshInstance3D).visible = glow
		(n.get_node("Ring") as MeshInstance3D).visible = SimState.has_safe_zone(d)
		(n.get_node("Light") as OmniLight3D).light_energy = (3.0 if glow else 1.0) if on else 0.0
		var bar := n.get_node("FuelBar") as MeshInstance3D
		var k_f := clampf(fuel / 100.0, 0.0, 1.0)
		bar.visible = on and (not low or _HudL.fuel_blink_on(_time))
		bar.scale = Vector3(maxf(k_f, 0.001), 1.0, 1.0)
		bar.position.x = -0.5 * (1.0 - k_f)
		var wc: Color = _HudL.warn_color(colorblind)
		bar.material_override = _mat(wc, 2.0, wc, true) if low else _mat(LANT_LIT, 2.0, LANT_LIT, true)
		(n.get_node("FuelBg") as MeshInstance3D).visible = on
	for i in _charm_nodes.size():
		var c: Dictionary = state.charms[i]
		var cn: Node3D = _charm_nodes[i]
		cn.visible = c.get("available", true)
		cn.position = c["pos"] + Vector3(0, 1.0 + 0.15 * sin(_time * 2.0 + i), 0)
		cn.rotation.y = _time * 1.5

	_sync_pool(_mote_pool, _mote_root, state.motes.size(), func():
		var n := Node3D.new()
		_mesh(n, _sphere(0.18), _mat(MOTE_CORE, 3.0, MOTE_CORE, true), Vector3.ZERO)
		var h := _mesh(n, _sphere(0.34), _mat(Color(MOTE_HALO, 0.28), 0.0, Color.BLACK, true), Vector3.ZERO)
		(h.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		h.name = "Halo"
		return n)
	for i in state.motes.size():
		var m: Dictionary = state.motes[i]
		var mn: Node3D = _mote_pool[i]
		mn.position = m["pos"] + Vector3(0, 0.6 + 0.08 * sin(_time * 3.0 + i), 0)
		var dropped: bool = m.get("kind", "random") == "dropped"
		mn.scale = Vector3.ONE * (1.3 if dropped else 1.0)
		if dropped and int(m.get("ttl_ticks", -1)) >= 0 and int(m["ttl_ticks"]) < 60:
			mn.visible = (state.tick / 4) % 2 == 0

	_sync_pool(_shade_pool, _shade_root, state.shades.size(), _make_shade)
	var sline: Color = _HudL.shade_line_color(colorblind)
	for i in state.shades.size():
		var s: Dictionary = state.shades[i]
		var sn: Node3D = _shade_pool[i]
		var ss: String = s.get("state", "wander")
		sn.position = s["pos"]
		var body := sn.get_node("Body") as MeshInstance3D
		match ss:
			"stunned":
				body.material_override = _mat(SHADE_STUN, 0.2, SHADE_STUN)
				sn.scale = Vector3(1.25, 0.6, 1.25)
			"spawning":
				body.material_override = _mat(SHADE_BODY, 0.5, sline)
				sn.scale = Vector3.ONE * 0.5
			"recoil":
				body.material_override = _mat(SHADE_BODY, 1.2, sline)
				sn.scale = Vector3(0.9, 1.2, 0.9)
			"chase":
				body.material_override = _mat(SHADE_BODY, 1.0, sline)
				sn.scale = Vector3.ONE * 1.1
			_:
				body.material_override = _mat(SHADE_BODY, 0.5, sline)
				sn.scale = Vector3.ONE
		sn.get_node("Outline").visible = ss != "stunned"
		var olm: StandardMaterial3D = (sn.get_node("Outline") as MeshInstance3D).material_override
		if olm.albedo_color != sline:
			olm.albedo_color = sline
		for en in ["Eye", "Eye2"]:
			(sn.get_node(en) as MeshInstance3D).material_override = _mat(sline, 2.0, sline, true)
		if ss == "drain":
			sn.scale = Vector3(1.15, 0.85, 1.15)

	_sync_pool(_drifter_pool, _drifter_root, state.drifters.size(), _make_drifter)
	for i in state.drifters.size():
		var dd: Dictionary = state.drifters[i]
		var dn: Node3D = _drifter_pool[i]
		var ds: String = dd.get("state", "idle")
		dn.visible = ds != "removed"
		dn.position = dd["pos"] + Vector3(0, 1.3 + 0.2 * sin(_time * 2.0 + i), 0)
		var sp := 6.0 if ds == "flee" else (4.0 if ds == "chase" else 1.5)
		for k in 3:
			var r: Node3D = dn.get_node("R%d" % k)
			r.rotation.z = 0.5 * sin(_time * sp + k * 1.3)
			r.rotation.x = 0.4 * sin(_time * sp * 0.8 + k)
		dn.scale = Vector3(1, 1.5, 1) if ds == "chase" else Vector3.ONE

	# anh sang: 0.15 + 0.55 * (den sang / tong den)
	var k := float(lit) / maxf(float(_lanterns.size()), 1.0)
	_env.ambient_light_energy = 0.15 + 0.55 * k
	_env.ambient_light_color = Color("#8FA0D8").lerp(Color("#FFC890"), k)
	_env.fog_light_color = MIST.lerp(Color("#4A3340"), k)

	_update_wind(state, pp)
	_update_camera(pp)

func _update_wind(state, pp: Vector3) -> void:
	var w: Dictionary = state.wind
	var active: bool = w.get("active", false)
	var warn: bool = int(w.get("warn_ticks", 0)) > 0
	_wind_label.text = "GIÓ MẠNH" if active else ("Gió sắp nổi…" if warn else "")
	if not _fx_on:
		return
	var dir := Vector2.from_angle(deg_to_rad(float(w.get("dir_deg", 0.0))))
	var show := active or warn
	for i in _leaves.size():
		var lf: Node3D = _leaves[i]
		lf.visible = show and (active or i < 10)
		if not show:
			continue
		var spd := 14.0 if active else 4.0
		var along := fposmod(_time * spd + float(i) * 7.3, 40.0) - 20.0
		var side := (float((i * 37) % 21) - 10.0) * 1.2
		var h := 0.5 + float((i * 13) % 8) * 0.7
		lf.position = pp + Vector3(dir.x * along - dir.y * side, h + 0.3 * sin(_time * 3.0 + i), dir.y * along + dir.x * side)
		lf.rotation = Vector3(_time * 2.0 + i, -atan2(dir.y, dir.x), _time * 3.0)

func _update_camera(pp: Vector3) -> void:
	var tgt: Vector3 = focus_override if focus_override != null else pp
	var off := Vector3(sin(camera_yaw), 0, cos(camera_yaw)) * camera_distance + Vector3(0, camera_height, 0)
	camera.position = tgt + off
	camera.look_at(tgt + Vector3(0, 1.5 if focus_override == null else 0.0, 0), Vector3.UP)

func _process(delta: float) -> void:
	_time += delta
	if not _fx_on:
		return
	if _flash.color.a > 0.0:
		_flash.color.a = maxf(0.0, _flash.color.a - delta * 1.6)
	for c in _fx_root.get_children():
		var life: float = c.get_meta("life", 0.0) + delta
		var dur: float = c.get_meta("dur", 0.4)
		c.set_meta("life", life)
		var t := clampf(life / dur, 0.0, 1.0)
		if c.has_meta("grow"):
			c.scale = Vector3.ONE * lerpf(0.2, float(c.get_meta("grow")), t)
		if c.has_meta("rise"):
			c.position.y += delta * 3.0
		var mat := (c as MeshInstance3D).material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 0.5 * (1.0 - t)
		if t >= 1.0:
			c.queue_free()
	# vet lướt (chi view, doc state)
	var dashing := _last_state != null and int(_last_state.player.get("dash_ticks_left", 0)) > 0
	for i in _ghosts.size():
		var g: Node3D = _ghosts[i]
		g.visible = dashing
		if dashing:
			var back := Vector2(_last_state.player.get("dash_dir", Vector2.ZERO))
			g.position = _last_pos + Vector3(-back.x * 0.7 * (i + 1), 1.0, -back.y * 0.7 * (i + 1))
			g.scale = Vector3.ONE * (1.0 - 0.15 * i)

func _ring_fx(pos: Vector3, radius: float, col: Color, dur: float, rise: bool = false) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, 0.5)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere(1.0)
	mi.material_override = m
	mi.position = pos
	mi.set_meta("grow", radius)
	mi.set_meta("dur", dur)
	if rise:
		mi.set_meta("rise", true)
	_fx_root.add_child(mi)

## Hieu ung theo event Sim (chi hinh anh).
func play_event(ev: Dictionary) -> void:
	if not _fx_on:
		return
	match ev.get("name", ""):
		"pulse":
			_ring_fx(_last_pos + Vector3(0, _Cfg.PULSE_CENTER_Y, 0), _Cfg.PULSE_RADIUS, MOTE_HALO, 0.4)
		"player_hit":
			if ev.get("data", {}).get("by", "") == "fall":
				_ring_fx(_last_pos, 3.0, Color("#BFD6E6"), 0.7, true)
				_flash.color = Color(0.05, 0.2, 0.35, 0.5)
			else:
				_flash.color = Color(1.0, 0.2, 0.25, 0.4)
		"lantern_lit":
			_ring_fx(_last_pos + Vector3(0, 1.5, 0), 3.0, LANT_LIT, 0.6)
		"charm_picked":
			_ring_fx(_last_pos + Vector3(0, 1.0, 0), 2.0, RED, 0.5)
