extends RefCounted
## Alternating tripod gait with world-space stance anchors and analytic two-bone IK.
var stride := 0.66
var stance := 0.62
var lift := 0.105
var pair_count := 3
var body_drop := 0.15
var skeleton: Skeleton3D
var actor: Node3D
var legs: Array[Dictionary] = []
var phase := 0.0
var travel := 0.0
var previous_position := Vector3.ZERO
var body_blend := 0.0
var ankle_clearance := 0.0
var root_bone := -1
var feeding_blend := 0.0
var feeding_time := 0.0
var feeding_yaw := 0.0
var contacts: Node
var antenna_materials: Array[ShaderMaterial] = []

func setup(owner_node: Node3D, model: Node3D) -> void:
	actor = owner_node
	contacts = actor.get_tree().get_first_node_in_group("ground_contacts")
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	root_bone = skeleton.find_bone("Root")
	previous_position = actor.global_position
	for pair in range(pair_count):
		for side in ["L", "R"]:
			var prefix := "Leg%d_%s" % [pair,side]
			var upper := skeleton.find_bone(prefix+"_Upper")
			var lower := skeleton.find_bone(prefix+"_Lower")
			var foot := skeleton.find_bone(prefix+"_Foot")
			var hip_rest := skeleton.get_bone_global_rest(upper)
			var knee_rest := skeleton.get_bone_global_rest(lower)
			var ankle_rest := skeleton.get_bone_global_rest(foot)
			var axis := (ankle_rest.origin-hip_rest.origin).normalized()
			var bend := knee_rest.origin-hip_rest.origin
			bend = (bend-axis*bend.dot(axis)).normalized()
			ankle_clearance = ankle_rest.origin.y * model.scale.y
			var anchor := _ground(skeleton.to_global(ankle_rest.origin))
			legs.append({"upper":upper,"lower":lower,"foot":foot,
				"hip_rest":hip_rest,"knee_rest":knee_rest,"ankle_rest":ankle_rest,
				"length_a":hip_rest.origin.distance_to(knee_rest.origin),
				"length_b":knee_rest.origin.distance_to(ankle_rest.origin),"bend":bend,
				"group":(pair+(0 if side=="L" else 1))%2,
				"anchor":anchor,"target":anchor,"start":anchor,"goal":anchor,
				"swing":false,"was_swing":false,"progress":0.0,"duration":0.3})
	for mesh in model.find_children("Antenna*", "MeshInstance3D", true, false):
		var material := mesh.get_surface_override_material(0) as ShaderMaterial
		if material:
			material.set_shader_parameter("antenna",true)
			antenna_materials.append(material)

func _ground(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP, point-Vector3.UP*2.0)
	query.collision_mask = 1
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	var height: float = hit.position.y if not hit.is_empty() else 0.0
	return Vector3(point.x,height+ankle_clearance,point.z)

func update(delta: float, moving: bool, speed: float) -> void:
	var displacement := actor.global_position-previous_position
	previous_position = actor.global_position
	var distance := Vector2(displacement.x,displacement.z).length()
	if distance > 2.0:
		for leg in legs:
			leg.anchor = _ground(skeleton.to_global(leg.ankle_rest.origin))
			leg.swing = false
			leg.was_swing = false
		distance = 0.0
	# Cadence follows actual rendered displacement, not an independently advancing clip.
	if moving:
		travel += distance
		phase = fposmod(travel / stride,1.0)
	body_blend = move_toward(body_blend,1.0 if moving else 0.0,delta*3.0)
	var root_rest := skeleton.get_bone_rest(root_bone)
	var shift := Vector3(sin(phase*TAU)*0.013,-body_drop+cos(phase*TAU*2.0)*0.008*body_blend,0)
	skeleton.set_bone_pose_position(root_bone,root_rest.origin+shift)
	skeleton.set_bone_pose_rotation(root_bone,root_rest.basis.get_rotation_quaternion()*Quaternion(Vector3.FORWARD,sin(phase*TAU)*0.008*body_blend))
	# Preserve mouth clearance while the knees carry a slightly lower body.
	var head := skeleton.find_bone("Head")
	var root_basis := skeleton.get_bone_global_pose(root_bone).basis
	skeleton.set_bone_pose_position(head,skeleton.get_bone_rest(head).origin+root_basis.inverse()*Vector3(0,body_drop,0))
	if pair_count == 3:
		_update_feeding(delta,moving,head)
	var forward := -actor.global_basis.z.normalized()
	for leg in legs:
		var local_phase := fposmod(phase+leg.group*0.5,1.0)
		var phase_swing := local_phase >= stance and moving
		if phase_swing and not leg.was_swing and not leg.swing:
			leg.swing = true
			leg.progress = 0.0
			leg.start = leg.anchor
			leg.duration = clampf(stride*(1.0-stance)/maxf(speed,0.15),0.09,1.2)
			var nominal := skeleton.to_global(leg.ankle_rest.origin)
			leg.goal = _ground(nominal+forward*stride*(1.0-stance+stance*0.5))
		leg.was_swing = phase_swing
		if leg.swing:
			leg.progress = clampf((local_phase-stance)/(1.0-stance),0.0,1.0) if moving and phase_swing else minf(1.0,leg.progress+delta/leg.duration)
			# A wrapped phase means this foot has completed its swing.
			if moving and not phase_swing:leg.progress = 1.0
			var t: float = leg.progress
			var ease := t*t*t*(10.0+t*(-15.0+6.0*t))
			leg.target = leg.start.lerp(leg.goal,ease)+Vector3.UP*lift*pow(sin(PI*t),2)
			if t >= 1.0:
				leg.anchor = leg.goal
				if is_instance_valid(contacts):
					contacts.land(leg.anchor-Vector3.UP*ankle_clearance,actor.global_rotation.y,actor.species)
				leg.target = leg.anchor
				leg.swing = false
		else:
			leg.target = leg.anchor
		_solve(leg,skeleton.to_local(leg.target))
	for material in antenna_materials:
		material.set_shader_parameter("sway_phase",travel/stride*TAU)
		material.set_shader_parameter("sway_strength",body_blend)

