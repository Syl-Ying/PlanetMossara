extends RefCounted

const BotanicalMesh = preload("res://scripts/botanical_mesh.gd")


func build_hihat_cluster() -> Node3D:
	var root := Node3D.new()
	root.name = "VestaHiHatCluster3D"
	var trunk_material := _material("Trunk", Color("342f3a"), 0.86)
	var top_material := _material("CanopyTop", Color("667684"), 0.76)
	var underside_material := _material("CanopyUnderside", Color("d0cec0"), 0.88)
	var membrane_material := _material("HangingMembrane", Color("b57970"), 0.9)
	var base_material := _material("FingerFlora", Color("3e3346"), 0.9)

	var tree_specs := [
		[Vector3(0.0, 0.0, 0.0), 11.8, 2.8, 2.0, -0.18, true],
		[Vector3(-3.4, 0.0, 0.25), 8.3, 2.25, 1.62, 0.12, true],
		[Vector3(3.65, 0.0, 0.4), 7.1, 2.1, 1.5, -0.1, true],
		[Vector3(-5.5, 0.0, 0.9), 4.9, 1.4, 0.95, 0.08, false],
		[Vector3(5.35, 0.0, 1.1), 4.2, 1.25, 0.9, -0.05, false],
	]
	for index in range(tree_specs.size()):
		var spec = tree_specs[index]
		_build_hihat_tree(
			root,
			"HiHat_%02d" % index,
			spec[0], spec[1], spec[2], spec[3], spec[4], spec[5],
			trunk_material, top_material, underside_material, membrane_material
		)

	for patch_index in range(7):
		var patch_x := -4.8 + patch_index * 1.55
		for stalk_index in range(3 + patch_index % 3):
			var stalk := MeshInstance3D.new()
			stalk.name = "BaseFinger_%02d_%02d" % [patch_index, stalk_index]
			var mesh := CapsuleMesh.new()
			mesh.radius = 0.10 + stalk_index * 0.022
			mesh.height = 0.65 + float((patch_index + stalk_index) % 4) * 0.24
			mesh.radial_segments = 7
			mesh.rings = 4
			stalk.mesh = mesh
			stalk.material_override = base_material
			stalk.position = Vector3(patch_x + stalk_index * 0.24, mesh.height * 0.45, 0.35 + sin(stalk_index) * 0.28)
			stalk.rotation_degrees.z = -13.0 + stalk_index * 7.0
			root.add_child(stalk)

	_merge_static_parts(root)
	_set_owners(root, root)
	return root


