extends Node
## Half-resolution planar reflection shared by the connected pools.
var reflection_view: SubViewport
var reflection_camera: Camera3D
var surface: ShaderMaterial

func _ready() -> void:
	process_priority = 200
	var ground := get_parent().get_node("PaleRainBasin") as MeshInstance3D
	surface = ground.material_override as ShaderMaterial
	# Never render water into its own reflection texture (including raised silt meshes).
	for mesh in get_parent().find_children("*", "MeshInstance3D", true, false):
		var material = mesh.material_override
		if material is ShaderMaterial and material.shader == surface.shader:
			mesh.layers = 2
	reflection_view = SubViewport.new()
	reflection_view.name = "BasinReflectionViewport"
	reflection_view.size = Vector2i(640,360)
	reflection_view.world_3d = get_viewport().world_3d
	reflection_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	reflection_view.audio_listener_enable_3d = false
	add_child(reflection_view)
	reflection_camera = Camera3D.new()
	reflection_camera.cull_mask = 1
	reflection_view.add_child(reflection_camera)
	reflection_camera.current = true
	surface.set_shader_parameter("reflection_texture",reflection_view.get_texture())

func _process(_delta: float) -> void:
	var source := get_viewport().get_camera_3d()
	if not source or source.global_position.y < 0.08:
		surface.set_shader_parameter("reflection_enabled",false)
		return
	var origin := source.global_position
	origin.y = -origin.y
	var forward := -source.global_basis.z
	forward.y = -forward.y
	var up := source.global_basis.y
	up = Vector3(-up.x,up.y,-up.z)
	reflection_camera.global_position = origin
	reflection_camera.look_at(origin+forward,up)
	reflection_camera.fov = source.fov
	reflection_camera.keep_aspect = source.keep_aspect
	reflection_camera.near = source.near
	reflection_camera.far = minf(source.far,180.0)
	var size := get_viewport().get_visible_rect().size
	var target_size := Vector2i(maxi(1,int(size.x*0.5)),maxi(1,int(size.y*0.5)))
	if reflection_view.size != target_size:reflection_view.size = target_size
	var projection := reflection_camera.get_camera_projection()*Projection(reflection_camera.global_transform.affine_inverse())
	surface.set_shader_parameter("reflection_projection",projection)
	surface.set_shader_parameter("reflection_enabled",true)

func _exit_tree() -> void:
	if surface:
		surface.set_shader_parameter("reflection_enabled",false)
		surface.set_shader_parameter("reflection_texture",null)
