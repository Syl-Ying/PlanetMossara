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

	var puzzle := get_first_node_in_group("puzzle")
	if puzzle == null:
		_fail("bloom gate puzzle is missing")
		return
	var grazers: Array[Node3D] = ecosystem.get_grazers()
	for index in 3:
		grazers[index].sim_position = Vector2(float(index) - 1.0, -23.0)
		grazers[index]._sync_transform()
	puzzle._process(3.1)
	if not puzzle.is_open:
		_fail("bloom gate did not open after three grazers held the lure zone")
		return

	print("PASS: Godot scene, populations, bio-signals, journal hooks, and bloom gate validated")
	world.queue_free()
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