func _aim(bone: int, desired: Quaternion) -> void:
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	# Godot bone pose rotation is the full local rotation, not a rest-relative delta.
	skeleton.set_bone_pose_rotation(bone,(parent_basis.get_rotation_quaternion().inverse()*desired).normalized())

func _solve(leg: Dictionary, target: Vector3) -> void:
	var hip := skeleton.get_bone_global_pose(leg.upper).origin
	var direction := target-hip
	var a: float = leg.length_a
	var b: float = leg.length_b
	var distance := clampf(direction.length(),absf(a-b)+0.001,a+b-0.001)
	direction = direction.normalized()
	var bend: Vector3 = leg.bend-direction*leg.bend.dot(direction)
	if bend.length_squared()<0.001:bend = direction.cross(Vector3.RIGHT)
	bend = bend.normalized()
	var along := (a*a-b*b+distance*distance)/(2.0*distance)
	var knee := hip+direction*along+bend*sqrt(maxf(0.0,a*a-along*along))
	var rest_upper: Vector3 = (leg.knee_rest.origin-leg.hip_rest.origin).normalized()
	_aim(leg.upper,Quaternion(rest_upper,(knee-hip).normalized())*leg.hip_rest.basis.get_rotation_quaternion())
	var actual_knee := skeleton.get_bone_global_pose(leg.lower).origin
	var rest_lower: Vector3 = (leg.ankle_rest.origin-leg.knee_rest.origin).normalized()
	_aim(leg.lower,Quaternion(rest_lower,(target-actual_knee).normalized())*leg.knee_rest.basis.get_rotation_quaternion())
	# Keep the hoof's world orientation stable throughout stance and swing.
	var world_rotation: Quaternion = leg.get("foot_rotation",Quaternion.IDENTITY)
	if not leg.has("foot_rotation"):
		world_rotation = skeleton.global_basis.get_rotation_quaternion()*leg.ankle_rest.basis.get_rotation_quaternion()
		leg.foot_rotation = world_rotation
	if leg.swing:
		var desired: Quaternion = skeleton.global_basis.get_rotation_quaternion()*leg.ankle_rest.basis.get_rotation_quaternion()
		world_rotation = world_rotation.slerp(desired,0.2)
		leg.foot_rotation = world_rotation
	_aim(leg.foot,skeleton.global_basis.get_rotation_quaternion().inverse()*world_rotation)

func support_count() -> int:
	var count := 0
	for leg in legs:
		if not leg.swing:count+=1
	return count

func _update_feeding(delta: float, moving: bool, head: int) -> void:
	var feeding: bool = actor.behavior == actor.Behavior.FEEDING and not moving
	feeding_blend = move_toward(feeding_blend,1.0 if feeding else 0.0,delta*1.8)
	feeding_time += delta
	var cycle := sin(feeding_time*TAU*0.85)
	var rest := skeleton.get_bone_global_rest(head)
	# Raise the resting head, then lower and probe rhythmically while feeding.
	var pitch := lerpf(-0.14,0.045+cycle*0.045,feeding_blend)
	var target_yaw := 0.0
	if feeding and actor.has_feeding_target:
		var target := Vector3(actor.feeding_target.x,actor.global_position.y,actor.feeding_target.y)
		var local_direction := skeleton.global_basis.inverse()*(target-actor.global_position)
		target_yaw=clampf(atan2(local_direction.x,local_direction.z),-0.45,0.45)
	feeding_yaw=lerp_angle(feeding_yaw,target_yaw,1.0-exp(-4.0*delta))
	_aim(head,Quaternion(Vector3.UP,feeding_yaw*feeding_blend)*Quaternion(Vector3.RIGHT,pitch)*rest.basis.get_rotation_quaternion())
	var parent := skeleton.get_bone_parent(head)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis
	var probe := Vector3(0,(0.04+0.035*(1.0-cycle))*feeding_blend,0.055*feeding_blend)
	skeleton.set_bone_pose_position(head,skeleton.get_bone_pose_position(head)+parent_basis.inverse()*probe)
	# The pad is rigidly attached to Head; keep it above the actual terrain when nodding.
	var pad_rest := Vector3(0,0.065,2.17)
	var pad := skeleton.to_global(skeleton.get_bone_global_pose(head)*rest.affine_inverse()*pad_rest)
	var floor_height := _ground(pad).y-ankle_clearance+0.035
	if pad.y<floor_height:
		var correction := skeleton.global_basis.inverse()*Vector3.UP*(floor_height-pad.y)
		skeleton.set_bone_pose_position(head,skeleton.get_bone_pose_position(head)+parent_basis.inverse()*correction)
