extends SceneTree
const Motion=preload("res://scripts/creature_motion.gd")
const Organism=preload("res://scripts/organism.gd")
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var site=load("res://assets/spacecraft/crash_site.tscn").instantiate()
	root.add_child(site)
	await physics_frame
	await physics_frame
	var shapes=site.find_children("*","CollisionShape3D",true,false)
	print("Crash collision shapes: ",shapes.size())
	if shapes.size()<4:
		printerr("FAIL: hull/fins/scar collision missing");quit(1);return
	var ray=PhysicsRayQueryParameters3D.create(Vector3(-6,1.1,0),Vector3(6,1.1,0),1)
	if site.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		printerr("FAIL: hull does not block player collision layer");quit(1);return
	var actor:=Node3D.new()
	actor.set_script(Organism)
	root.add_child(actor)
	actor.configure(1,1,Vector2(-6,0),100)
	actor.set_process(false)
	if Motion._safe_fraction(actor,[actor],Vector2(12,0))>0.5:
		printerr("FAIL: creature sweep crossed capsule");quit(1);return
	print("PASS: crash site has physical hull and creature sweep protection")
	actor.queue_free()
	site.queue_free()
	await process_frame
	quit()
