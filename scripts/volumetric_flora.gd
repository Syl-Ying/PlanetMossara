extends Node3D

var rng := RandomNumberGenerator.new()
var breathing_parts: Array[Node3D] = []


func _ready() -> void:
	rng.seed = 48201
	_build_canopy_groves()
	_build_fan_colonies()
	_build_membrane_fronds()
	_build_spore_cups()
	_build_ground_relief()


func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for part in breathing_parts:
		var phase: float = part.get_meta("phase")
		var base_rotation: Vector3 = part.get_meta("base_rotation")
		part.rotation = base_rotation + Vector3(
			sin(time * 0.31 + phase) * 0.018,
			cos(time * 0.19 + phase) * 0.014,
			sin(time * 0.27 + phase) * 0.022
		)


func get_mesh_count() -> int:
	return find_children("*", "MeshInstance3D", true, false).size()


func _material(color: Color, transparent := false, emission := Color.TRANSPARENT) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	material.metallic_specular = 0.16
	material.rim_enabled = true
	material.rim = 0.34
	material.rim_tint = 0.48
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission.a > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 0.22
	return material


func _build_canopy_groves() -> void:
	var trunk_material := _material(Color("342f3a"))
	var canopy_material := _material(Color("667684"))
	var underside_material := _material(Color("d0cec0"))
	var membrane_material := _material(Color(0.69, 0.42, 0.42, 0.78), true)
	var positions := [
		Vector3(-31, 0, -31), Vector3(-20, 0, -39), Vector3(-37, 0, -8),
		Vector3(29, 0, -36), Vector3(38, 0, -15), Vector3(23, 0, -27),
		Vector3(-43, 0, 18), Vector3(43, 0, 21), Vector3(30, 0, 38),
	]
	for index in range(positions.size()):
		var tree := Node3D.new()
		tree.name = "VolumetricHiHat_%02d" % index
		tree.position = positions[index]
		tree.rotation.y = rng.randf_range(-PI, PI)
		add_child(tree)

		var height := rng.randf_range(7.0, 12.5)
		var lean := Vector3(rng.randf_range(-0.7, 0.7), height, rng.randf_range(-0.7, 0.7))
		_add_segment(tree, Vector3.ZERO, lean, 0.11, 0.34, trunk_material, 9)
		for root_index in range(5):
			var root_angle := TAU * root_index / 5.0 + rng.randf_range(-0.25, 0.25)
			var root_end := Vector3(cos(root_angle) * 1.35, 0.05, sin(root_angle) * 1.35)
			_add_segment(tree, Vector3(0.0, 0.32, 0.0), root_end, 0.04, 0.22, trunk_material, 7)

		var branch_center := lean - Vector3(0.0, 0.42, 0.0)
		for branch_index in range(7):
			var angle := TAU * branch_index / 7.0
			var endpoint := lean + Vector3(cos(angle) * 2.1, -0.08, sin(angle) * 1.55)
			_add_segment(tree, branch_center, endpoint, 0.035, 0.09, trunk_material, 7)

		var canopy := MeshInstance3D.new()
		canopy.name = "LayeredCanopy"
		var canopy_mesh := SphereMesh.new()
		canopy_mesh.radius = 1.0
		canopy_mesh.height = 1.15
		canopy_mesh.radial_segments = 14
		canopy_mesh.rings = 5
		canopy.mesh = canopy_mesh
		canopy.material_override = canopy_material
		canopy.position = lean + Vector3(0.0, 0.22, 0.0)
		canopy.scale = Vector3(2.45, 0.42, 1.82)
		tree.add_child(canopy)

		var underside := MeshInstance3D.new()
		var underside_mesh := CylinderMesh.new()
		underside_mesh.top_radius = 1.68
		underside_mesh.bottom_radius = 2.02
		underside_mesh.height = 0.18
		underside_mesh.radial_segments = 14
		underside.mesh = underside_mesh
		underside.material_override = underside_material
		underside.position = lean - Vector3(0.0, 0.28, 0.0)
		underside.scale.z = 0.74
		tree.add_child(underside)

		for veil_index in range(3):
			var veil := MeshInstance3D.new()
			var veil_mesh := PrismMesh.new()
			veil_mesh.size = Vector3(0.46 + veil_index * 0.12, 1.2 + veil_index * 0.38, 0.14)
			veil.mesh = veil_mesh
			veil.material_override = membrane_material
			var veil_angle := -1.1 + veil_index * 1.05
			veil.position = lean + Vector3(cos(veil_angle) * 1.3, -0.95 - veil_index * 0.18, sin(veil_angle) * 0.95)
			veil.rotation_degrees = Vector3(rng.randf_range(-6.0, 6.0), rad_to_deg(-veil_angle), rng.randf_range(-7.0, 7.0))
			veil.set_meta("phase", float(index * 3 + veil_index))
			veil.set_meta("base_rotation", veil.rotation)
			breathing_parts.append(veil)
			tree.add_child(veil)


