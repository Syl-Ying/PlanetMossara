extends Node3D

const LURE_CENTER := Vector2(0.0, -23.0)
const REQUIRED_GRAZERS := 3
const REQUIRED_HOLD_SECONDS := 3.0

var gate_progress := 0.0
var is_open := false
var is_complete := false
var gate_visual: Node3D
var gate_collision: CollisionShape3D
var beacon_light: OmniLight3D


func _ready() -> void:
	add_to_group("puzzle")
	_build_lure_marker()
	_build_gate()
	_build_beacon()


func _process(delta: float) -> void:
	var ecosystem := get_tree().get_first_node_in_group("ecosystem")
	if ecosystem == null:
		return

	if not is_open:
		var grazer_count: int = ecosystem.count_grazers_near(LURE_CENTER, 6.5)
		if grazer_count >= REQUIRED_GRAZERS:
			gate_progress = minf(REQUIRED_HOLD_SECONDS, gate_progress + delta)
		else:
			gate_progress = maxf(0.0, gate_progress - delta * 0.5)
		var percent := int(round(gate_progress / REQUIRED_HOLD_SECONDS * 100.0))
		get_tree().call_group(
			"hud", "set_objective",
			"Gather 3 grazers in the amber bloom (%d/3) — hold %d%%" % [grazer_count, percent]
		)
		if gate_progress >= REQUIRED_HOLD_SECONDS:
			_open_gate()
	else:
		gate_visual.position.y = move_toward(gate_visual.position.y, 4.6, delta * 2.2)
		if not is_complete:
			get_tree().call_group("hud", "set_objective", "The living gate is open — reach the cyan beacon")


func _build_lure_marker() -> void:
	var marker := MeshInstance3D.new()
	marker.name = "AmberBloom"
	var disc := CylinderMesh.new()
	disc.top_radius = 6.5
	disc.bottom_radius = 6.5
	disc.height = 0.025
	marker.mesh = disc
	marker.position = Vector3(LURE_CENTER.x, 0.025, LURE_CENTER.y)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.95, 0.61, 0.18, 0.22)
	material.emission_enabled = true
	material.emission = Color("8f4e14")
	material.emission_energy_multiplier = 0.55
	marker.material_override = material
	add_child(marker)

	for angle_index in 12:
		var petal := MeshInstance3D.new()
		var petal_mesh := SphereMesh.new()
		petal_mesh.radius = 0.38
		petal_mesh.height = 0.22
		petal.mesh = petal_mesh
		petal.material_override = material
		var angle := TAU * angle_index / 12.0
		petal.position = Vector3(
			LURE_CENTER.x + cos(angle) * 6.0,
			0.13,
			LURE_CENTER.y + sin(angle) * 6.0
		)
		add_child(petal)


func _build_gate() -> void:
	var gate_body := StaticBody3D.new()
	gate_body.name = "LivingGateCollision"
	gate_body.position = Vector3(0.0, 0.0, -30.0)
	gate_collision = CollisionShape3D.new()
	var gate_shape := BoxShape3D.new()
	gate_shape.size = Vector3(9.0, 4.0, 0.8)
	gate_collision.shape = gate_shape
	gate_collision.position.y = 2.0
	gate_body.add_child(gate_collision)
	add_child(gate_body)

	gate_visual = Node3D.new()
	gate_visual.name = "LivingGateVisual"
	gate_visual.position = Vector3(0.0, 0.0, -30.0)
	add_child(gate_visual)

	var gate_material := StandardMaterial3D.new()
	gate_material.albedo_color = Color("765278")
	gate_material.roughness = 0.86
	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.65
		pillar_mesh.bottom_radius = 1.2
		pillar_mesh.height = 5.6
		pillar.mesh = pillar_mesh
		pillar.material_override = gate_material
		pillar.position = Vector3(side * 4.4, 2.8, 0.0)
		pillar.rotation_degrees.z = side * 8.0
		gate_visual.add_child(pillar)

	var membrane := MeshInstance3D.new()
	membrane.name = "Membrane"
	var membrane_mesh := QuadMesh.new()
	membrane_mesh.size = Vector2(8.0, 3.8)
	membrane.mesh = membrane_mesh
	var membrane_material := StandardMaterial3D.new()
	membrane_material.albedo_color = Color("9c6f91")
	membrane_material.emission_enabled = true
	membrane_material.emission = Color("4a2446")
	membrane_material.emission_energy_multiplier = 0.4
	membrane_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	membrane.material_override = membrane_material
	membrane.position.y = 2.0
	gate_visual.add_child(membrane)


func _build_beacon() -> void:
	var beacon := Area3D.new()
	beacon.name = "ExitBeacon"
	beacon.position = Vector3(0.0, 0.0, -39.0)
	var beacon_shape_node := CollisionShape3D.new()
	var beacon_shape := CylinderShape3D.new()
	beacon_shape.radius = 2.4
	beacon_shape.height = 3.0
	beacon_shape_node.shape = beacon_shape
	beacon_shape_node.position.y = 1.5
	beacon.add_child(beacon_shape_node)
	beacon.body_entered.connect(_on_beacon_entered)
	add_child(beacon)

	var beacon_mesh := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.45
	mesh.bottom_radius = 1.4
	mesh.height = 3.2
	beacon_mesh.mesh = mesh
	beacon_mesh.position.y = 1.6
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.35, 0.92, 1.0, 0.45)
	material.emission_enabled = true
	material.emission = Color("41cfe3")
	material.emission_energy_multiplier = 1.5
	beacon_mesh.material_override = material
	beacon.add_child(beacon_mesh)

	beacon_light = OmniLight3D.new()
	beacon_light.light_color = Color("68edff")
	beacon_light.light_energy = 2.0
	beacon_light.omni_range = 8.0
	beacon_light.position.y = 2.0
	beacon.add_child(beacon_light)


func _open_gate() -> void:
	is_open = true
	gate_collision.set_deferred("disabled", true)
	get_tree().call_group("hud", "show_ecology_message", "The living gate has opened")


func _on_beacon_entered(body: Node3D) -> void:
	if not is_open or is_complete or not body.is_in_group("player"):
		return
	is_complete = true
	beacon_light.light_color = Color("e8ffae")
	get_tree().call_group("hud", "set_objective", "PASSAGE COMPLETE — the ecosystem remembers your intervention")
	get_tree().call_group("hud", "show_ecology_message", "Ecological passage complete")
