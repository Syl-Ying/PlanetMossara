extends SceneTree
const Organism = preload("res://scripts/organism.gd")
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var world: Node3D = load("res://main.tscn").instantiate()
	root.add_child(world)
	world.get_node("Walker").set_process(false)
	world.get_node("Walker").set_physics_process(false)
	world.get_node("QuietInterface").hide()
	var ecology := world.get_node("VestaEcology")
	ecology.set_physics_process(false)
	for organism in ecology.organisms:
		organism.hide()
		organism.set_process(false)
	var heroes: Array[Node3D] = []
	for i in range(2):
		var creature := Node3D.new()
		creature.set_script(Organism)
		world.add_child(creature)
		creature.configure(i+1,i+1,Vector2(-1.4 if i==0 else 1.4,8),100)
		creature.rotation.y = -2.1 if i==0 else 2.1
		creature.set_process(false)
		heroes.append(creature)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(0,2.1,14.2)
	camera.look_at(Vector3(0,0.95,8))
	camera.fov=43
	camera.current=true
	for shot in ["idle","walk","interaction"]:
		for i in heroes.size():
			var player: AnimationPlayer = heroes[i].creature_animation
			player.play("Idle" if shot=="idle" else ("Walk" if shot=="walk" else ("Feed" if i==0 else "Alert")),0)
			player.seek(0.45,true)
			player.pause()
		for frame in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://assets/creatures/models/in_game_%s.png" % shot)
	world.queue_free()
	await process_frame
	quit()
