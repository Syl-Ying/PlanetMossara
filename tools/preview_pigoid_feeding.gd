extends SceneTree
const Organism = preload("res://scripts/organism.gd")
class Rehearsal extends Node:
	var actor: Node3D
	var elapsed := 0.0
	func _process(delta: float) -> void:
		elapsed += delta
		var speed := minf(elapsed/0.6,1.0)*0.7 if elapsed < 2.0 else maxf(0.0,0.7-(elapsed-2.0)*2.0)
		actor.move_velocity = Vector2(0,-speed)
		actor.set_behavior(3 if elapsed>=2.4 and elapsed<7.0 else 1)
		actor.sim_position += actor.move_velocity*delta
		actor._sync_transform()
class SideCamera extends Camera3D:
	var actor: Node3D
	func _process(_delta: float) -> void:
		global_position=actor.global_position+Vector3(3.5,1.55,0.4)
		look_at(actor.global_position+Vector3(0,0.9,0))
func _initialize() -> void:call_deferred("_setup")
func _setup() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	world.get_node("QuietInterface").hide()
	world.get_node("Walker").set_physics_process(false)
	var ecology=world.get_node("VestaEcology")
	ecology.set_physics_process(false)
	for other in ecology.organisms:
		if other.species!=0:
			other.hide()
			other.set_process(false)
	var actor := Node3D.new()
	actor.set_script(Organism)
	world.add_child(actor)
	actor.configure(100,1,Vector2(0,17),100)
	var driver := Rehearsal.new()
	driver.actor=actor
	driver.process_priority=-20
	world.add_child(driver)
	var camera := SideCamera.new()
	camera.actor=actor
	camera.process_priority=100
	camera.fov=43
	world.add_child(camera)
	camera.current=true
