extends RefCounted
## Swept clearance checks for simulation-driven creatures (render transforms stay interpolated).
static func radius(actor: Node3D) -> float:
	if actor.species == 0:return 0.35
	return 1.35 if actor.species == 1 else 1.65

static func move(actor: Node3D, neighbors: Array[Node3D], delta: float) -> void:
	var desired: Vector2 = actor.move_velocity*delta
	if desired.length_squared()<0.0000001:return
	var holding: bool = actor.avoidance_time>0.0
	actor.avoidance_time=maxf(0.0,actor.avoidance_time-delta)
	if holding:desired=actor.avoidance_direction*desired.length()
	var best := Vector2.ZERO
	var score := -1.0
	var preference := 1.0 if actor.organism_id%2==0 else -1.0
	for angle in [0.0,0.45*preference,-0.45*preference,0.9*preference,-0.9*preference,1.3*preference,-1.3*preference,1.57*preference,-1.57*preference,2.1*preference,-2.1*preference,2.7*preference,-2.7*preference,PI]:
		var candidate := desired.rotated(angle)
		var fraction := _safe_fraction(actor,neighbors,candidate)
		candidate *= fraction
		var merit := candidate.length()*(0.55+0.45*cos(angle))
		if merit>score:
			score=merit
			best=candidate
		if angle==0.0 and fraction>0.999:break
	# Keep a chosen detour briefly; otherwise the goal pulls the animal back into the wall every tick.
	if best.length()>0.0001 and (not holding or best.normalized().dot(desired.normalized())<0.5):
		if best.normalized().dot(desired.normalized())<0.8:
			actor.avoidance_direction=best.normalized()
			actor.avoidance_time=0.85
	actor.sim_position+=best
	actor.move_velocity=best/delta

static func _safe_fraction(actor: Node3D, neighbors: Array[Node3D], motion: Vector2) -> float:
	var fraction := 1.0
	# Treat the walkable boundary like a wall so fleeing creatures can turn along it.
	for axis in range(2):
		if motion[axis]>0.0:
			fraction=minf(fraction,maxf(0.0,(44.95-actor.sim_position[axis])/motion[axis]))
		elif motion[axis]<0.0:
			fraction=minf(fraction,maxf(0.0,(-44.95-actor.sim_position[axis])/motion[axis]))
	var shape := CylinderShape3D.new()
	shape.radius=radius(actor)
	shape.height=0.65
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.collision_mask=5
	query.transform=Transform3D(Basis.IDENTITY,Vector3(actor.sim_position.x,actor._render_current.y+0.58,actor.sim_position.y))
	query.motion=Vector3(motion.x,0,motion.y)
	query.margin=0.015
	var sweep := actor.get_world_3d().direct_space_state.cast_motion(query)
	if sweep.size()==2 and sweep[0]<1.0:
		fraction=minf(fraction,maxf(0.0,sweep[0]-0.025/motion.length()))
	# Casts can report a safe fraction at a contact boundary; validate the endpoint too.
	var start := query.transform.origin
	query.motion=Vector3.ZERO
	query.transform.origin=start+Vector3(motion.x,0,motion.y)*fraction
	var space := actor.get_world_3d().direct_space_state
	if not space.intersect_shape(query,1).is_empty():
		var low := 0.0
		var high := fraction
		for iteration in range(12):
			var middle := (low+high)*0.5
			query.transform.origin=start+Vector3(motion.x,0,motion.y)*middle
			if space.intersect_shape(query,1).is_empty():low=middle
			else:high=middle
		fraction=maxf(0.0,low-0.01/motion.length())
	for other in neighbors:
		if other==actor:continue
		var offset: Vector2=actor.sim_position-other.sim_position
		var clearance := radius(actor)+radius(other)
		var c := offset.length_squared()-clearance*clearance
		var b := offset.dot(motion)
		if c<0.0:
			# Permit escape from a pre-existing overlap, but never deepen it.
			if b<0.0:fraction=0.0
			continue
		var a := motion.length_squared()
		var discriminant := b*b-a*c
		if discriminant>=0.0 and b<0.0:
			fraction=minf(fraction,maxf(0.0,(-b-sqrt(discriminant))/a-0.001))
	return clampf(fraction,0,1)

static func clear_position(actor: Node3D, point: Vector2, neighbors: Array[Node3D]) -> bool:
	var shape := CylinderShape3D.new()
	shape.radius=radius(actor)+0.06
	shape.height=0.65
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.collision_mask=5
	query.transform=Transform3D(Basis.IDENTITY,Vector3(point.x,0.58,point.y))
	if not actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return false
	for other in neighbors:
		if other==actor:continue
		if point.distance_to(other.sim_position)<radius(actor)+radius(other)+0.06:return false
	return true

static func settle_spawn(actor: Node3D, neighbors: Array[Node3D]) -> void:
	if clear_position(actor,actor.sim_position,neighbors):return
	var origin: Vector2=actor.sim_position
	for ring in range(1,25):
		for direction in range(32):
			var point := origin+Vector2.RIGHT.rotated(TAU*direction/32.0)*ring*0.5
			if absf(point.x)>44.0 or absf(point.y)>44.0:continue
			if clear_position(actor,point,neighbors):
				actor.sim_position=point
				actor._transform_initialized=false
				actor._sync_transform()
				return
