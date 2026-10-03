shader_type spatial;
render_mode unshaded, cull_front;
void vertex() { VERTEX += NORMAL * 0.004; }
void fragment() { ALBEDO = vec3(0.045, 0.039, 0.052); }
