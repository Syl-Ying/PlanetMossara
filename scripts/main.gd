extends Node3D

const EcosystemScript := preload("res://scripts/ecosystem.gd")
const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/hud.gd")
const AmbientSoundScript := preload("res://scripts/ambient_sound.gd")
const VolumetricFloraScript := preload("res://scripts/volumetric_flora.gd")

var ambient_fliers: Array[Node3D] = []


func _ready() -> void:
	_configure_input()
	_build_environment()
	var crash_site := preload("res://assets/spacecraft/crash_site.tscn").instantiate()
	crash_site.position = Vector3(-10.0,0.0,16.0)
	crash_site.rotation.y = -0.3
	add_child(crash_site)
	var contacts := Node3D.new()
	contacts.name = "GroundContacts"
	contacts.set_script(preload("res://scripts/ground_contacts.gd"))
	add_child(contacts)
	_spawn_ecosystem()
	_spawn_player()
	_spawn_hud()
	_spawn_ambient_sound()
	var reflections := Node.new()
	reflections.name = "BasinReflections"
	reflections.set_script(preload("res://scripts/basin_reflection.gd"))
	add_child(reflections)
	print("Vesta basin ready: there is no objective. Walk, watch, and listen.")


func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for flier in ambient_fliers:
		var phase: float = flier.get_meta("phase")
		var origin: Vector3 = flier.get_meta("origin")
		flier.position = origin + Vector3(
			cos(time * 0.18 + phase) * 4.0,
			sin(time * 0.37 + phase) * 0.8,
			sin(time * 0.15 + phase) * 3.0
		)
		flier.rotation.y = -time * 0.18 - phase


func _configure_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("slow_walk", KEY_SHIFT)
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
	world_environment.name = "VestaAtmosphere"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("9aaaba")
	sky_material.sky_horizon_color = Color("d8d7ce")
	sky_material.ground_bottom_color = Color("403b4b")
	sky_material.ground_horizon_color = Color("b5aaa5")
	sky_material.sun_angle_max = 8.0
	sky_material.sun_curve = 0.08
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c5d2ca")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("cfd2c9")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.003
	environment.fog_sky_affect = 0.55
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.0
	environment.adjustment_contrast = 1.08
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "SoftOvercastLight"
	sun.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	sun.light_color = Color("f2dcc3")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)

	var ground := MeshInstance3D.new()
	ground.name = "PaleRainBasin"
	var plane := PlaneMesh.new()
	plane.size = Vector2(440.0, 440.0)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	ground.mesh = plane
	var soil := ShaderMaterial.new()
	soil.shader = preload("res://assets/shaders/basin_ground.gdshader")
	ground.material_override = soil
	add_child(ground)

	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundCollision"
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120.0, 0.2, 120.0)
	ground_shape.shape = box
	ground_shape.position.y = -0.1
	ground_body.add_child(ground_shape)
	add_child(ground_body)

	var terrain := Node3D.new()
	terrain.name = "BasinTerrain"
	terrain.set_script(preload("res://scripts/basin_terrain.gd"))
	add_child(terrain)
	_spawn_volumetric_flora()
	_build_ambient_fauna()


func _toon_material(color: Color, roughness := 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.metallic_specular = 0.14
	material.rim_enabled = false
	material.rim = 0.26
	material.rim_tint = 0.42
	return material


func _spawn_volumetric_flora() -> void:
	var flora := Node3D.new()
	flora.name = "VolumetricFlora"
	flora.set_script(VolumetricFloraScript)
	add_child(flora)


func _build_ambient_fauna() -> void:
	var body_material := _toon_material(Color("d5cbc0"))
	var wing_material := _toon_material(Color(0.55, 0.66, 0.68, 0.62), 1.0)
	wing_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for index in range(9):
		var flier := Node3D.new()
		flier.name = "RainSkimmer_%02d" % index
		var origin := Vector3(-24.0 + index * 6.0, 8.0 + float(index % 3) * 1.4, -23.0 - float(index % 4) * 4.0)
		flier.position = origin
		flier.set_meta("origin", origin)
		flier.set_meta("phase", float(index) * 0.83)
		var body := MeshInstance3D.new()
		var body_mesh := SphereMesh.new()
		body_mesh.radius = 0.18
		body_mesh.height = 0.75
		body_mesh.radial_segments = 7
		body_mesh.rings = 4
		body.mesh = body_mesh
		body.material_override = body_material
		body.rotation_degrees.x = 90.0
		flier.add_child(body)
		for side in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			var wing_mesh := PrismMesh.new()
			wing_mesh.size = Vector3(0.85, 0.04, 0.32)
			wing.mesh = wing_mesh
			wing.material_override = wing_material
			wing.position.x = side * 0.45
			wing.rotation_degrees.y = side * 13.0
			flier.add_child(wing)
		add_child(flier)
		ambient_fliers.append(flier)


func _spawn_ecosystem() -> void:
	var ecosystem := Node3D.new()
	ecosystem.name = "VestaEcology"
	ecosystem.set_script(EcosystemScript)
	add_child(ecosystem)


func _spawn_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Walker"
	player.set_script(PlayerScript)
	player.position = Vector3(0.0, 1.2, 12.0)
	add_child(player)


func _spawn_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "QuietInterface"
	hud.set_script(HudScript)
	add_child(hud)


func _spawn_ambient_sound() -> void:
	var ambience := Node.new()
	ambience.name = "VestaAmbience"
	ambience.set_script(AmbientSoundScript)
	add_child(ambience)