func build_foreground_cluster() -> Node3D:
	var root := Node3D.new()
	root.name = "VestaForegroundFlora3D"
	var dark_material := _material("DarkFinger", Color("3e3346"), 0.9)
	var leaf_material := _material("FanLeaf", Color("7d8e70"), 0.82)
	var leaf_alt_material := _material("FanLeafShadow", Color("617965"), 0.86)
	var rib_material := _material("LeafRib", Color("46524e"), 0.9)
	var membrane_material := _material("CoralMembrane", Color("b75e4d"), 0.9)
	var cup_material := _material("SporeCup", Color("7894a0"), 0.68)
	var cup_inside_material := _material("SporeCupInside", Color("27323a"), 0.76, false, Color("40515a"))
	var pearl_material := _material("PearlGrowth", Color("d5cdb7"), 0.58)

	var finger_specs := [
		[-5.2, 2.8, -9.0], [-4.35, 1.55, 12.0], [-3.7, 1.2, -8.0],
		[-2.45, 1.9, 7.0], [-0.8, 1.35, -5.0], [0.45, 1.55, 8.0],
		[2.25, 1.25, -12.0], [3.9, 1.7, 6.0], [5.15, 2.6, -7.0], [5.75, 1.75, 10.0],
	]
	for index in range(finger_specs.size()):
		var spec = finger_specs[index]
		var base := Vector3(spec[0], 0.0, 0.9 + sin(index * 1.7) * 0.32)
		var mid := base + Vector3(spec[2] * 0.012, spec[1] * 0.48, 0.0)
		var tip := base + Vector3(spec[2] * 0.018, spec[1], 0.08)
		var points: Array[Vector3] = []
		var radii: Array[float] = []
		for section in range(21):
			var t := section / 20.0
			points.append(base + Vector3(spec[2] * 0.05 * t * t + sin(t * PI) * 0.12, spec[1] * t, sin(t * PI) * 0.14))
			radii.append((0.16 + spec[1] * 0.045) * pow(maxf(0.0, sin(PI * (0.12 + t * 0.88))), 0.32))
		_add_custom(root, "RoundedFinger_%02d" % index, BotanicalMesh.tube(points, radii), dark_material)
		for root_index in range(4):
			var angle := root_index * 1.8 + index
			var root_points: Array[Vector3] = []
			var root_radii: Array[float] = []
			for section in range(13):
				var t := section / 12.0
				root_points.append(base + Vector3(cos(angle + t * 0.7) * t * 1.15, 0.12 * (1.0 - t), sin(angle + t * 0.7) * t * 0.65))
				root_radii.append(0.095 * pow(1.0 - t, 0.9))
			_add_custom(root, "Root_%d_%d" % [index, root_index], BotanicalMesh.tube(root_points, root_radii, 9), dark_material)
		if index % 2 == 0:
			for pearl_index in range(2):
				var pearl := MeshInstance3D.new()
				pearl.name = "Pearl_%02d_%02d" % [index, pearl_index]
				var pearl_mesh := SphereMesh.new()
				pearl_mesh.radius = 0.105
				pearl_mesh.height = 0.08
				pearl_mesh.radial_segments = 8
				pearl_mesh.rings = 4
				pearl.mesh = pearl_mesh
				pearl.material_override = pearl_material
				pearl.position = mid.lerp(tip, 0.25 + pearl_index * 0.22) + Vector3(0.13, 0.0, 0.0)
				root.add_child(pearl)

	var leaf_specs := [
		[Vector3(-3.55, 0.0, -0.15), 2.55, -17.0, 1.65],
		[Vector3(-2.0, 0.0, -0.4), 2.0, 14.0, 1.40],
		[Vector3(-0.6, 0.0, 0.1), 2.25, -8.0, 1.5],
		[Vector3(1.9, 0.0, -0.45), 2.35, 12.0, 1.6],
		[Vector3(3.35, 0.0, -0.25), 2.7, -10.0, 1.7],
	]
	for index in range(leaf_specs.size()):
		var spec = leaf_specs[index]
		_build_fan_leaf(root, "FanLeaf_%02d" % index, spec[0], spec[1], spec[2], spec[3], leaf_material if index % 2 == 0 else leaf_alt_material, rib_material)

	_build_coral_frond(root, Vector3(-0.15, 0.0, -0.25), 4.5, 18.0, membrane_material, rib_material, "CoralTall")
	_build_coral_frond(root, Vector3(0.6, 0.0, -0.15), 3.5, -22.0, membrane_material, rib_material, "CoralShort")

	for cup_index in range(11):
		var x := -5.5 + cup_index * 1.05
		var height := 0.45 + float((cup_index * 7) % 5) * 0.13
		var base := Vector3(x, 0.0, 1.1 + sin(cup_index * 1.9) * 0.4)
		var tip := base + Vector3(sin(cup_index) * 0.12, height, 0.0)
		_add_segment(root, base, tip, 0.025, 0.052, rib_material, "CupStalk_%02d" % cup_index, 7)
		_add_spore_cup(root, tip, cup_material, cup_inside_material, "SporeCup_%02d" % cup_index)

	for vine_index in range(7):
		var start := Vector3(-5.7 + vine_index * 1.8, 0.08, 0.35 + sin(vine_index) * 0.35)
		var end := start + Vector3(1.25, 0.0, cos(vine_index) * 0.5)
		_add_segment(root, start, end, 0.035, 0.06, dark_material, "GroundVine_%02d" % vine_index, 7)

	_merge_static_parts(root)
	_set_owners(root, root)
	return root


