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
var feeding_target := Vector2.ZERO
var has_feeding_target := false
var avoidance_time := 0.0
var avoidance_direction := Vector2.ZERO
var body_visual: Node3D
var body_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var base_height := 0.0
var creature_animation: AnimationPlayer
var creature_model: Node3D
var _render_previous := Vector3.ZERO
var _render_current := Vector3.ZERO
var _transform_initialized := false
var _walking := false
var pigoid_gait: RefCounted
var sterq_gait: RefCounted
const SterqGait = preload("res://scripts/sterq_gait.gd")
const PigoidGait = preload("res://scripts/pigoid_gait.gd")
const PigoidScene = preload("res://assets/creatures/models/pigoid.glb")
const SterqScene = preload("res://assets/creatures/models/sterq.glb")
const CreatureShader = preload("res://assets/shaders/creature_ink.gdshader")


func configure(new_id: int, new_species: int, start_position: Vector2, start_energy: float) -> void:
	organism_id = new_id
	species = new_species
	sim_position = start_position
	energy = start_energy
	behavior = Behavior.ROOTED if species == Species.GLOW_REED else Behavior.WANDERING
	_sync_transform()
	_build_visual()


func get_display_name() -> String:
	return DISPLAY_NAMES[species]


func _make_toon(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.metallic_specular = 0.13
	material.rim_enabled = false
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
	_load_creature(PigoidScene, 0.62)
	creature_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	pigoid_gait = PigoidGait.new()
	pigoid_gait.setup(self, creature_model)


func _build_sterq_serpent() -> void:
	_load_creature(SterqScene, 0.64)
	creature_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	sterq_gait = SterqGait.new()
	sterq_gait.setup(self,creature_model)


func _load_creature(scene: PackedScene, size: float) -> void:
	creature_model = scene.instantiate()
	creature_model.name = "SculptedCreature"
	creature_model.scale = Vector3.ONE * size
	# Blender's -Y front exports to Godot +Z; align to the simulation's -Z front.
	creature_model.rotation.y = PI
	body_visual.add_child(creature_model)
	var contact := MeshInstance3D.new()
	contact.name = "SoftContactShadow"
	var shadow_plane := PlaneMesh.new()
	shadow_plane.size = Vector2(1.2, 1.9) if species == Species.BURROW_GRAZER else Vector2(1.4, 2.7)
	contact.mesh = shadow_plane
	var contact_material := ShaderMaterial.new()
	contact_material.shader = preload("res://assets/shaders/creature_contact.gdshader")
	contact.material_override = contact_material
	contact.position.y = 0.012
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body_visual.add_child(contact)
	for node in creature_model.find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var original := node.get_active_material(surface) as StandardMaterial3D
			if original == null:
				continue
			var ink := ShaderMaterial.new()
			ink.shader = CreatureShader
			ink.set_shader_parameter("pigment", original.albedo_color)
			ink.set_shader_parameter("use_skin_map", original.albedo_texture != null)
			if original.albedo_texture:
				ink.set_shader_parameter("skin_map", original.albedo_texture)
			node.set_surface_override_material(surface, ink)
	var players := creature_model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		creature_animation = players[0]
		for clip in creature_animation.get_animation_list():
			if clip != "RESET":
				creature_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		_play_creature_clip("Idle")


func _play_creature_clip(clip: String) -> void:
	if creature_animation == null or not creature_animation.has_animation(clip):
		return
	if creature_animation.current_animation != clip:
		creature_animation.play(clip, 0.25)


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


func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	if species == Species.GLOW_REED:
		body_visual.rotation.z = sin(time * 0.72 + organism_id) * 0.035
		body_visual.scale.y = 1.0 + sin(time * 0.55 + organism_id * 0.41) * 0.025
		return
	# Interpolate the 30 Hz ecology on every rendered frame.
	var ecology := get_parent()
	if ecology and ecology.is_in_group("ecosystem"):
		position = _render_previous.lerp(_render_current, clampf(ecology.accumulator / ecology.FIXED_STEP, 0.0, 1.0))
	else:
		position = _render_current
	if move_velocity.length_squared() > 0.02:
		var direction := Vector3(move_velocity.x, 0.0, move_velocity.y).normalized()
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-5.0 * delta))
	if creature_animation:
		var speed := move_velocity.length()
		_walking = speed > (0.07 if _walking else 0.18)
		var clip := "Idle"
		if _walking:
			clip = "Walk"
		elif behavior == Behavior.FEEDING and species == Species.BURROW_GRAZER:
			clip = "Feed"
		elif behavior == Behavior.HUNTING and species == Species.VEIL_STALKER:
			clip = "Alert"
		_play_creature_clip(clip)
		var target_rate := clampf(speed / 1.1, 0.45, 1.55) if clip == "Walk" else 1.0
		creature_animation.speed_scale = lerpf(creature_animation.speed_scale, target_rate, 1.0 - exp(-6.0 * delta))
		if pigoid_gait:
			creature_animation.advance(delta)
			pigoid_gait.update(delta,_walking,speed)
		elif sterq_gait:
			creature_animation.advance(delta)
			sterq_gait.update(delta,_walking,speed)


func _sync_transform() -> void:
	var target := Vector3(sim_position.x, 0.0, sim_position.y)
	if species != Species.GLOW_REED and is_inside_tree():
		var query := PhysicsRayQueryParameters3D.create(target+Vector3.UP*1.0,target-Vector3.UP)
		query.collision_mask = 1
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():target.y=hit.position.y
	if not _transform_initialized:
		_render_previous = target
		_render_current = target
		position = target
		_transform_initialized = true
	else:
		_render_previous = _render_current
		_render_current = target
