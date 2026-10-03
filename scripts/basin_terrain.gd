extends Node3D
## Low relief, fractured basalt and clustered gravel over the continuous tidal field.
const BotanicalMesh = preload("res://scripts/botanical_mesh.gd")
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 70619
	_build_stones()
	_build_banks()
	_build_horizon()
	_build_foreground_shoals()

func _pigment(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/botanical_ink.gdshader")
	material.set_shader_parameter("pigment", color)
	material.set_shader_parameter("grain", 0.015)
	return material

func _rock_mesh(seed_phase: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for j in range(4):
		var ring := PackedVector3Array()
		for i in range(9):
			var a := TAU * i / 9.0
			var radius: float = [1.0, 0.94, 0.65, 0.08][j] * (1.0 + 0.18 * sin(i * 7.3 + seed_phase))
			var y: float = [0.0, 0.30, 0.83, 1.0][j]
			ring.append(Vector3(cos(a) * radius + y * 0.17, y * (0.9 + sin(i * 3.7 + seed_phase) * 0.13), sin(a) * radius))
		rings.append(ring)
	for j in range(3):
		for i in range(9):
			var k := (i + 1) % 9
			for v in [rings[j][i], rings[j][k], rings[j+1][k], rings[j][i], rings[j+1][k], rings[j+1][i]]:
				st.add_vertex(v)
	for i in range(9):
		st.add_vertex(rings[3][i])
		st.add_vertex(rings[3][(i + 1) % 9])
		st.add_vertex(Vector3(0.17,1.0,0))
	st.generate_normals()
	st.index()
	return st.commit()

func _build_stones() -> void:
	for variant in range(4):
		var gravel := MultiMeshInstance3D.new()
		gravel.name = "ScatteredGravel_%d" % variant
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _rock_mesh(variant * 2.3)
		multimesh.instance_count = 170
		gravel.multimesh = multimesh
		gravel.material_override = _pigment([Color("41404b"),Color("55515b"),Color("706b68"),Color("474753")][variant])
		for i in range(170):
			# Small clusters break the evenly sprinkled appearance; some isolated fragments remain.
			var cluster := Vector3(sin(float(i / 14)*19.3+variant)*43.0,0.0,cos(float(i / 14)*11.7+variant)*43.0)
			var center := cluster + Vector3(rng.randfn(0.0,1.4),-0.008,rng.randfn(0.0,0.55))
			if i % 5 == 0:
				center = Vector3(rng.randf_range(-53,53),-0.008,rng.randf_range(-53,53))
			var size := rng.randf_range(0.045,0.23)
			var basis := Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3(size*1.5,size*0.55,size))
			multimesh.set_instance_transform(i,Transform3D(basis,center))
		add_child(gravel)
	var sites := [Vector3(-4,0,5),Vector3(8,0,-6),Vector3(-17,0,-12),Vector3(16,0,12),Vector3(-23,0,17),Vector3(27,0,-23)]
	for i in sites.size():
		for piece in range(5):
			var rock := MeshInstance3D.new()
			rock.name = "Basalt_%d_%d" % [i,piece]
			rock.mesh = _rock_mesh(i + piece * 0.8)
			rock.material_override = _pigment(Color("45414e") if piece % 2 == 0 else Color("55515a"))
			rock.position = sites[i] + Vector3(piece * 0.48,0.0,sin(piece*2.1)*0.4)
			rock.scale = Vector3(0.65 + piece * 0.17, 0.22 + (piece % 3) * 0.20,0.60 + piece * 0.12)
			rock.rotation.y = i + piece * 2.3
			add_child(rock)
			# Convex collision follows the low stone mound, so walking remains grounded.
			rock.create_convex_collision()

func _build_banks() -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/basin_ground.gdshader")
	for i in range(18):
		var shoal := MeshInstance3D.new()
		shoal.name = "LowSiltBank_%02d" % i
		shoal.mesh = _rock_mesh(i * 1.37)
		shoal.material_override = material
		shoal.position = Vector3(rng.randf_range(-49,49),-0.015,rng.randf_range(-49,35))
		shoal.scale = Vector3(rng.randf_range(1.8,4.8),rng.randf_range(0.035,0.075),rng.randf_range(0.4,1.0))
		shoal.rotation.y = rng.randf_range(-0.2,0.2)
		add_child(shoal)

func _build_horizon() -> void:
	# Low distant basin shelves break the flat square edge without blocking the walkable area.
	for i in range(15):
		var shelf := MeshInstance3D.new()
		shelf.name = "DistantBasinShelf_%02d" % i
		shelf.mesh = _rock_mesh(i * 0.7)
		shelf.material_override = _pigment(Color("73798b"))
		var angle := TAU * i / 15.0
		shelf.position = Vector3(cos(angle)*115.0,-0.2,sin(angle)*115.0)
		shelf.scale = Vector3(17.0 + i % 3 * 6.0,3.0 + i % 4 * 1.7,12.0)
		shelf.rotation.y = angle
		add_child(shelf)

func _build_foreground_shoals() -> void:
	# Real shallow banks with eroded ledges, rather than flat painted shore outlines.
	var sites := [Vector3(-3.8,0,10.3),Vector3(4.8,0,6.8),Vector3(-7.0,0,0.5)]
	var sizes := [Vector2(2.7,0.95),Vector2(3.2,1.1),Vector2(2.5,1.0)]
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/basin_ground.gdshader")
	material.set_shader_parameter("raised_silt",true)
	for index in sites.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rings: Array[PackedVector3Array] = []
		for layer in range(5):
			var ring := PackedVector3Array()
			for i in range(64):
				var a := TAU*i/64.0
				var erosion := 1.0+0.10*sin(a*5.0+index)+0.055*sin(a*13.0+index*2.1)+0.025*sin(a*23.0)
				var radius: float = [1.0,0.96,0.91,0.86,0.70][layer]*erosion
				var height: float = [-0.012,0.025,0.047,0.10,0.14][layer]
				height += sin(a*3.0+index)*0.012*layer/4.0
				ring.append(Vector3(cos(a)*sizes[index].x*radius,height,sin(a)*sizes[index].y*radius))
			rings.append(ring)
		for layer in range(4):
			for i in range(64):
				var k := (i+1)%64
				for point in [rings[layer][i],rings[layer][k],rings[layer+1][k],rings[layer][i],rings[layer+1][k],rings[layer+1][i]]:
					st.add_vertex(point)
		for i in range(64):
			for point in [rings[4][i],rings[4][(i+1)%64],Vector3(0,0.145,0)]:
				st.add_vertex(point)
		st.generate_normals()
		st.index()
		var bank := MeshInstance3D.new()
		bank.name = "ErodedShore_%d" % index
		bank.mesh=st.commit()
		bank.material_override=material
		bank.position=sites[index]
		add_child(bank)
		bank.create_trimesh_collision()
		var fragments := MultiMeshInstance3D.new()
		fragments.name="EmbeddedShoreFragments_%d" % index
		var batch := MultiMesh.new()
		batch.transform_format=MultiMesh.TRANSFORM_3D
		batch.mesh=_rock_mesh(index+0.6)
		batch.instance_count=45
		fragments.multimesh=batch
		fragments.material_override=_pigment(Color("54515a"))
		for i in range(45):
			var a := rng.randf_range(-PI,PI)
			var radius := sqrt(rng.randf())*0.53
			var size := rng.randf_range(0.025,0.10)
			var point: Vector3 = sites[index]+Vector3(cos(a)*sizes[index].x*radius,0.137,sin(a)*sizes[index].y*radius)
			var basis := Basis(Vector3.UP,a).scaled(Vector3(size*1.9,size*0.48,size))
			batch.set_instance_transform(i,Transform3D(basis,point))
		add_child(fragments)