func _build_fan_colonies() -> void:
	var leaf_materials := [
		_material(Color("9ba995")),
		_material(Color("83958a")),
		_material(Color("bcc0a7")),
	]
	var rib_material := _material(Color("3f4a48"))
	for colony_index in range(14):
		var colony := Node3D.new()
		colony.name = "VolumetricFanColony_%02d" % colony_index
		var angle := colony_index * 2.37
		var distance := 8.5 + float((colony_index * 13) % 31)
		colony.position = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		colony.rotation.y = rng.randf_range(-PI, PI)
		add_child(colony)

		for leaf_index in range(4 + colony_index % 3):
			var side := -1.0 + leaf_index * 0.4
			var stalk_height := rng.randf_range(0.55, 1.25)
			var base := Vector3(side * 0.55, 0.05, rng.randf_range(-0.28, 0.28))
			var tip := base + Vector3(side * 0.38, stalk_height, rng.randf_range(-0.18, 0.18))
			_add_segment(colony, base, tip, 0.025, 0.07, rib_material, 7)
			var leaf := MeshInstance3D.new()
			var leaf_mesh := SphereMesh.new()
			leaf_mesh.radius = 0.5
			leaf_mesh.height = 0.62
			leaf_mesh.radial_segments = 10
			leaf_mesh.rings = 5
			leaf.mesh = leaf_mesh
			leaf.material_override = leaf_materials[(colony_index + leaf_index) % leaf_materials.size()]
			leaf.position = tip + Vector3(0.0, 0.24, 0.0)
			leaf.scale = Vector3(0.58 + leaf_index * 0.035, 0.9, 0.12)
			leaf.rotation_degrees = Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(-35.0, 35.0), side * -24.0)
			leaf.set_meta("phase", float(colony_index * 4 + leaf_index) * 0.43)
			leaf.set_meta("base_rotation", leaf.rotation)
			breathing_parts.append(leaf)
			colony.add_child(leaf)


func _build_membrane_fronds() -> void:
	var spine_material := _material(Color("4b3846"))
	var membrane_material := _material(Color(0.74, 0.39, 0.38, 0.83), true)
	var positions := [
		Vector3(-10, 0, -8), Vector3(12, 0, -15), Vector3(-18, 0, 9),
		Vector3(23, 0, 12), Vector3(-27, 0, -22), Vector3(31, 0, -4),
	]
	for index in range(positions.size()):
		var frond := Node3D.new()
		frond.name = "VolumetricMembrane_%02d" % index
		frond.position = positions[index]
		frond.rotation.y = rng.randf_range(-PI, PI)
		add_child(frond)

		var height := rng.randf_range(2.2, 3.6)
		var points := [
			Vector3.ZERO,
			Vector3(0.18, height * 0.34, 0.04),
			Vector3(-0.08, height * 0.68, 0.10),
			Vector3(0.22, height, 0.0),
		]
		for point_index in range(points.size() - 1):
			_add_segment(frond, points[point_index], points[point_index + 1], 0.025, 0.065, spine_material, 7)
		for blade_index in range(5):
			var blade := MeshInstance3D.new()
			var blade_mesh := PrismMesh.new()
			blade_mesh.size = Vector3(0.44 + blade_index * 0.08, 0.78, 0.12 + blade_index * 0.018)
			blade.mesh = blade_mesh
			blade.material_override = membrane_material
			blade.position = Vector3(
				(-1.0 if blade_index % 2 == 0 else 1.0) * (0.26 + blade_index * 0.08),
				0.72 + blade_index * height * 0.15,
				0.0
			)
			blade.rotation_degrees.z = (-1.0 if blade_index % 2 == 0 else 1.0) * (34.0 + blade_index * 3.0)
			blade.set_meta("phase", float(index * 5 + blade_index))
			blade.set_meta("base_rotation", blade.rotation)
			breathing_parts.append(blade)
			frond.add_child(blade)


