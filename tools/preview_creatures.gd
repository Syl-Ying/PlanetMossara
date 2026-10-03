extends SceneTree
const Organism = preload("res://scripts/organism.gd")
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("b9beb8")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.7
	env.environment = settings
	stage.add_child(env)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40,40)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("777d7d")
	ground.material_override = mat
	stage.add_child(ground)
	for i in range(2):
		var creature := Node3D.new()
		creature.set_script(Organism)
		stage.add_child(creature)
		creature.configure(i+1,i+1,Vector2(-1.4 if i==0 else 1.4,0),100)
		creature.rotation.y = -2.1 if i==0 else 2.1
		creature.set_process(false)
		print("PREVIEW animations ", creature.creature_animation.get_animation_list())
		creature.creature_animation.play("Idle")
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0,2.0,6.2)
	camera.look_at(Vector3(0,0.9,0))
	camera.fov = 43
	camera.current = true
	for frame in range(30):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/creatures/models/godot_creature_preview.png")
	stage.queue_free()
	await process_frame
	quit()
