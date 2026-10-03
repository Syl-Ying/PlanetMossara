extends SceneTree
func _initialize() -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file("res://assets/spacecraft/models/crashed_capsule.glb",state)
	if error!=OK:
		printerr("FAIL: GLB parse failed ",error);quit(1);return
	var model := document.generate_scene(state)
	if model==null:
		printerr("FAIL: GLB did not generate a scene");quit(1);return
	root.add_child(model)
	var meshes := model.find_children("*","MeshInstance3D",true,false)
	var triangles := 0
	for mesh in meshes:
		if not mesh.transform.is_finite() or mesh.mesh==null:
			printerr("FAIL: invalid mesh/transform");quit(1);return
		for surface in mesh.mesh.get_surface_count():
			triangles+=mesh.mesh.surface_get_array_index_len(surface)/3
	if meshes.size()<30 or triangles<1000:
		printerr("FAIL: incomplete capsule");quit(1);return
	print("PASS: capsule GLB loads in Godot; meshes=",meshes.size()," triangles=",triangles)
	model.queue_free()
	quit()
