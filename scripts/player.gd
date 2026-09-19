extends CharacterBody3D

const WALK_SPEED := 7.5
const ACCELERATION := 24.0
const MOUSE_SENSITIVITY := 0.0022

var camera_pivot: Node3D
var camera: Camera3D


func _ready() -> void:
	add_to_group("player")
	_build_body()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	add_child(collision)

	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position.y = 0.62
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.fov = 72.0
	camera.near = 0.08
	camera_pivot.add_child(camera)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -1.35, 1.35)
	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("release_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event.is_action_pressed("nutrient_signal"):
		get_tree().call_group("ecosystem", "create_bio_signal", "nutrient", global_position)
	elif event.is_action_pressed("light_signal"):
		get_tree().call_group("ecosystem", "create_bio_signal", "light", global_position)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var desired_direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var desired_velocity := desired_direction * WALK_SPEED
	velocity.x = move_toward(velocity.x, desired_velocity.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, ACCELERATION * delta)
	move_and_slide()
