extends Node3D

const OrganismScript := preload("res://scripts/organism.gd")
const FIXED_STEP := 1.0 / 30.0
const WORLD_HALF_EXTENT := 45.0

var organisms: Array[Node3D] = []
var bio_signals: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var next_id := 1
var elapsed_seconds := 0.0
var accumulator := 0.0


func _ready() -> void:
	add_to_group("ecosystem")
	rng.seed = 1337
	_populate_default_world()


func _physics_process(delta: float) -> void:
	accumulator += minf(delta, 0.25)
	while accumulator >= FIXED_STEP:
		_step_simulation(FIXED_STEP)
		accumulator -= FIXED_STEP


func _populate_default_world() -> void:
	for _index in 24:
		_add_organism(
			LivingOrganism.Species.GLOW_REED,
			Vector2(rng.randf_range(-42.0, 42.0), rng.randf_range(-42.0, 42.0)),
			rng.randf_range(45.0, 100.0)
		)
	for _index in 5:
		var direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		_add_organism(LivingOrganism.Species.BURROW_GRAZER, direction * rng.randf_range(5.0, 34.0), rng.randf_range(50.0, 90.0))
	# Three grazers begin close enough to the first puzzle to teach signal-based herding.
	_add_organism(LivingOrganism.Species.BURROW_GRAZER, Vector2(-7.0, -19.0), 82.0)
	_add_organism(LivingOrganism.Species.BURROW_GRAZER, Vector2(7.0, -21.0), 76.0)
	_add_organism(LivingOrganism.Species.BURROW_GRAZER, Vector2(1.0, -15.0), 88.0)
	for _index in 3:
		var direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		_add_organism(LivingOrganism.Species.VEIL_STALKER, direction * rng.randf_range(24.0, 41.0), rng.randf_range(55.0, 95.0))


func _add_organism(species: int, start_position: Vector2, energy: float) -> Node3D:
	var organism := Node3D.new()
	organism.name = "Organism_%03d" % next_id
	organism.set_script(OrganismScript)
	add_child(organism)
	organism.configure(next_id, species, start_position, energy)
	next_id += 1
	organisms.append(organism)
	return organism


func _step_simulation(delta: float) -> void:
	elapsed_seconds += delta
	_update_signals(delta)

	for organism in organisms:
		if organism.species == LivingOrganism.Species.GLOW_REED:
			organism.energy = minf(100.0, organism.energy + 0.7 * delta)
			organism.set_behavior(LivingOrganism.Behavior.ROOTED)

	for organism in organisms:
		if organism.species == LivingOrganism.Species.BURROW_GRAZER:
			_update_grazer(organism, delta)
		elif organism.species == LivingOrganism.Species.VEIL_STALKER:
			_update_stalker(organism, delta)

	for organism in organisms:
		if organism.species == LivingOrganism.Species.GLOW_REED:
			continue
		organism.sim_position += organism.move_velocity * delta
		organism.sim_position.x = clampf(organism.sim_position.x, -WORLD_HALF_EXTENT, WORLD_HALF_EXTENT)
		organism.sim_position.y = clampf(organism.sim_position.y, -WORLD_HALF_EXTENT, WORLD_HALF_EXTENT)
		organism._sync_transform()


func _update_signals(delta: float) -> void:
	for index in range(bio_signals.size() - 1, -1, -1):
		bio_signals[index]["ttl"] = float(bio_signals[index]["ttl"]) - delta
		if float(bio_signals[index]["ttl"]) <= 0.0:
			var visual: Node = bio_signals[index]["visual"]
			visual.queue_free()
			bio_signals.remove_at(index)


func _update_grazer(grazer: Node3D, delta: float) -> void:
	var nearest_stalker := _nearest_species(grazer, LivingOrganism.Species.VEIL_STALKER, true)
	if nearest_stalker and grazer.sim_position.distance_squared_to(nearest_stalker.sim_position) < 144.0:
		grazer.move_velocity = grazer.sim_position.direction_to(nearest_stalker.sim_position) * -7.0
		grazer.set_behavior(LivingOrganism.Behavior.FLEEING)
		grazer.energy = maxf(0.0, grazer.energy - 0.8 * delta)
		return

	var nutrient := _strongest_signal("nutrient", grazer.sim_position)
	if not nutrient.is_empty():
		grazer.move_velocity = grazer.sim_position.direction_to(nutrient["position"]) * 3.6
		grazer.set_behavior(LivingOrganism.Behavior.ATTRACTED)
		return

	var nearest_reed := _nearest_species(grazer, LivingOrganism.Species.GLOW_REED, false)
	if nearest_reed:
		var distance_squared: float = grazer.sim_position.distance_squared_to(nearest_reed.sim_position)
		if distance_squared < 3.24 and nearest_reed.energy >= 8.0:
			var bite := minf(nearest_reed.energy, 7.0 * delta)
			nearest_reed.energy -= bite
			grazer.energy = minf(100.0, grazer.energy + bite * 0.65)
			grazer.move_velocity = Vector2.ZERO
			grazer.set_behavior(LivingOrganism.Behavior.FEEDING)
		elif distance_squared < 900.0:
			grazer.move_velocity = grazer.sim_position.direction_to(nearest_reed.sim_position) * 2.4
			grazer.set_behavior(LivingOrganism.Behavior.FORAGING)
		else:
			_wander(grazer, 0.37, 1.2)
	else:
		_wander(grazer, 0.37, 1.2)
	grazer.energy = maxf(0.0, grazer.energy - 0.16 * delta)


