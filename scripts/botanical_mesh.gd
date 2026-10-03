extends RefCounted
## Authored surfaces for the illustrated basin flora. No textures or billboards.

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# Godot's front faces use clockwise winding.
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(surface, a, b, c)
	_triangle(surface, a, c, d)

static func _finish(surface: SurfaceTool) -> ArrayMesh:
	surface.generate_normals()
	surface.index()
	return surface.commit()

static func fan_point(u: float, v: float, height: float, width: float) -> Vector3:
	var angle := u * 1.32
	var reach := height * (0.91 + 0.065 * cos(u * PI * 3.0) + 0.025 * sin(u * 17.0))
	return Vector3(sin(angle) * width * pow(v, 0.8), reach * cos(angle * 0.62) * v,
		0.32 * sin(v * PI * 0.9) + 0.018 * cos(u * PI * 8.0) * v + 0.12 * u * u * v)

static func fan(height: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(10):
		for i in range(32):
			var u := -1.0 + i / 16.0
			var v := j / 10.0
			var a := fan_point(u, v, height, width)
			var b := fan_point(u + 1.0 / 16.0, v, height, width)
			var c := fan_point(u + 1.0 / 16.0, v + 0.1, height, width)
			var d := fan_point(u, v + 0.1, height, width)
			var thickness := Vector3(0, 0, 0.028)
			_quad(st, a, d, c, b)
			_quad(st, a - thickness, b - thickness, c - thickness, d - thickness)
			if j == 9:
				_quad(st, d, d - thickness, c - thickness, c)
			if i == 0:
				_quad(st, a, a - thickness, d - thickness, d)
			if i == 31:
				_quad(st, b, c, c - thickness, b - thickness)
	return _finish(st)

static func _veil_point(u: float, v: float, height: float, width: float) -> Vector3:
	var taper := pow(sin(PI * clampf(v, 0.001, 0.999)), 1.3)
	return Vector3(u * width * taper + 0.55 * sin(v * PI * 1.3), v * height,
		0.14 * sin(v * PI * 2.0 + u * 1.6))

static func veil(height: float, width: float) -> ArrayMesh:
	# Concentric patches map smooth elliptical openings to contiguous sheet bands.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var holes := [Vector3(-0.24, 0.11, 0.048), Vector3(0.28, 0.28, 0.065),
		Vector3(-0.2, 0.47, 0.082), Vector3(0.27, 0.66, 0.061), Vector3(-0.18, 0.84, 0.045)]
	for h in holes.size():
		var hole: Vector3 = holes[h]
		var low: float = 0.0 if h == 0 else (hole.y + holes[h - 1].y) * 0.5
		var high: float = 1.0 if h == holes.size() - 1 else (hole.y + holes[h + 1].y) * 0.5
		var outer: Array[Vector2] = []
		var inner: Array[Vector2] = []
		for i in range(80):
			var angle := TAU * i / 80.0
			var ray := Vector2(cos(angle), sin(angle))
			var dx := ((1.0 if ray.x > 0 else -1.0) - hole.x) / ray.x if absf(ray.x) > 0.0001 else 10000.0
			var dy: float = ((high if ray.y > 0 else low) - hole.y) / ray.y if absf(ray.y) > 0.0001 else 10000.0
			outer.append(Vector2(hole.x, hole.y) + ray * minf(dx, dy))
			inner.append(Vector2(hole.x, hole.y) + Vector2(ray.x * hole.z * 3.2, ray.y * hole.z))
		for i in range(80):
			var k := (i + 1) % 80
			var a := _veil_point(outer[i].x, outer[i].y, height, width)
			var b := _veil_point(outer[k].x, outer[k].y, height, width)
			var c := _veil_point(inner[k].x, inner[k].y, height, width)
			var d := _veil_point(inner[i].x, inner[i].y, height, width)
			var t := Vector3(0, 0, 0.022)
			for layer in range(8):
				var uv0 := outer[i].lerp(inner[i], layer / 8.0)
				var uv1 := outer[k].lerp(inner[k], layer / 8.0)
				var uv2 := outer[k].lerp(inner[k], (layer + 1) / 8.0)
				var uv3 := outer[i].lerp(inner[i], (layer + 1) / 8.0)
				var p0 := _veil_point(uv0.x, uv0.y, height, width)
				var p1 := _veil_point(uv1.x, uv1.y, height, width)
				var p2 := _veil_point(uv2.x, uv2.y, height, width)
				var p3 := _veil_point(uv3.x, uv3.y, height, width)
				_quad(st, p0, p3, p2, p1)
				_quad(st, p0 - t, p1 - t, p2 - t, p3 - t)
			_quad(st, d, d - t, c - t, c)
			_quad(st, a, b, b - t, a - t)
	return _finish(st)

static func lathe(profile: Array[Vector2], segments := 32, scallop := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for i in segments:
			var points: Array[Vector3] = []
			for corner in [Vector2i(row, i), Vector2i(row + 1, i), Vector2i(row + 1, i + 1), Vector2i(row, i + 1)]:
				var angle: float = TAU * corner.y / segments
				var radius := profile[corner.x].x * (1.0 + scallop * sin(angle * 7.0))
				points.append(Vector3(cos(angle) * radius, profile[corner.x].y, sin(angle) * radius))
			_quad(st, points[0], points[1], points[2], points[3])
	return _finish(st)

static func tube(points: Array[Vector3], radii: Array[float], segments := 14) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for j in points.size():
		var tangent := (points[mini(j + 1, points.size() - 1)] - points[maxi(j - 1, 0)]).normalized()
		var axis := Vector3.FORWARD
		if absf(tangent.dot(axis)) > 0.95:
			axis = Vector3.RIGHT
		var right := tangent.cross(axis).normalized()
		var forward := tangent.cross(right).normalized()
		var ring := PackedVector3Array()
		for i in segments:
			var angle := TAU * i / segments
			ring.append(points[j] + radii[j] * (right * cos(angle) + forward * sin(angle)))
		rings.append(ring)
	for j in range(points.size() - 1):
		for i in segments:
			var k := (i + 1) % segments
			_quad(st, rings[j][i], rings[j + 1][i], rings[j + 1][k], rings[j][k])
	return _finish(st)
