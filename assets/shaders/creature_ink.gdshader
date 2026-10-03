shader_type spatial;
render_mode unshaded;
uniform vec4 pigment : source_color = vec4(0.6,0.6,0.6,1.0);
uniform sampler2D skin_map : source_color, filter_linear_mipmap;
uniform bool use_skin_map = false;
uniform bool antenna = false;
uniform float sway_phase = 0.0;
uniform float sway_strength = 0.0;
varying vec3 world_normal;
void vertex() {
 if (antenna) {
  float tip = max(0.0, VERTEX.y - 1.08);
  VERTEX.x += tip * tip * 0.045 * sin(sway_phase - tip * 1.4) * sway_strength;
 }
 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL); }
void fragment() {
 vec3 color = pigment.rgb;
 if (use_skin_map) { color *= texture(skin_map, UV).rgb; }
 float diffuse = dot(normalize(world_normal),normalize(vec3(-0.5,0.8,0.4)));
 float shade = mix(0.61,1.0,smoothstep(-0.35,0.65,diffuse));
 float rim = smoothstep(0.03,0.23,abs(dot(normalize(NORMAL),normalize(VIEW))));
 ALBEDO = color * shade * mix(0.62,1.0,rim);
}