func _update_stalker(stalker: Node3D, delta: float) -> void:
	var defensive := _strongest_signal("light", stalker.sim_position)
	if not defensive.is_empty():
		stalker.move_velocity = stalker.sim_position.direction_to(defensive["position"]) * -8.0
		stalker.set_behavior(LivingOrganism.Behavior.FLEEING)
		stalker.energy = maxf(0.0, stalker.energy - 0.5 * delta)
		return

	var nearest_grazer := _nearest_species(stalker, LivingOrganism.Species.BURROW_GRAZER, true)
	if nearest_grazer:
		var distance_squared: float = stalker.sim_position.distance_squared_to(nearest_grazer.sim_position)
		if distance_squared < 1.82:
			var feeding := minf(nearest_grazer.energy, 14.0 * delta)
			nearest_grazer.energy -= feeding
			stalker.energy = minf(100.0, stalker.energy + feeding * 0.45)
			stalker.move_velocity = Vector2.ZERO
			stalker.set_behavior(LivingOrganism.Behavior.FEEDING)
		elif distance_squared < 1444.0:
			stalker.move_velocity = stalker.sim_position.direction_to(nearest_grazer.sim_position) * 3.1
			stalker.set_behavior(LivingOrganism.Behavior.HUNTING)
		else:
			_wander(stalker, 0.21, 1.0)
	else:
		_wander(stalker, 0.21, 1.0)
	stalker.energy = maxf(0.0, stalker.energy - 0.22 * delta)


func _wander(organism: Node3D, frequency: float, speed: float) -> void:
	var angle: float = elapsed_seconds * frequency + organism.organism_id * 1.71
	organism.move_velocity = Vector2(cos(angle), sin(angle)) * speed
	organism.set_behavior(LivingOrganism.Behavior.WANDERING)


func _nearest_species(source: Node3D, wanted_species: int, require_energy: bool) -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := INF
	for candidate in organisms:
		if candidate == source or candidate.species != wanted_species:
			continue
		if require_energy and candidate.energy <= 0.0:
			continue
		var distance: float = source.sim_position.distance_squared_to(candidate.sim_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest


func _strongest_signal(kind: String, source_position: Vector2) -> Dictionary:
	var strongest: Dictionary = {}
	var strongest_score := 0.0
	for signal_data in bio_signals:
		if signal_data["kind"] != kind:
			continue
		var distance_squared := source_position.distance_squared_to(signal_data["position"])
		if distance_squared > float(signal_data["radius"]) ** 2:
			continue
		var score := float(signal_data["strength"]) / maxf(1.0, distance_squared)
		if score > strongest_score:
			strongest_score = score
			strongest = signal_data
	return strongest


func create_bio_signal(kind: String, world_position: Vector3) -> void:
	var radius := 18.0 if kind == "nutrient" else 16.0
	var lifetime := 8.0 if kind == "nutrient" else 5.0
	var color := Color("f0cf66") if kind == "nutrient" else Color("8feaff")
	var visual := _create_signal_visual(radius, color)
	visual.position = Vector3(world_position.x, 0.04, world_position.z)
	add_child(visual)
	bio_signals.append({
		"kind": kind,
		"position": Vector2(world_position.x, world_position.z),
		"radius": radius,
		"strength": 5.0,
		"ttl": lifetime,
		"visual": visual,
	})
	get_tree().call_group("hud", "show_ecology_message", "Nutrient lure released" if kind == "nutrient" else "Defensive light released")


func _create_signal_visual(radius: float, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.035
	visual.mesh = disc
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.18)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	return visual


func get_snapshot() -> Dictionary:
	var snapshot := {
		"reeds": 0,
		"grazers": 0,
		"stalkers": 0,
		"fleeing": 0,
		"signals": bio_signals.size(),
		"seconds": elapsed_seconds,
	}
	for organism in organisms:
		if organism.species == LivingOrganism.Species.GLOW_REED:
			snapshot["reeds"] += 1
		elif organism.species == LivingOrganism.Species.BURROW_GRAZER:
			snapshot["grazers"] += 1
		else:
			snapshot["stalkers"] += 1
		if organism.behavior == LivingOrganism.Behavior.FLEEING:
			snapshot["fleeing"] += 1
	return snapshot


func count_grazers_near(center: Vector2, radius: float) -> int:
	var count := 0
	var radius_squared := radius * radius
	for organism in organisms:
		if organism.species == LivingOrganism.Species.BURROW_GRAZER \
		and organism.energy > 0.0 \
		and organism.sim_position.distance_squared_to(center) <= radius_squared:
			count += 1
	return count


func get_grazers() -> Array[Node3D]:
	var grazers: Array[Node3D] = []
	for organism in organisms:
		if organism.species == LivingOrganism.Species.BURROW_GRAZER:
			grazers.append(organism)
	return grazers


func discover_species_near(center: Vector2, radius: float) -> Array[String]:
	var discoveries: Array[String] = []
	var radius_squared := radius * radius
	for organism in organisms:
		if organism.sim_position.distance_squared_to(center) > radius_squared:
			continue
		var species_name := ""
		if organism.species == LivingOrganism.Species.GLOW_REED:
			species_name = "Glow Reed"
		elif organism.species == LivingOrganism.Species.BURROW_GRAZER:
			species_name = "Burrow Grazer"
		else:
			species_name = "Veil Stalker"
		if species_name not in discoveries:
			discoveries.append(species_name)
	return discoveries
