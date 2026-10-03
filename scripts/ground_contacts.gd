extends Node3D
## Bounded reusable landing effects; one emission per completed foot swing.
const CAPACITY := 96
const LIFETIME := 7.0
var effects: Array[MeshInstance3D] = []
var ages: Array[float] = []
var cursor := 0
var landing_count := 0
func _ready() -> void:
	add_to_group("ground_contacts")
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.2,1.2)
	for i in range(CAPACITY):
		var effect := MeshInstance3D.new()
		effect.mesh = plane
		effect.layers = 2 # Contact overlays must not render into the planar reflection.
		effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/ground_contact.gdshader")
		effect.material_override = material
		effect.hide()
		add_child(effect)
		effects.append(effect)
		ages.append(LIFETIME)
func land(point: Vector3, yaw: float, species: int) -> void:
	var effect := effects[cursor]
	effect.global_position = point+Vector3.UP*0.006
	effect.rotation.y = yaw
	var material := effect.material_override as ShaderMaterial
	material.set_shader_parameter("age",0.0)
	material.set_shader_parameter("landing_point",point)
	material.set_shader_parameter("species_size",1.0 if species==1 else 0.8)
	ages[cursor]=0.0
	effect.show()
	cursor=(cursor+1)%CAPACITY
	landing_count+=1
func _process(delta: float) -> void:
	for i in range(CAPACITY):
		if ages[i]>=LIFETIME:continue
		ages[i]+=delta
		if ages[i]>=LIFETIME:
			effects[i].hide()
		else:
			effects[i].material_override.set_shader_parameter("age",ages[i])
