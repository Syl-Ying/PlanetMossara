extends SceneTree
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	var ecology=world.get_node("VestaEcology")
	ecology.set_physics_process(false)
	await physics_frame
	await physics_frame
	var blocked := {}
	var feeding := {}
	var starts := {}
	var stationary := {}
	var max_stationary := {}
	for frame in range(1800):
		for actor in ecology.organisms:starts[actor.organism_id]=actor.sim_position
		ecology._step_simulation(1.0/30.0)
		for actor in ecology.organisms:
			if actor.species==0:continue
			var stalled: bool=actor.behavior in [2,4,5] and actor.sim_position.distance_to(starts[actor.organism_id])<0.0007
			stationary[actor.organism_id]=stationary.get(actor.organism_id,0)+1 if stalled else 0
			max_stationary[actor.organism_id]=maxi(max_stationary.get(actor.organism_id,0),stationary[actor.organism_id])
			if stalled:
				blocked[actor.organism_id]=blocked.get(actor.organism_id,0)+1
			if actor.behavior==3:feeding[actor.organism_id]=feeding.get(actor.organism_id,0)+1
	print("BLOCKED FRAMES: ",blocked," FEEDING FRAMES: ",feeding)
	print("Longest stalled run: ",max_stationary)
	for frames in max_stationary.values():
		if frames>150:
			printerr("FAIL: pursuing/fleeing creature stuck for over five seconds");quit(1);return
	if feeding.size()<3:
		printerr("FAIL: too few creatures reached food");quit(1);return
	print("PASS: live-world travel, feeding and no prolonged obstacle/boundary stalls")
	world.queue_free()
	await process_frame
	quit()
