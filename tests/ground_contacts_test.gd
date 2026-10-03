extends SceneTree
const Organism = preload("res://scripts/organism.gd")
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var effects := Node3D.new()
	effects.set_script(preload("res://scripts/ground_contacts.gd"))
	root.add_child(effects)
	effects.set_process(false)
	for species in [1,2]:
		var actor := Node3D.new()
		actor.set_script(Organism)
		root.add_child(actor)
		actor.configure(species,species,Vector2.ZERO,100)
		actor.set_process(false)
		var before: int=effects.landing_count
		for frame in range(180):
			actor.move_velocity=Vector2(0,-0.7)
			actor.sim_position+=actor.move_velocity/60.0
			actor._sync_transform()
			actor._process(1.0/60.0)
		if effects.landing_count<=before:
			printerr("FAIL: walking must emit contacts for both species");quit(1);return
		actor.move_velocity=Vector2.ZERO
		for frame in range(120):actor._process(1.0/60.0)
		var stopped: int=effects.landing_count
		for frame in range(120):actor._process(1.0/60.0)
		if effects.landing_count!=stopped:
			printerr("FAIL: resting feet must not keep emitting contacts");quit(1);return
		actor.queue_free()
	for i in range(200):effects.land(Vector3.ZERO,0,1)
	if effects.get_child_count()!=96:
		printerr("FAIL: effect pool must remain bounded");quit(1);return
	effects._process(8.0)
	for effect in effects.effects:
		if effect.visible:
			printerr("FAIL: expired contacts must hide");quit(1);return
	print("PASS: both species emit on landing, no idle emissions, bounded pool and expiry")
	effects.queue_free()
	await process_frame
	quit()
