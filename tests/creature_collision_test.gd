extends SceneTree
const Organism = preload("res://scripts/organism.gd")
const Motion = preload("res://scripts/creature_motion.gd")
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var actors: Array[Node3D]=[]
	for i in range(2):
		var actor := Node3D.new()
		actor.set_script(Organism)
		root.add_child(actor)
		actor.configure(i+1,i+1,Vector2(-4 if i==0 else 4,0),100)
		actor.set_process(false)
		actors.append(actor)
	for frame in range(240):
		for i in range(2):
			actors[i].move_velocity=Vector2(3.4 if i==0 else -3.4,0)
			Motion.move(actors[i],actors,1.0/30.0)
		if actors[0].sim_position.distance_to(actors[1].sim_position)<2.999:
			printerr("FAIL: creatures overlapped during head-on movement");quit(1);return
	var obstacle := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(1,3,200)
	collider.shape=box
	obstacle.add_child(collider)
	obstacle.position=Vector3(0,1.5,0)
	root.add_child(obstacle)
	await physics_frame
	for layer in [1,4]:
		obstacle.collision_layer=layer
		await physics_frame
		actors[0].sim_position=Vector2(-4,0)
		for frame in range(30):
			actors[0].move_velocity=Vector2(30,0)
			Motion.move(actors[0],[actors[0]],1.0/30.0)
			if actors[0].sim_position.x > -1.84:
				printerr("FAIL: creature crossed rock/foliage barrier ",layer," ",frame," ",actors[0].sim_position);quit(1);return
	print("PASS: head-on separation and swept rock/foliage barriers at high speed")
	for actor in actors:actor.queue_free()
	obstacle.queue_free()
	await process_frame
	quit()
