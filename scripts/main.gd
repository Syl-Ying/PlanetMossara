extends Node3D

const EcosystemScript := preload("res://scripts/ecosystem.gd")
const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/hud.gd")
const PuzzleScript := preload("res://scripts/bloom_gate_puzzle.gd")


func _ready() -> void:
	_configure_input()
	_build_environment()
	_spawn_ecosystem()
	_spawn_puzzle()
	_spawn_player()
	_spawn_hud()
	print("Living World ready: Q attracts grazers, E repels stalkers.")


func _configure_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("nutrient_signal", KEY_Q)
	_add_key_action("light_signal", KEY_E)
	_add_key_action("journal", KEY_TAB)
	_add_key_action("release_mouse", KEY_ESCAPE)


func _add_key_action(action_name: StringName, physical_key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var key_event := InputEventKey.new()
		key_event.physical_keycode = physical_key
		InputMap.action_add_event(action_name, key_event)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("101a22")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8fb7ac")
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-54.0, -32.0, 0.0)
	sun.light_color = Color("ffe8b8")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(100.0, 100.0)
	plane.subdivide_width = 20
	plane.subdivide_depth = 20
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("182f2a")
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	add_child(ground)

	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundCollision"
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 0.2, 100.0)
	ground_shape.shape = box
	ground_shape.position.y = -0.1
	ground_body.add_child(ground_shape)
	add_child(ground_body)

	_build_landmarks()


func _build_landmarks() -> void:
	var landmark_material := StandardMaterial3D.new()
	landmark_material.albedo_color = Color("3d5e55")
	landmark_material.roughness = 0.92
	var positions := [
		Vector3(-18.0, 1.8, -14.0), Vector3(20.0, 2.5, -24.0),
		Vector3(26.0, 1.4, 18.0), Vector3(-27.0, 2.2, 22.0),
		Vector3(5.0, 1.2, -34.0), Vector3(-7.0, 1.6, 34.0),
	]
	for index in positions.size():
		var landmark := MeshInstance3D.new()
		landmark.name = "Landmark_%02d" % index
		var prism := PrismMesh.new()
		prism.size = Vector3(2.5 + index % 3, 2.8 + index * 0.35, 3.0)
		landmark.mesh = prism
		landmark.material_override = landmark_material
		landmark.position = positions[index]
		landmark.rotation_degrees.y = float(index * 37)
		add_child(landmark)


func _spawn_ecosystem() -> void:
	var ecosystem := Node3D.new()
	ecosystem.name = "Ecosystem"
	ecosystem.set_script(EcosystemScript)
	add_child(ecosystem)


func _spawn_puzzle() -> void:
	var puzzle := Node3D.new()
	puzzle.name = "BloomGatePuzzle"
	puzzle.set_script(PuzzleScript)
	add_child(puzzle)


func _spawn_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Explorer"
	player.set_script(PlayerScript)
	player.position = Vector3(0.0, 1.2, 12.0)
	add_child(player)


func _spawn_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(HudScript)
	add_child(hud)
