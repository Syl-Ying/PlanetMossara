extends SceneTree
const Organism = preload("res://scripts/organism.gd")
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var actor := Node3D.new()
	actor.set_script(Organism)
	root.add_child(actor)
	actor.configure(1,1,Vector2.ZERO,100)
	actor.set_process(false)
	var gait = actor.pigoid_gait
	var skeleton: Skeleton3D=gait.skeleton
	var head := skeleton.find_bone("Head")
	for frame in range(90):actor._process(1.0/60.0)
	var idle := skeleton.get_bone_global_pose(head).basis.get_rotation_quaternion()
	actor.set_behavior(Organism.Behavior.FEEDING)
	var min_pitch := INF
	var max_pitch := -INF
	for frame in range(240):
		actor._process(1.0/60.0)
		if frame>60:
			var angle := idle.angle_to(skeleton.get_bone_global_pose(head).basis.get_rotation_quaternion())
			min_pitch=minf(min_pitch,angle)
			max_pitch=maxf(max_pitch,angle)
			if gait.support_count()!=6:
				printerr("FAIL: feeding feet must remain planted");quit(1);return
	if max_pitch<0.18 or max_pitch-min_pitch<0.07 or actor.creature_animation.current_animation!="Feed":
		printerr("FAIL: feeding needs a visible, repeating head motion");quit(1);return
	actor.has_feeding_target=true
	actor.feeding_target=Vector2(0.45,-1.7)
	for frame in range(90):actor._process(1.0/60.0)
	if absf(gait.feeding_yaw)<0.15 or gait.support_count()!=6:
		printerr("FAIL: head must follow food without moving planted feet");quit(1);return
	actor.set_behavior(Organism.Behavior.WANDERING)
	for frame in range(90):actor._process(1.0/60.0)
	if idle.angle_to(skeleton.get_bone_global_pose(head).basis.get_rotation_quaternion())>0.01:
		printerr("FAIL: head must return to resting pose");quit(1);return
	print("PASS: visible feeding cycle, six planted feet, smooth return to idle")
	actor.queue_free()
	await process_frame
	quit()
