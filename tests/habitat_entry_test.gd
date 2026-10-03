extends SceneTree
var site: Node3D
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	site=load("res://assets/spacecraft/crash_site.tscn").instantiate()
	root.add_child(site)
	var ground:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(30,0.2,30)
	shape.shape=box
	shape.position.y=-0.1
	ground.add_child(shape)
	root.add_child(ground)
	var player:=CharacterBody3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.38
	capsule.height=1.8
	var collision:=CollisionShape3D.new()
	collision.shape=capsule
	player.add_child(collision)
	root.add_child(player)
	player.position=Vector3(-0.325,1.0,-4.6)
	await physics_frame
	for frame in range(240):
		await physics_frame
		player.velocity.z=1.5 if player.position.z<-.35 else 0.0
		player.velocity.y-=18.0/60.0
		player.move_and_slide()
	print("Entry position: ",player.position)
	if player.position.z<-.6 or player.position.y<1.5 or player.position.y>1.8:
		printerr("FAIL: full-height player cannot enter and stand on cabin floor");quit(1);return
	# Cross the cabin then walk back down the same ramp.
	for frame in range(120):
		await physics_frame
		player.velocity=Vector3(0,-0.3,0.6 if player.position.z<.45 else 0.0)
		player.move_and_slide()
	if player.position.z<.3:
		printerr("FAIL: cabin aisle is obstructed");quit(1);return
	for frame in range(240):
		await physics_frame
		player.velocity.z=-1.5
		player.velocity.y-=18.0/60.0
		player.move_and_slide()
	print("Exit position: ",player.position)
	if player.position.z>-4.0 or player.position.y>1.0:
		printerr("FAIL: player cannot leave cabin");quit(1);return
	print("PASS: 1.8 m tall / 0.76 m wide player enters, crosses cabin, and exits via ramp")
	quit()
