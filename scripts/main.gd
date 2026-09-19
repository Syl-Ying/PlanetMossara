extends Node3D

const EcosystemScript := preload("res://scripts/ecosystem.gd")
const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/hud.gd")
const AmbientSoundScript := preload("res://scripts/ambient_sound.gd")

var ambient_fliers: Array[Node3D] = []


func _ready() -> void:
	_configure_input()
	_build_environment()
	_spawn_ecosystem()
	_spawn_player()
	_spawn_hud()
	_spawn_ambient_sound()
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
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("cfd2c9")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.55
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.78
	environment.adjustment_contrast = 1.08
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "SoftOvercastLight"
	sun.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	sun.light_color = Color("f2dcc3")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)

	var ground := MeshInstance3D.new()
	ground.name = "PaleRainBasin"
	var plane := PlaneMesh.new()
	plane.size = Vector2(120.0, 120.0)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	ground.mesh = plane
	ground.material_override = _toon_material(Color("6f7478"), 0.98)
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

	_build_puddles()
	_build_hi_hat_grove()
	_build_membrane_forms()
	_build_finger_flora()
	_build_ambient_fauna()


func _toon_material(color: Color, roughness := 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


func _build_puddles() -> void:
	var water_material := _toon_material(Color(0.48, 0.58, 0.62, 0.48), 0.42)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var puddles := [
		[Vector3(-13.0, 0.018, -4.0), Vector2(19.0, 8.0), -7.0],
		[Vector3(17.0, 0.02, -19.0), Vector2(13.0, 5.5), 12.0],
		[Vector3(20.0, 0.017, 17.0), Vector2(9.0, 4.0), -18.0],
	]
	for data in puddles:
		var puddle := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = data[1]
		puddle.mesh = mesh
		puddle.material_override = water_material
		puddle.position = data[0]
		puddle.rotation_degrees.y = data[2]
		add_child(puddle)


func _build_hi_hat_grove() -> void:
	var stem_material := _toon_material(Color("30313d"))
	var cap_material := _toon_material(Color("626d7b"))
	var grove := [
		Vector3(-31, 0, -31), Vector3(-23, 0, -36), Vector3(-35, 0, -12),
		Vector3(30, 0, -35), Vector3(37, 0, -18), Vector3(24, 0, -28),
		Vector3(-42, 0, 12), Vector3(43, 0, 18), Vector3(31, 0, 34),
		Vector3(-29, 0, 31), Vector3(8, 0, -45), Vector3(-9, 0, -42),
	]
	for index in range(grove.size()):
		var tree := Node3D.new()
		tree.name = "HiHatTree_%02d" % index
		tree.position = grove[index]
		var height := 6.5 + float(index % 4) * 1.8
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = 0.08
		stem_mesh.bottom_radius = 0.19
		stem_mesh.height = height
		stem_mesh.radial_segments = 7
		stem.mesh = stem_mesh
		stem.material_override = stem_material
		stem.position.y = height * 0.5
		stem.rotation_degrees.z = -4.0 + float(index % 3) * 4.0
		tree.add_child(stem)
		var cap := MeshInstance3D.new()
		var cap_mesh := CylinderMesh.new()
		cap_mesh.top_radius = 2.0 + float(index % 3) * 0.35
		cap_mesh.bottom_radius = cap_mesh.top_radius * 0.82
		cap_mesh.height = 0.24
		cap_mesh.radial_segments = 12
		cap.mesh = cap_mesh
		cap.material_override = cap_material
		cap.position.y = height
		cap.scale.z = 0.72
		tree.add_child(cap)
		add_child(tree)


func _build_membrane_forms() -> void:
	var bone_material := _toon_material(Color("4d4654"))
	var veil_material := _toon_material(Color(0.72, 0.46, 0.44, 0.72), 1.0)
	veil_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for index in range(5):
		var form := Node3D.new()
		form.name = "RainMembrane_%02d" % index
		form.position = Vector3(-39.0 + index * 18.0, 0.0, -46.0 + float(index % 2) * 6.0)
		var spine := MeshInstance3D.new()
		var spine_mesh := CylinderMesh.new()
		spine_mesh.top_radius = 0.16
		spine_mesh.bottom_radius = 0.55
		spine_mesh.height = 10.0 + index
		spine_mesh.radial_segments = 7
		spine.mesh = spine_mesh
		spine.material_override = bone_material
		spine.position.y = spine_mesh.height * 0.5
		spine.rotation_degrees.z = -10.0 + index * 4.0
		form.add_child(spine)
		var veil := MeshInstance3D.new()
		var veil_mesh := PrismMesh.new()
		veil_mesh.size = Vector3(5.0, 6.5, 0.18)
		veil.mesh = veil_mesh
		veil.material_override = veil_material
		veil.position = Vector3(1.1, 6.2 + index * 0.5, 0.0)
		veil.rotation_degrees.z = -13.0 + index * 3.0
		form.add_child(veil)
		add_child(form)


func _build_finger_flora() -> void:
	var palettes := [Color("4b334e"), Color("786067"), Color("92706c"), Color("3c5960")]
	for patch_index in range(18):
		var patch := Node3D.new()
		patch.name = "FingerFlora_%02d" % patch_index
		var angle := patch_index * 2.19
		var radius := 14.0 + float((patch_index * 11) % 28)
		patch.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var material := _toon_material(palettes[patch_index % palettes.size()])
		for finger_index in range(3 + patch_index % 4):
			var finger := MeshInstance3D.new()
			var mesh := CapsuleMesh.new()
			mesh.radius = 0.12 + finger_index * 0.025
			mesh.height = 0.8 + float((finger_index + patch_index) % 4) * 0.35
			mesh.radial_segments = 7
			mesh.rings = 4
			finger.mesh = mesh
			finger.material_override = material
			finger.position = Vector3((finger_index - 2) * 0.28, mesh.height * 0.45, sin(finger_index) * 0.22)
			finger.rotation_degrees.z = -16.0 + finger_index * 8.0
			patch.add_child(finger)
		add_child(patch)


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
