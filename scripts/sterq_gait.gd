extends "res://scripts/pigoid_gait.gd"
## Four-beat crawl, world-anchored feet, cascading tail follow and reversible frill display.
var tail_headings: Array[float] = []
var frill_open := 0.0

func setup(owner_node: Node3D, model: Node3D) -> void:
	stride = 0.32
	stance = 0.81
	lift = 0.055
	pair_count = 2
	body_drop = 0.055
	super.setup(owner_node,model)
	# LH -> LF -> RH -> RF, one swing at a time, three planted supports.
	var offsets := [0.25,0.75,0.0,0.5]
	for i in legs.size():legs[i].group = offsets[i]*2.0
	for i in range(3):tail_headings.append(actor.global_rotation.y)

func update(delta: float, moving: bool, speed: float) -> void:
	super.update(delta,moving,speed)
	var feeding: bool = actor.behavior == actor.Behavior.FEEDING and not moving
	feeding_blend=move_toward(feeding_blend,1.0 if feeding else 0.0,delta*1.8)
	feeding_time+=delta
	var head := skeleton.find_bone("Head")
	var head_rest := skeleton.get_bone_global_rest(head)
	# A deliberate dip followed by a longer recovery, rather than constant bobbing.
	var cycle := fposmod(feeding_time,1.6)/1.6
	var dip := pow(maxf(0.0,sin(cycle*TAU)),2.0)
	var desired_yaw := 0.0
	if feeding and actor.has_feeding_target:
		var target_point := Vector3(actor.feeding_target.x,actor.global_position.y,actor.feeding_target.y)
		var direction := skeleton.global_basis.inverse()*(target_point-actor.global_position)
		desired_yaw=clampf(atan2(direction.x,direction.z),-0.4,0.4)
	feeding_yaw=lerp_angle(feeding_yaw,desired_yaw,1.0-exp(-4.0*delta))
	var base_rotation := skeleton.get_bone_global_pose(head).basis.get_rotation_quaternion()
	var feeding_rotation := Quaternion(Vector3.UP,feeding_yaw)*Quaternion(Vector3.RIGHT,0.16+dip*0.20)*head_rest.basis.get_rotation_quaternion()
	_aim(head,base_rotation.slerp(feeding_rotation,feeding_blend))
	var heading := actor.global_rotation.y
	for i in range(3):
		var target := heading if i==0 else tail_headings[i-1]
		tail_headings[i] = lerp_angle(tail_headings[i],target,1.0-exp(-[6.0,4.0,3.0][i]*delta))
		var lag := clampf(wrapf(tail_headings[i]-heading,-PI,PI),-0.65,0.65)
		var sway := sin(phase*TAU-i*0.65)*0.018*body_blend
		var bone := skeleton.find_bone("Tail%d" % i)
		var rest := skeleton.get_bone_global_rest(bone)
		_aim(bone,Quaternion(Vector3.UP,lag+sway)*rest.basis.get_rotation_quaternion())
	var alert: bool = actor.behavior == actor.Behavior.HUNTING or actor.behavior == actor.Behavior.FLEEING
	var display := 1.0 if alert else (0.45 if feeding else 0.0)
	frill_open = move_toward(frill_open,display,delta*(1.4 if alert else 0.45))
	for side in ["L","R"]:
		var bone := skeleton.find_bone("Frill_"+side)
		var rest := skeleton.get_bone_global_rest(bone)
		var sign_value := -1.0 if side=="L" else 1.0
		var fold := sign_value*(1.0-frill_open)*0.65
		_aim(bone,Quaternion(Vector3.UP,fold)*rest.basis.get_rotation_quaternion())