func _build_spore_cups() -> void:
	var stalk_material := _material(Color("3c4a51"))
	var cup_material := _material(Color("7894a0"))
	var inside_material := _material(Color("28323b"), false, Color("42505a"))
	for colony_index in range(10):
		var colony := Node3D.new()
		colony.name = "SporeCupColony_%02d" % colony_index
		var angle := colony_index * 2.73 + 0.4
		var distance := 11.0 + float((colony_index * 9) % 24)
		colony.position = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		add_child(colony)
		for cup_index in range(3 + colony_index % 4):
			var x := (cup_index - 2) * 0.33
			var height := rng.randf_range(0.38, 0.92)
			_add_segment(colony, Vector3(x, 0.0, 0.0), Vector3(x * 1.08, height, rng.randf_range(-0.16, 0.16)), 0.018, 0.042, stalk_material, 6)
			var cup := MeshInstance3D.new()
			var cup_mesh := CylinderMesh.new()
			cup_mesh.top_radius = 0.18
			cup_mesh.bottom_radius = 0.08
			cup_mesh.height = 0.18
			cup_mesh.radial_segments = 9
			cup.mesh = cup_mesh
			cup.material_override = cup_material
			cup.position = Vector3(x * 1.08, height + 0.06, 0.0)
			colony.add_child(cup)
			var center := MeshInstance3D.new()
			var center_mesh := CylinderMesh.new()
			center_mesh.top_radius = 0.105
			center_mesh.bottom_radius = 0.105
			center_mesh.height = 0.012
			center_mesh.radial_segments = 9
			center.mesh = center_mesh
			center.material_override = inside_material
			center.position = cup.position + Vector3(0.0, 0.097, 0.0)
			colony.add_child(center)


func _build_ground_relief() -> void:
	var mound_materials := [
		_material(Color("62676b")),
		_material(Color("777873")),
		_material(Color("555c61")),
	]
	for index in range(26):
		var mound := MeshInstance3D.new()
		mound.name = "GroundMound_%02d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 1.1
		mesh.radial_segments = 9
		mesh.rings = 4
		mound.mesh = mesh
		mound.material_override = mound_materials[index % mound_materials.size()]
		var angle := index * 2.11
		var distance := 10.0 + float((index * 7) % 38)
		mound.position = Vector3(cos(angle) * distance, -0.30, sin(angle) * distance)
		mound.scale = Vector3(rng.randf_range(0.45, 1.6), rng.randf_range(0.18, 0.42), rng.randf_range(0.5, 1.9))
		mound.rotation.y = rng.randf_range(-PI, PI)
		add_child(mound)


func _add_segment(parent: Node3D, start: Vector3, end: Vector3, top_radius: float, bottom_radius: float, material: Material, radial_segments := 8) -> MeshInstance3D:
	var direction := end - start
	var segment := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = direction.length()
	mesh.radial_segments = radial_segments
	segment.mesh = mesh
	segment.material_override = material
	segment.position = (start + end) * 0.5
	segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
	parent.add_child(segment)
	return segment
