extends SceneTree
func _initialize() -> void:call_deferred("run_audit")
func run_audit() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	var ecology=world.get_node("VestaEcology")
	ecology.set_physics_process(false)
	var changes={}
	var reversals={}
	for frame in range(1800):
		var old={}
		for o in ecology.organisms:
			if o.species==1:old[o.organism_id]=[o.behavior,o.move_velocity]
		ecology._step_simulation(1.0/30.0)
		for o in ecology.organisms:
			if o.species!=1:continue
			var before=old[o.organism_id]
			if before[0]!=o.behavior:changes[o.organism_id]=changes.get(o.organism_id,0)+1
			if before[1].length()>0.1 and o.move_velocity.length()>0.1 and before[1].normalized().dot(o.move_velocity.normalized())<0:
				reversals[o.organism_id]=reversals.get(o.organism_id,0)+1
	print("60 seconds behavior changes: ",changes," reversals: ",reversals)
	for id in changes:
		if changes[id] > 60 or reversals.get(id,0) > 10:
			printerr("FAIL: grazer decision thrashing returned: ",id)
			quit(1)
			return
	# Check that rendering actually interpolates between simulation ticks.
	var grazer = ecology.organisms[24]
	grazer._render_previous=Vector3(0,0,0)
	grazer._render_current=Vector3(1,0,0)
	grazer.move_velocity=Vector2(1,0)
	ecology.accumulator=ecology.FIXED_STEP*0.25
	grazer._process(1.0/60.0)
	if not is_equal_approx(grazer.position.x,0.25):
		printerr("FAIL: rendered movement is not interpolated")
		quit(1)
		return
	# Low-speed noise must not restart the gait each frame.
	grazer.move_velocity=Vector2(0.25,0)
	grazer._process(1.0/60.0)
	for speed in [0.13,0.15,0.12,0.16]:
		grazer.move_velocity=Vector2(speed,0)
		grazer._process(1.0/60.0)
		if grazer.creature_animation.current_animation != "Walk":
			printerr("FAIL: gait flickers at low speed")
			quit(1)
			return
	print("PASS: no rapid decision reversals, interpolated movement, stable gait at low speed")
	world.queue_free()
	await process_frame
	quit()
