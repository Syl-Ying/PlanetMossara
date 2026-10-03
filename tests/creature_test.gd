extends SceneTree
const Organism = preload("res://scripts/organism.gd")
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("FAIL: ", message)
		quit(1)
	return ok
func _run() -> void:
	for species in [1,2]:
		var creature := Node3D.new()
		creature.set_script(Organism)
		root.add_child(creature)
		creature.configure(species,species,Vector2.ZERO,100.0)
		creature.set_process(false)
		var skeletons := creature.find_children("*", "Skeleton3D", true, false)
		if not _check(skeletons.size()==1,"one imported skeleton required"):return
		var skeleton := skeletons[0] as Skeleton3D
		var limbs := 0
		for bone in skeleton.get_bone_count():
			if skeleton.get_bone_name(bone).ends_with("_Upper"):limbs+=1
		if not _check(limbs==(6 if species==1 else 4),"incorrect limb count"):return
		var player: AnimationPlayer = creature.creature_animation
		for clip in ["Idle","Walk","Feed" if species==1 else "Alert"]:
			if not _check(player.has_animation(clip),"missing clip "+clip):return
			player.play(clip,0)
			for t in [0.0,0.25,0.5,1.0,1.5]:
				player.seek(t,true)
				await process_frame
				for bone in skeleton.get_bone_count():
					var pose := skeleton.get_bone_global_pose(bone)
					if not _check(pose.origin.is_finite() and pose.origin.length()<12,"invalid animation pose"):return
		player.play("Walk",0)
		player.seek(0,true)
		await process_frame
		var leg := skeleton.find_bone("Leg0_L_Upper")
		var start := skeleton.get_bone_pose_rotation(leg)
		player.seek(0.5,true)
		await process_frame
		if not _check(start.angle_to(skeleton.get_bone_pose_rotation(leg))>0.01,"walk clip does not move leg bones"):return
		creature.set_process(true)
		creature.move_velocity=Vector2(1,0)
		creature._process(0.016)
		if not _check(player.current_animation=="Walk","locomotion not connected to animation"):return
		creature.move_velocity=Vector2.ZERO
		creature.set_behavior(Organism.Behavior.FEEDING if species==1 else Organism.Behavior.HUNTING)
		creature._process(0.016)
		if not _check(player.current_animation==("Feed" if species==1 else "Alert"),"behavior not connected to animation"):return
		creature.queue_free()
		await process_frame
	print("PASS: imported 6/4-limb skeletons, three clips per species, finite moving bones, and behavior-driven transitions")
	quit(0)
