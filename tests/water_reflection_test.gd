extends SceneTree
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	world.get_node("Walker").set_physics_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	var reflection = world.get_node("BasinReflections")
	for position in [Vector3(0,1.25,14.8),Vector3(4,3,9)]:
		camera.position=position
		camera.look_at(Vector3(-2,0,7))
		await process_frame
		reflection._process(0.016)
		var mirrored: Camera3D = reflection.reflection_camera
		var expected := camera.global_position*Vector3(1,-1,1)
		var direction := -camera.global_basis.z*Vector3(1,-1,1)
		if mirrored.global_position.distance_to(expected)>0.001 or (-mirrored.global_basis.z).distance_to(direction)>0.001:
			printerr("FAIL: reflection camera must mirror position and direction");quit(1);return
	var surface: MeshInstance3D = world.get_node("PaleRainBasin")
	if surface.layers & reflection.reflection_camera.cull_mask:
		printerr("FAIL: reflection must exclude its own water surface");quit(1);return
	camera.position.y=0.02
	reflection._process(0.016)
	if reflection.surface.get_shader_parameter("reflection_enabled"):
		printerr("FAIL: reflection must disable below the water plane");quit(1);return
	print("PASS: moving mirrored camera, water exclusion and below-surface fallback")
	world.queue_free()
	await process_frame
	quit()
