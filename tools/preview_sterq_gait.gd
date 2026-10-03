extends SceneTree
const Organism = preload("res://scripts/organism.gd")
class Rehearsal extends Node:
	var actor: Node3D
	var elapsed := 0.0
	func _process(delta: float) -> void:
		elapsed += delta
		var speed := minf(elapsed/0.6,1.0)*0.7 if elapsed < 5.0 else maxf(0.0,0.7-(elapsed-5.0)*2.0)
		actor.move_velocity = Vector2(0,-speed).rotated(clampf((elapsed-2.5)/2.5,0.0,1.0)*1.2)
		actor.set_behavior(4 if elapsed>=5.5 and elapsed<7.5 else 1)
		actor.sim_position += actor.move_velocity*delta
		actor._sync_transform()
class SideCamera extends Camera3D:
	var actor: Node3D
	func _process(_delta: float) -> void:
		global_position=actor.global_position+Vector3(3.2,1.8,3.2)
		look_at(actor.global_position+Vector3(0,0.55,0))
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
	actor.configure(100,2,Vector2(0,17),100)
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
