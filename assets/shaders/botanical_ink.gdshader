shader_type spatial;
render_mode unshaded;
uniform vec4 pigment : source_color = vec4(0.5, 0.6, 0.5, 1.0);
uniform float grain = 0.035;
varying vec3 local_position;
varying vec3 world_normal;
void vertex() {
 local_position = VERTEX;
 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
 vec3 n = normalize(world_normal);
 float light = dot(n, normalize(vec3(-0.4, 0.8, 0.6)));
 float shade = mix(0.73, 1.06, smoothstep(-0.4, 0.65, light));
 float fleck = fract(sin(dot(floor(local_position * 67.0), vec3(12.9898,78.233,39.425))) * 43758.5453);
 float mottling = sin(local_position.x * 10.0 + sin(local_position.y * 9.0)) * sin(local_position.z * 13.0 + local_position.y * 5.0);
 float edge = smoothstep(0.03, 0.3, abs(dot(normalize(NORMAL), normalize(VIEW))));
 ALBEDO = pigment.rgb * shade * mix(0.60, 1.0, edge) * (1.0 + mottling * 0.025 - step(0.965, fleck) * grain * 4.0);
}
