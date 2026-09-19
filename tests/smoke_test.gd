extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load("res://main.tscn")
	if packed_scene == null:
		_fail("main scene could not be loaded")
		return
	var world := packed_scene.instantiate()
	root.add_child(world)
	for _frame in 12:
		await physics_frame

	var ecosystem := get_first_node_in_group("ecosystem")
	if ecosystem == null:
		_fail("ecosystem group is missing")
		return
	var snapshot: Dictionary = ecosystem.get_snapshot()
	if snapshot["reeds"] != 24 or snapshot["grazers"] != 8 or snapshot["stalkers"] != 3:
		_fail("unexpected default population: %s" % snapshot)
		return

	ecosystem.create_bio_signal("nutrient", Vector3.ZERO)
	ecosystem.create_bio_signal("light", Vector3(4.0, 0.0, 4.0))
	await physics_frame
	snapshot = ecosystem.get_snapshot()
	if snapshot["signals"] != 2:
		_fail("signals were not registered")
		return

	if world.get_node_or_null("BloomGatePuzzle") != null:
		_fail("task-driven bloom gate should not exist in quiet-walk mode")
		return
	var ambience := world.get_node_or_null("VestaAmbience/RainBasinBed") as AudioStreamPlayer
	if ambience == null or ambience.stream == null or not ambience.playing:
		_fail("procedural ambience is missing")
		return
	if world.get_node_or_null("HiHatTree_00") == null:
		_fail("Vesta scenery is missing")
		return
	if world.get_node_or_null("IllustratedHiHat_00") == null or world.get_node_or_null("IllustratedFlora_00") == null:
		_fail("illustrated 2.5D vegetation layers are missing")
		return
	var discovered: Array[String] = ecosystem.discover_species_near(
		Vector2(ecosystem.organisms[0].sim_position.x, ecosystem.organisms[0].sim_position.y), 0.5
	)
	if "Spore Tree" not in discovered:
		_fail("Vesta species naming is not connected to observations")
		return

	print("PASS: quiet-walk scene, Vesta ecology, ambience, observations, and optional bio-signals validated")
	world.queue_free()
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
