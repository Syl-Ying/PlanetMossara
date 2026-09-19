class_name LivingOrganism
extends Node3D

enum Species { GLOW_REED, BURROW_GRAZER, VEIL_STALKER }
enum Behavior { ROOTED, WANDERING, FORAGING, FEEDING, HUNTING, FLEEING, ATTRACTED }

const DISPLAY_NAMES := {
	Species.GLOW_REED: "Spore Tree",
	Species.BURROW_GRAZER: "Pigoid",
	Species.VEIL_STALKER: "Sterq Serpent",
}

var organism_id := 0
var species := Species.GLOW_REED
var behavior := Behavior.ROOTED
var energy := 100.0
var sim_position := Vector2.ZERO
var move_velocity := Vector2.ZERO
var body_visual: Node3D
var body_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var base_height := 0.0


func configure(new_id: int, new_species: int, start_position: Vector2, start_energy: float) -> void:
	organism_id = new_id
	species = new_species
	sim_position = start_position
	energy = start_energy
	behavior = Behavior.ROOTED if species == Species.GLOW_REED else Behavior.WANDERING
	_build_visual()
	_sync_transform()


func get_display_name() -> String:
	return DISPLAY_NAMES[species]


func _make_toon(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	material.metallic_specular = 0.13
	material.rim_enabled = true
	material.rim = 0.32
	material.rim_tint = 0.5
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _build_visual() -> void:
	body_visual = Node3D.new()
	body_visual.name = "Visual"
	add_child(body_visual)

	if species == Species.GLOW_REED:
		_build_spore_tree()
	elif species == Species.BURROW_GRAZER:
		_build_pigoid()
	else:
		_build_sterq_serpent()


func _build_spore_tree() -> void:
	base_height = 1.2
	body_material = _make_toon(Color("424f4b"))
	accent_material = _make_toon(Color(0.81, 0.47, 0.40, 0.72), true)
	accent_material.emission_enabled = true
	accent_material.emission = Color("6f3a39")
	accent_material.emission_energy_multiplier = 0.26
	for stem_index in range(3):
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = 0.045
		stem_mesh.bottom_radius = 0.11
		stem_mesh.height = 1.45 + stem_index * 0.34
		stem_mesh.radial_segments = 7
		stem.mesh = stem_mesh
		stem.material_override = body_material
		stem.position = Vector3((stem_index - 1) * 0.24, stem_mesh.height * 0.5, 0.0)
		stem.rotation_degrees.z = (stem_index - 1) * -9.0
		body_visual.add_child(stem)

		var sac := MeshInstance3D.new()
		var sac_mesh := SphereMesh.new()
		sac_mesh.radius = 0.28 + stem_index * 0.035
		sac_mesh.height = 0.7 + stem_index * 0.08
		sac_mesh.radial_segments = 10
		sac_mesh.rings = 6
		sac.mesh = sac_mesh
		sac.material_override = accent_material
		sac.position = stem.position + Vector3(0.0, stem_mesh.height * 0.52, 0.0)
		sac.scale = Vector3(0.75, 1.0, 0.62)
		body_visual.add_child(sac)

		for seed_index in range(3):
			var seed := MeshInstance3D.new()
			var seed_mesh := SphereMesh.new()
			seed_mesh.radius = 0.045
			seed_mesh.height = 0.09
			seed_mesh.radial_segments = 6
			seed_mesh.rings = 3
			seed.mesh = seed_mesh
			seed.material_override = _make_toon(Color("e59d57"))
			seed.position = sac.position + Vector3((seed_index - 1) * 0.085, 0.02 + seed_index * 0.035, 0.12)
			body_visual.add_child(seed)


func _build_pigoid() -> void:
	base_height = 0.56
	body_material = _make_toon(Color("c1beb0"))
	accent_material = _make_toon(Color("728b8b"))
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.55
	body_mesh.height = 0.95
	body_mesh.radial_segments = 10
	body_mesh.rings = 6
	_add_outlined_part(body_mesh, Vector3(0.0, base_height, 0.0), Vector3.ZERO, Vector3(0.92, 0.62, 1.45), body_material)

	for plate_index in range(4):
		var plate := MeshInstance3D.new()
		var plate_mesh := SphereMesh.new()
		plate_mesh.radius = 0.32
		plate_mesh.height = 0.22
		plate_mesh.radial_segments = 8
		plate_mesh.rings = 4
		plate.mesh = plate_mesh
		plate.material_override = accent_material
		plate.position = Vector3(0.0, 0.95, -0.48 + plate_index * 0.34)
		plate.scale = Vector3(1.15, 0.42, 0.8)
		body_visual.add_child(plate)

	var leg_material := _make_toon(Color("5f6663"))
	for z_offset in [-0.5, 0.0, 0.5]:
		for side in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.075
			leg_mesh.bottom_radius = 0.11
			leg_mesh.height = 0.58
			leg_mesh.radial_segments = 6
			leg.mesh = leg_mesh
			leg.material_override = leg_material
			leg.position = Vector3(side * 0.48, 0.31, z_offset)
			leg.rotation_degrees.z = side * -28.0
			body_visual.add_child(leg)

	var snout := MeshInstance3D.new()
	var snout_mesh := CylinderMesh.new()
	snout_mesh.top_radius = 0.055
	snout_mesh.bottom_radius = 0.13
	snout_mesh.height = 0.92
	snout_mesh.radial_segments = 7
	snout.mesh = snout_mesh
	snout.material_override = leg_material
	snout.position = Vector3(0.0, 0.48, -1.05)
	snout.rotation_degrees.x = 73.0
	body_visual.add_child(snout)
	_add_feelers(Color("7fb2bc"), 0.82, -0.7)


func _build_sterq_serpent() -> void:
	base_height = 0.54
	body_material = _make_toon(Color("84636d"))
	accent_material = _make_toon(Color(0.42, 0.24, 0.31, 0.82), true)
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.62
	body_mesh.height = 1.08
	body_mesh.radial_segments = 10
	body_mesh.rings = 6
	_add_outlined_part(body_mesh, Vector3(0.0, base_height, 0.0), Vector3.ZERO, Vector3(0.74, 0.52, 1.72), body_material)

	for side in [-1.0, 1.0]:
		var veil := MeshInstance3D.new()
		var veil_mesh := PrismMesh.new()
		veil_mesh.size = Vector3(1.25, 0.10, 2.35)
		veil.mesh = veil_mesh
		veil.material_override = accent_material
		veil.position = Vector3(side * 0.55, 0.75, 0.20)
		veil.rotation_degrees = Vector3(0.0, side * 7.0, side * 16.0)
		body_visual.add_child(veil)

	var limb_material := _make_toon(Color("423c43"))
	for z_offset in [-0.47, 0.42]:
		for side in [-1.0, 1.0]:
			var limb := MeshInstance3D.new()
			var limb_mesh := CylinderMesh.new()
			limb_mesh.top_radius = 0.065
			limb_mesh.bottom_radius = 0.13
			limb_mesh.height = 0.82
			limb_mesh.radial_segments = 6
			limb.mesh = limb_mesh
			limb.material_override = limb_material
			limb.position = Vector3(side * 0.48, 0.25, z_offset)
			limb.rotation_degrees.z = side * -38.0
			body_visual.add_child(limb)

	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.055
		eye_mesh.height = 0.11
		eye_mesh.radial_segments = 6
		eye_mesh.rings = 3
		eye.mesh = eye_mesh
		var eye_material := _make_toon(Color("e4b56b"))
		eye_material.emission_enabled = true
		eye_material.emission = Color("a45b40")
		eye_material.emission_energy_multiplier = 0.65
		eye.material_override = eye_material
		eye.position = Vector3(side * 0.22, 0.72, -0.93)
		body_visual.add_child(eye)
	_add_feelers(Color("754752"), 1.25, -0.8)


func _add_outlined_part(mesh: PrimitiveMesh, part_position: Vector3, part_rotation: Vector3, part_scale: Vector3, material: Material) -> void:
	var outline := MeshInstance3D.new()
	outline.mesh = mesh
	var outline_material := StandardMaterial3D.new()
	outline_material.albedo_color = Color("292833")
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.material_override = outline_material
	outline.position = part_position
	outline.rotation_degrees = part_rotation
	outline.scale = part_scale * 1.055
	body_visual.add_child(outline)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = part_position
	part.rotation_degrees = part_rotation
	part.scale = part_scale
	body_visual.add_child(part)


func _add_feelers(color: Color, length: float, z_position: float) -> void:
	var material := _make_toon(color)
	for side in [-1.0, 1.0]:
		var feeler := MeshInstance3D.new()
		var feeler_mesh := CylinderMesh.new()
		feeler_mesh.top_radius = 0.018
		feeler_mesh.bottom_radius = 0.035
		feeler_mesh.height = length
		feeler_mesh.radial_segments = 6
		feeler.mesh = feeler_mesh
		feeler.material_override = material
		feeler.position = Vector3(side * 0.22, base_height + 0.34, z_position)
		feeler.rotation_degrees.x = 66.0
		feeler.rotation_degrees.z = side * 15.0
		body_visual.add_child(feeler)


func set_behavior(new_behavior: int) -> void:
	behavior = new_behavior
	if not body_material:
		return
	if behavior == Behavior.FLEEING:
		body_material.emission_enabled = true
		body_material.emission = Color("9f5c59")
		body_material.emission_energy_multiplier = 0.28
	elif species != Species.GLOW_REED:
		body_material.emission_enabled = false


func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	if species == Species.GLOW_REED:
		body_visual.rotation.z = sin(time * 0.72 + organism_id) * 0.035
		body_visual.scale.y = 1.0 + sin(time * 0.55 + organism_id * 0.41) * 0.025
		return
	if move_velocity.length_squared() > 0.02:
		var direction := Vector3(move_velocity.x, 0.0, move_velocity.y).normalized()
		var target_yaw := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.08)
	body_visual.position.y = sin(time * 2.1 + organism_id) * 0.028


func _sync_transform() -> void:
	position = Vector3(sim_position.x, 0.0, sim_position.y)
