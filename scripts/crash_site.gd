extends Node3D
## Habitable crash-site shell with open doorway, level floor and exterior impact scar.
func _ready() -> void:
	# Use Godot's imported scene so web exports include all mesh/material dependencies.
	var capsule := preload("res://assets/spacecraft/models/habitat_capsule.glb").instantiate()
	capsule.name="CapsuleModel"
	add_child(capsule)
	for part in capsule.find_children("*","MeshInstance3D",true,false):
		# Concave shell collision preserves the doorway and usable cabin volume.
		if "Segmented ceramic shell" in part.name or "CabinFloor" in part.name or "InteriorBulkhead" in part.name or "EntryRamp" in part.name:
			part.create_trimesh_collision()
		if "Bent rear stabilizer" in part.name:
			var body := StaticBody3D.new()
			var collision := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size=part.get_aabb().size.max(Vector3.ONE*0.08)
			collision.shape=box
			collision.position=part.get_aabb().get_center()
			body.add_child(collision)
			part.add_child(body)
		for index in part.mesh.get_surface_count():
			var original := part.get_active_material(index) as StandardMaterial3D
			if original:
				var material := original.duplicate() as StandardMaterial3D
				material.albedo_color *= Color(0.65,0.65,0.65,1)
				material.roughness=maxf(material.roughness,0.65)
				part.set_surface_override_material(index,material)
	var body := StaticBody3D.new()
	body.name="CreatureOnlyHullBarrier"
	body.collision_layer=4
	body.collision_mask=0
	var collision := CollisionShape3D.new()
	var hull := CapsuleShape3D.new()
	hull.radius=2.05
	hull.height=7.25
	collision.shape=hull
	collision.rotation.z=PI/2.0
	collision.position=Vector3(0,1.75,0)
	body.add_child(collision)
	add_child(body)
	var light := OmniLight3D.new()
	light.name="CabinServiceLight"
	light.position=Vector3(0,2.65,0)
	light.light_color=Color("ffe3ae")
	light.light_energy=0.5
	light.omni_range=3.2
	light.shadow_enabled=true
	add_child(light)
	_build_scar()

func _soil(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color=color
	result.roughness=0.97
	return result

func _build_scar() -> void:
	var soil := _soil(Color("393937"))
	# The center stays at the existing walkable floor; displaced banks give the scar its depth.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array[PackedVector3Array]=[]
	for i in range(41):
		var t := i/40.0
		var width := lerpf(1.5,0.13,t)*(1.0+sin(i*1.7)*0.10)
		var center := sin(t*4.0)*0.18
		var row := PackedVector3Array()
		for j in range(7):
			var lateral := (j-3)/3.0
			var raised := pow(absf(lateral),5.0)*sin(PI*t)*0.15
			row.append(Vector3(3.0+t*11.5,0.009+raised,center+lateral*width))
		rows.append(row)
	for i in range(40):
		for j in range(6):
			for point in [rows[i][j],rows[i][j+1],rows[i+1][j+1],rows[i][j],rows[i+1][j+1],rows[i+1][j]]:
				st.add_vertex(point)
	st.generate_normals()
	var scar := MeshInstance3D.new()
	scar.name="ImpactFurrow"
	scar.mesh=st.commit()
	scar.material_override=soil
	add_child(scar)
	scar.create_trimesh_collision()
	var rng := RandomNumberGenerator.new()
	rng.seed=7401
	var fragment_material := _soil(Color("8c8775"))
	for i in range(12):
		var shard := MeshInstance3D.new()
		shard.name="TrailFragment_%02d" % i
		var mesh := PrismMesh.new()
		mesh.size=Vector3(rng.randf_range(0.13,0.40),rng.randf_range(0.03,0.09),rng.randf_range(0.12,0.30))
		shard.mesh=mesh
		shard.material_override=fragment_material
		var distance := rng.randf_range(3.5,12.0)
		shard.position=Vector3(distance,0.06,rng.randf_range(-1.0,1.0)*(1.0-distance/15.0))
		shard.rotation.y=rng.randf_range(-PI,PI)
		add_child(shard)
