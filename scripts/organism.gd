class_name LivingOrganism
extends Node3D

enum Species { GLOW_REED, BURROW_GRAZER, VEIL_STALKER }
enum Behavior { ROOTED, WANDERING, FORAGING, FEEDING, HUNTING, FLEEING, ATTRACTED }

var organism_id := 0
var species := Species.GLOW_REED
var behavior := Behavior.ROOTED
var energy := 100.0
var sim_position := Vector2.ZERO
var move_velocity := Vector2.ZERO
var body_visual: Node3D
var body_material: StandardMaterial3D
var base_height := 0.0


func configure(new_id: int, new_species: int, start_position: Vector2, start_energy: float) -> void:
	organism_id = new_id
	species = new_species
	sim_position = start_position
	energy = start_energy
	behavior = Behavior.ROOTED if species == Species.GLOW_REED else Behavior.WANDERING
	_build_visual()
	_sync_transform()


func _build_visual() -> void:
	body_material = StandardMaterial3D.new()
	body_material.roughness = 0.72
	body_visual = Node3D.new()
	body_visual.name = "Visual"
	add_child(body_visual)

	if species == Species.GLOW_REED:
		base_height = 0.9
		body_material.albedo_color = Color("58d98c")
		body_material.emission_enabled = true
		body_material.emission = Color("1f8c64")
		body_material.emission_energy_multiplier = 0.7
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = 0.05
		stem_mesh.bottom_radius = 0.18
		stem_mesh.height = 1.8
		stem.mesh = stem_mesh
		stem.material_override = body_material
		stem.position.y = 0.9
		body_visual.add_child(stem)
		var bulb := MeshInstance3D.new()
		var bulb_mesh := SphereMesh.new()
		bulb_mesh.radius = 0.24
		bulb_mesh.height = 0.48
		bulb.mesh = bulb_mesh
		bulb.material_override = body_material
		bulb.position.y = 1.88
		body_visual.add_child(bulb)
	elif species == Species.BURROW_GRAZER:
		base_height = 0.42
		body_material.albedo_color = Color("5ab9e8")
		var body := MeshInstance3D.new()
		var body_mesh := SphereMesh.new()
		body_mesh.radius = 0.52
		body_mesh.height = 0.85
		body.mesh = body_mesh
		body.material_override = body_material
		body.scale = Vector3(1.35, 0.72, 0.85)
		body.position.y = base_height
		body_visual.add_child(body)
		_add_feelers(body_material)
	else:
		base_height = 0.68
		body_material.albedo_color = Color("d55cb9")
		var body := MeshInstance3D.new()
		var body_mesh := PrismMesh.new()
		body_mesh.size = Vector3(1.25, 1.1, 1.9)
		body.mesh = body_mesh
		body.material_override = body_material
		body.position.y = base_height
		body_visual.add_child(body)
		_add_feelers(body_material)


func _add_feelers(material: StandardMaterial3D) -> void:
	for side in [-1.0, 1.0]:
		var feeler := MeshInstance3D.new()
		var feeler_mesh := CylinderMesh.new()
		feeler_mesh.top_radius = 0.025
		feeler_mesh.bottom_radius = 0.045
		feeler_mesh.height = 0.8
		feeler.mesh = feeler_mesh
		feeler.material_override = material
		feeler.position = Vector3(side * 0.28, base_height + 0.32, -0.55)
		feeler.rotation_degrees.x = 62.0
		feeler.rotation_degrees.z = side * 18.0
		body_visual.add_child(feeler)


func set_behavior(new_behavior: int) -> void:
	behavior = new_behavior
	if not body_material:
		return
	if behavior == Behavior.FLEEING:
		body_material.emission_enabled = true
		body_material.emission = Color("ff725e")
		body_material.emission_energy_multiplier = 0.75
	elif species != Species.GLOW_REED:
		body_material.emission_enabled = false


func _process(_delta: float) -> void:
	if species == Species.GLOW_REED:
		body_visual.rotation.z = sin(Time.get_ticks_msec() * 0.0017 + organism_id) * 0.045
		return
	if move_velocity.length_squared() > 0.02:
		var direction := Vector3(move_velocity.x, 0.0, move_velocity.y).normalized()
		var target_yaw := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.12)
	body_visual.position.y = sin(Time.get_ticks_msec() * 0.006 + organism_id) * 0.05


func _sync_transform() -> void:
	position = Vector3(sim_position.x, 0.0, sim_position.y)
