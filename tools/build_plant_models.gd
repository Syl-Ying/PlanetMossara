extends SceneTree


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/models"))
	var factory = load("res://scripts/plant_model_factory.gd").new()
	var models := {
		"res://assets/models/vesta_hihat_cluster_3d.tscn": factory.build_hihat_cluster(),
		"res://assets/models/vesta_foreground_flora_3d.tscn": factory.build_foreground_cluster(),
	}
	for path in models:
		var packed := PackedScene.new()
		var pack_result := packed.pack(models[path])
		if pack_result != OK:
			printerr("Could not pack %s: %s" % [path, pack_result])
			quit(1)
			return
		var save_result := ResourceSaver.save(packed, path)
		if save_result != OK:
			printerr("Could not save %s: %s" % [path, save_result])
			quit(1)
			return
		print("MODEL: %s" % path)
		models[path].free()
	quit(0)
