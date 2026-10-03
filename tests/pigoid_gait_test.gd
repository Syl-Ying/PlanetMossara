extends SceneTree
const Organism = preload("res://scripts/organism.gd")
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	for turning in [false,true]:
		if not await _scenario(turning):
			quit(1)
			return
	print("PASS: straight/turning variable-speed tripod gait and stable stop")
	quit()

func _scenario(turning: bool) -> bool:
	var actor := Node3D.new()
	actor.set_script(Organism)
	root.add_child(actor)
	actor.configure(1,1,Vector2.ZERO,100)
	actor.set_process(false)
	if actor.pigoid_gait == null:
		printerr("FAIL: missing gait controller");return false
	var max_error := 0.0
	var max_slide := 0.0
	var min_support := 6
	var last_positions := {}
	var last_anchors := {}
	for frame in range(600):
		var speed: float = [0.48,1.35,3.4,0.7,0.0][mini(frame/120,4)] if turning else (0.7 if frame<480 else 0.0)
		actor.move_velocity=Vector2(0,-speed).rotated(frame/60.0*0.3 if turning else 0.0)
		actor.sim_position += actor.move_velocity/60.0
		actor._sync_transform()
		actor._process(1.0/60.0)
		var gait = actor.pigoid_gait
		min_support = mini(min_support,gait.support_count())
		for leg in gait.legs:
			var actual: Vector3 = gait.skeleton.to_global(gait.skeleton.get_bone_global_pose(leg.foot).origin)
			if frame>60 and not leg.swing:
				max_error=maxf(max_error,actual.distance_to(leg.target))
				if last_positions.has(leg.foot) and last_anchors[leg.foot].is_equal_approx(leg.anchor):
					max_slide=maxf(max_slide,actual.distance_to(last_positions[leg.foot]))
			last_positions[leg.foot]=actual
			last_anchors[leg.foot]=leg.anchor
	print("GAIT: max planted error=",max_error," max frame slide=",max_slide," minimum supports=",min_support)
	if max_error>0.025 or max_slide>0.015 or min_support<3 or actor.pigoid_gait.support_count()!=6:
		printerr("FAIL: feet must remain planted, >=3 support during gait, all 6 settle after stopping")
		return false
	actor.queue_free()
	await process_frame
	print("PASS: stance feet stay fixed through body sway, tripods alternate, stop settles all feet")
	return true
