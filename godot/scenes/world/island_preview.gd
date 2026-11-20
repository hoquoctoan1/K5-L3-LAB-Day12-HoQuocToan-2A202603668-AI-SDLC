extends Node3D

const LANTERN_POSITIONS: Array[Vector3] = [
	Vector3(-7.0, 0.0, -3.0),
	Vector3(7.0, 0.0, -3.0),
	Vector3(0.0, 0.0, -8.0),
	Vector3(-7.0, 0.0, 4.0),
	Vector3(7.0, 0.0, 4.0),
]

func _ready() -> void:
	_build_environment()
	_build_cloud_sea()
	_build_island()
	_build_lanterns()
	_build_may()
	_build_preview_camera()

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.02, 0.085)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.18, 0.42)
	environment.ambient_light_energy = 0.8

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var moonlight := DirectionalLight3D.new()
	moonlight.name = "VioletMoonlight"
	moonlight.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	moonlight.light_color = Color(0.48, 0.37, 0.78)
	moonlight.light_energy = 1.1
	moonlight.shadow_enabled = true
	add_child(moonlight)

func _build_cloud_sea() -> void:
	var cloud_material := _make_material(Color(0.36, 0.29, 0.53))
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 1.0
	cloud_mesh.height = 2.0
	cloud_mesh.radial_segments = 24
	cloud_mesh.rings = 12
	_add_mesh(
		"CloudSea",
		cloud_mesh,
		cloud_material,
		Vector3(0.0, -18.0, 0.0),
		Vector3(120.0, 12.0, 120.0)
	)

	var cloud_puff_mesh := SphereMesh.new()
	cloud_puff_mesh.radius = 1.0
	cloud_puff_mesh.height = 2.0
	cloud_puff_mesh.radial_segments = 20
	cloud_puff_mesh.rings = 10
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var cloud_position := Vector3(
			cos(angle) * 15.0,
			-2.25 + float(index % 3) * 0.18,
			sin(angle) * 15.0
		)
		_add_mesh(
			"CloudPuff%02d" % index,
			cloud_puff_mesh,
			cloud_material,
			cloud_position,
			Vector3(2.4, 0.72, 1.7)
		)

func _build_island() -> void:
	var grass_material := _make_material(Color(0.13, 0.25, 0.20))
	var rock_material := _make_material(Color(0.12, 0.09, 0.20))
	_add_mesh(
		"IslandTop",
		_cylinder_mesh(12.0, 11.5, 1.4),
		grass_material,
		Vector3(0.0, -0.7, 0.0)
	)
	_add_mesh(
		"FloatingRock",
		_cylinder_mesh(11.45, 7.7, 3.2),
		rock_material,
		Vector3(0.0, -2.3, 0.0)
	)

func _build_lanterns() -> void:
	var post_material := _make_material(Color(0.20, 0.12, 0.12))
	var gold_material := _make_material(
		Color(1.0, 0.54, 0.16),
		Color(1.0, 0.38, 0.08),
		2.0
	)
	var flame_material := _make_material(
		Color(1.0, 0.77, 0.32),
		Color(1.0, 0.54, 0.14),
		3.0
	)

	for index in range(LANTERN_POSITIONS.size()):
		var lantern := Node3D.new()
		lantern.name = "LanternPreview%02d" % (index + 1)
		lantern.position = LANTERN_POSITIONS[index]
		add_child(lantern)

		_add_mesh_to(
			lantern,
			"Base",
			_cylinder_mesh(0.48, 0.62, 0.20, 24),
			post_material,
			Vector3(0.0, 0.10, 0.0)
		)
		_add_mesh_to(
			lantern,
			"Post",
			_cylinder_mesh(0.12, 0.16, 1.65, 16),
			post_material,
			Vector3(0.0, 0.95, 0.0)
		)
		_add_mesh_to(
			lantern,
			"LanternHousing",
			_sphere_mesh(),
			gold_material,
			Vector3(0.0, 2.05, 0.0),
			Vector3(0.56, 0.78, 0.56)
		)
		_add_mesh_to(
			lantern,
			"LanternFlame",
			_sphere_mesh(),
			flame_material,
			Vector3(0.0, 2.05, 0.0),
			Vector3(0.30, 0.48, 0.30)
		)

		var lamp_light := OmniLight3D.new()
		lamp_light.name = "PreviewGlow"
		lamp_light.position = Vector3(0.0, 2.05, 0.0)
		lamp_light.light_color = Color(1.0, 0.56, 0.20)
		lamp_light.light_energy = 1.0
		lamp_light.omni_range = 6.0
		lantern.add_child(lamp_light)

		var label := Label3D.new()
		label.name = "PreviewLabel"
		label.text = "ĐÈN %d" % (index + 1)
		label.position = Vector3(0.0, 3.0, 0.0)
		label.font_size = 24
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lantern.add_child(label)

func _build_may() -> void:
	var may := Node3D.new()
	may.name = "MayPlaceholder"
	add_child(may)

	var robe_material := _make_material(Color(0.36, 0.70, 0.67))
	var skin_material := _make_material(Color(0.95, 0.75, 0.61))
	var hat_material := _make_material(Color(0.47, 0.54, 0.31))
	var lantern_material := _make_material(
		Color(1.0, 0.72, 0.26),
		Color(1.0, 0.50, 0.12),
		2.5
	)

	_add_mesh_to(
		may,
		"Robe",
		_capsule_mesh(0.42, 1.35),
		robe_material,
		Vector3(0.0, 0.68, 0.0)
	)
	_add_mesh_to(
		may,
		"Head",
		_sphere_mesh(),
		skin_material,
		Vector3(0.0, 1.46, 0.0),
		Vector3(0.34, 0.36, 0.34)
	)
	_add_mesh_to(
		may,
		"ConicalHat",
		_cylinder_mesh(0.02, 0.70, 0.30, 24),
		hat_material,
		Vector3(0.0, 1.83, 0.0)
	)
	_add_mesh_to(
		may,
		"HangingLantern",
		_sphere_mesh(),
		lantern_material,
		Vector3(0.42, 1.12, -0.10),
		Vector3(0.15, 0.20, 0.15)
	)

	var name_label := Label3D.new()
	name_label.name = "PlaceholderName"
	name_label.text = "MÂY"
	name_label.position = Vector3(0.0, 2.35, 0.0)
	name_label.font_size = 30
	name_label.outline_size = 7
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	may.add_child(name_label)

func _build_preview_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector3(0.0, 16.0, 31.0)
	camera.fov = 52.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.make_current()

func _add_mesh(
	node_name: String,
	mesh: Mesh,
	material: Material,
	position: Vector3,
	mesh_scale: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	return _add_mesh_to(self, node_name, mesh, material, position, mesh_scale)

func _add_mesh_to(
	parent: Node3D,
	node_name: String,
	mesh: Mesh,
	material: Material,
	position: Vector3,
	mesh_scale: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.scale = mesh_scale
	parent.add_child(instance)
	return instance

func _make_material(
	color: Color,
	emission_color: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_energy
	return material

func _cylinder_mesh(
	top_radius: float,
	bottom_radius: float,
	height: float,
	segments: int = 48
) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh

func _sphere_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return mesh

func _capsule_mesh(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.rings = 8
	return mesh