func _build_hihat_tree(parent: Node3D, node_name: String, origin: Vector3, height: float, width: float, depth: float, lean: float, has_membrane: bool, trunk_material: Material, top_material: Material, underside_material: Material, membrane_material: Material) -> void:
	var tree := Node3D.new()
	tree.name = node_name
	tree.position = origin
	parent.add_child(tree)
	var crown := Vector3(lean * height * 0.16, height, 0.0)
	var mid := Vector3(lean * height * 0.08, height * 0.55, 0.05)
	_add_segment(tree, Vector3.ZERO, mid, 0.19, 0.42, trunk_material, node_name + "_TrunkLower", 10)
	_add_segment(tree, mid, crown, 0.09, 0.21, trunk_material, node_name + "_TrunkUpper", 10)
	for root_index in range(5):
		var angle := TAU * root_index / 5.0
		_add_segment(tree, Vector3(0.0, 0.3, 0.0), Vector3(cos(angle) * 1.25, 0.04, sin(angle) * 0.75), 0.045, 0.2, trunk_material, node_name + "_Root_%02d" % root_index, 7)
	for branch_index in range(8):
		var angle := TAU * branch_index / 8.0
		var endpoint := crown + Vector3(cos(angle) * width * 0.78, -0.15, sin(angle) * depth * 0.76)
		_add_segment(tree, crown - Vector3(0.0, 0.38, 0.0), endpoint, 0.032, 0.075, trunk_material, node_name + "_CanopyRib_%02d" % branch_index, 7)
	var underside := MeshInstance3D.new()
	underside.name = node_name + "_Underside"
	var underside_mesh := CylinderMesh.new()
	underside_mesh.top_radius = width * 0.72
	underside_mesh.bottom_radius = width * 0.9
	underside_mesh.height = 0.22
	underside_mesh.radial_segments = 16
	underside.mesh = underside_mesh
	underside.material_override = underside_material
	underside.position = crown - Vector3(0.0, 0.18, 0.0)
	underside.scale.z = depth / width
	tree.add_child(underside)
	var top := MeshInstance3D.new()
	top.name = node_name + "_CanopyTop"
	top.mesh = BotanicalMesh.lathe([
		Vector2(0, 0.32), Vector2(0.30, 0.29), Vector2(0.66, 0.16),
		Vector2(0.92, 0.035), Vector2(1.0, 0), Vector2(0.92, -0.04),
		Vector2(0.45, -0.09), Vector2(0, -0.12)], 48, 0.035)
	top.material_override = top_material
	top.position = crown + Vector3(0.0, 0.21, 0.0)
	top.scale = Vector3(width, 1.0, depth)
	tree.add_child(top)
	if has_membrane:
		for strip_index in range(2):
			var pivot := Node3D.new()
			pivot.name = "Sway_%s_Membrane_%02d" % [node_name, strip_index]
			pivot.position = crown + Vector3((-0.6 if strip_index == 0 else 0.6) * width, -0.2, depth * 0.48)
			tree.add_child(pivot)
			var strip := MeshInstance3D.new()
			strip.name = "PerforatedHangingVeil"
			strip.mesh = BotanicalMesh.veil(height * 0.3, width * 0.34)
			strip.material_override = membrane_material
			strip.rotation.z = PI
			pivot.add_child(strip)
	var body := StaticBody3D.new()
	body.name = "TrunkCollision"
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = height
	collision.shape = shape
	collision.position = crown * 0.5
	body.add_child(collision)
	tree.add_child(body)


func _build_fan_leaf(parent: Node3D, node_name: String, base: Vector3, height: float, tilt_degrees: float, width: float, leaf_material: Material, rib_material: Material) -> void:
	var leaf_root := Node3D.new()
	leaf_root.name = "Sway_" + node_name
	leaf_root.position = base
	leaf_root.rotation_degrees.z = tilt_degrees
	parent.add_child(leaf_root)
	var stalk_tip := Vector3(0.0, height * 0.44, 0.0)
	_add_segment(leaf_root, Vector3.ZERO, stalk_tip, 0.035, 0.08, rib_material, node_name + "_Stalk", 8)
	var leaf := MeshInstance3D.new()
	leaf.name = node_name + "_PleatedSurface"
	leaf.mesh = BotanicalMesh.fan(height, width)
	leaf.material_override = leaf_material
	leaf_root.add_child(leaf)
	for rib in range(9):
		var u := -1.0 + rib * 0.25
		for section in range(5):
			var start := BotanicalMesh.fan_point(u, section / 5.0, height, width) + Vector3(0, 0, 0.023)
			var end := BotanicalMesh.fan_point(u, (section + 1) / 5.0, height, width) + Vector3(0, 0, 0.023)
			_add_segment(leaf_root, start, end, 0.004, 0.007, rib_material, "Rib_%d_%d" % [rib, section], 5)


