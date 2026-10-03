extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var world: Node3D = load("res://main.tscn").instantiate()
	root.add_child(world)
	world.get_node("Walker").set_process(false)
	world.get_node("Walker").set_physics_process(false)
	world.get_node("QuietInterface").hide()
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0.8, 1.25, 14.8)
	camera.look_at(Vector3(-2.0, 0.1, 7.0))
	camera.current = true
	for frame in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://assets/models/shore_preview.png")
	print("Preview saved: ", result)
	world.queue_free()
	await process_frame
	quit(result)
