extends Node3D

const HiHatModel = preload("res://assets/models/vesta_hihat_cluster_3d.tscn")
const ForegroundModel = preload("res://assets/models/vesta_foreground_flora_3d.tscn")

var rng := RandomNumberGenerator.new()
var breathing_parts: Array[Node3D] = []


func _ready() -> void:
	rng.seed = 48201
	_place_reference_models()



func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for part in breathing_parts:
		var phase: float = part.get_meta("phase")
		var base_rotation: Vector3 = part.get_meta("base_rotation")
		part.rotation = base_rotation + Vector3(
			sin(time * 0.31 + phase) * 0.018,
			cos(time * 0.19 + phase) * 0.014,
			sin(time * 0.27 + phase) * 0.022
		)


func get_mesh_count() -> int:
	return find_children("*", "MeshInstance3D", true, false).size()


func _material(color: Color, transparent := false, emission := Color.TRANSPARENT) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.metallic_specular = 0.16
	material.rim_enabled = false
	material.rim = 0.34
	material.rim_tint = 0.48
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission.a > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 0.22
	return material


func _place_reference_models() -> void:
	var groves := [Vector3(-27, 0, -27), Vector3(27, 0, -30),
		Vector3(-35, 0, 4), Vector3(35, 0, 9)]
	for index in groves.size():
		var grove := HiHatModel.instantiate() as Node3D
		grove.name = "ReferenceHiHatGrove_%02d" % index
		grove.position = groves[index]
		grove.rotation.y = -0.35 + index * 0.65
		grove.scale = Vector3.ONE * (0.85 + index * 0.10)
		add_child(grove)
		_register_sway(grove, index * 1.3)
	var beds := [Vector3(-6, 0, 5), Vector3(7, 0, 2), Vector3(-10, 0, -6),
		Vector3(17, 0, -17), Vector3(-26, 0, 12), Vector3(26, 0, 19)]
	for index in beds.size():
		var bed := ForegroundModel.instantiate() as Node3D
		bed.name = "ReferenceFloraBed_%02d" % index
		bed.position = beds[index]
		bed.rotation.y = -0.15 + index * 0.31
		bed.scale = Vector3.ONE * (0.9 + float(index % 3) * 0.08)
		add_child(bed)
		_register_sway(bed, index * 2.1)
		_add_creature_barrier(bed)


func _register_sway(model: Node3D, phase: float) -> void:
	for part in model.find_children("Sway_*", "Node3D", true, false):
		# Only animate anchored leaf/frond roots, never detached stem segments.
		if part is MeshInstance3D:
			continue
		part.set_meta("phase", phase + breathing_parts.size() * 0.37)
		part.set_meta("base_rotation", part.rotation)
		breathing_parts.append(part)

func _add_creature_barrier(bed: Node3D) -> void:
	var bounds := AABB()
	var first := true
	for mesh in bed.find_children("*", "MeshInstance3D", true, false):
		var local: AABB = (bed.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds = local if first else bounds.merge(local)
		first=false
	if first:return
	var body := StaticBody3D.new()
	body.name="CreatureFoliageBarrier"
	body.collision_layer=4
	body.collision_mask=0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=Vector3(bounds.size.x+0.2,1.5,bounds.size.z+0.2)
	collider.shape=shape
	collider.position=Vector3(bounds.get_center().x,0.75,bounds.get_center().z)
	body.add_child(collider)
	bed.add_child(body)