func _build_coral_frond(parent: Node3D, base: Vector3, height: float, tilt_degrees: float, membrane_material: Material, spine_material: Material, node_name: String) -> void:
	var frond := Node3D.new()
	frond.name = "Sway_" + node_name
	frond.position = base
	frond.rotation_degrees.z = tilt_degrees
	parent.add_child(frond)
	var p0 := Vector3.ZERO
	var p1 := Vector3(0.1, height * 0.34, 0.0)
	var p2 := Vector3(-0.12, height * 0.68, 0.04)
	var p3 := Vector3(0.05, height, 0.0)
	_add_segment(frond, p0, p1, 0.035, 0.085, spine_material, node_name + "_Spine0", 7)
	_add_segment(frond, p1, p2, 0.025, 0.052, spine_material, node_name + "_Spine1", 7)
	_add_segment(frond, p2, p3, 0.012, 0.035, spine_material, node_name + "_Spine2", 7)
	var membrane := MeshInstance3D.new()
	membrane.name = node_name + "_PerforatedSheet"
	membrane.mesh = BotanicalMesh.veil(height, height * 0.18)
	membrane.material_override = membrane_material
	frond.add_child(membrane)


func _add_spore_cup(parent: Node3D, position: Vector3, cup_material: Material, inside_material: Material, node_name: String) -> void:
	var cup := MeshInstance3D.new()
	cup.name = node_name
	var profile: Array[Vector2] = [
		Vector2(0.0, -0.08), Vector2(0.09, -0.07), Vector2(0.18, 0.04),
		Vector2(0.20, 0.16), Vector2(0.17, 0.18), Vector2(0.14, 0.12),
		Vector2(0.11, 0.01), Vector2(0.0, -0.02)]
	profile.reverse()
	cup.mesh = BotanicalMesh.lathe(profile, 24, 0.045)
	cup.material_override = cup_material
	cup.position = position + Vector3(0.0, 0.08, 0.0)
	parent.add_child(cup)
	var center := MeshInstance3D.new()
	center.name = node_name + "_Inside"
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.12
	center_mesh.bottom_radius = 0.12
	center_mesh.height = 0.014
	center_mesh.radial_segments = 10
	center.mesh = center_mesh
	center.material_override = inside_material
	center.position = position + Vector3(0.0, 0.07, 0.0)
	parent.add_child(center)


func _material(resource_name: String, color: Color, _roughness: float, _transparent := false, _emission := Color.TRANSPARENT) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.resource_name = resource_name
	material.shader = preload("res://assets/shaders/botanical_ink.gdshader")
	material.set_shader_parameter("pigment", color)
	var outline := ShaderMaterial.new()
	outline.shader = preload("res://assets/shaders/botanical_outline.gdshader")
	if resource_name not in ["LeafRib", "PearlGrowth", "SporeCupInside"]:
		material.next_pass = outline
	return material


func _add_segment(parent: Node3D, start: Vector3, end: Vector3, top_radius: float, bottom_radius: float, material: Material, node_name: String, radial_segments := 8) -> MeshInstance3D:
	var direction := end - start
	var segment := MeshInstance3D.new()
	segment.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = direction.length()
	mesh.radial_segments = radial_segments
	segment.mesh = mesh
	segment.material_override = material
	segment.position = (start + end) * 0.5
	segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
	parent.add_child(segment)
	return segment


func _set_owners(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owners(child, owner)


func _merge_static_parts(node: Node3D) -> void:
	# Keep animated pivots and collisions; batch stationary pieces by material.
	var groups := {}
	for child in node.get_children():
		if child is MeshInstance3D:
			var material: Material = child.material_override
			if not groups.has(material):
				groups[material] = []
			groups[material].append(child)
		elif child is Node3D:
			_merge_static_parts(child)
	for material in groups:
		var parts: Array = groups[material]
		if parts.size() < 2:
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in parts:
			surface.append_from(part.mesh, 0, part.transform)
		surface.index()
		var merged := MeshInstance3D.new()
		merged.name = material.resource_name + "_SculptedMesh"
		merged.mesh = surface.commit()
		merged.material_override = material
		node.add_child(merged)
		for part in parts:
			part.free()


func _add_custom(parent: Node3D, node_name: String, mesh: Mesh, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	part.material_override = material
	parent.add_child(part)
