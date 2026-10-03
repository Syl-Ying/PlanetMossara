extends SceneTree
class FollowCamera extends Camera3D:
	var target: Node3D
	func _process(_delta: float) -> void:
		global_position = target.global_position + Vector3(3.0, 2.0, 3.6)
		look_at(target.global_position + Vector3(0,0.9,0))
func _initialize() -> void:
	call_deferred("_setup")
func _setup() -> void:
	var world: Node3D = load("res://main.tscn").instantiate()
	root.add_child(world)
	world.get_node("QuietInterface").hide()
	world.get_node("Walker").set_physics_process(false)
	var camera := FollowCamera.new()
	camera.target = world.get_node("VestaEcology").organisms[24]
	camera.process_priority = 100
	camera.fov = 46
	world.add_child(camera)
	camera.current = true
