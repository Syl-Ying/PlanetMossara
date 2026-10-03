shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
#include "res://assets/shaders/basin_field.gdshaderinc"
uniform float age = 8.0;
uniform float species_size = 1.0;
uniform vec3 landing_point;
varying vec3 world_point;
void vertex() { world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=(UV-0.5)*1.2;
 float r=length(p);
 // Classify the landing itself, then clip the effect at the same shoreline as the ground.
 float water=(1.0-smoothstep(0.478,0.482,basin_field(landing_point.xz)))*(1.0-step(0.025,landing_point.y));
 float local_water=1.0-smoothstep(0.478,0.482,basin_field(world_point.xz));
 float radius=0.04+age*0.32;
 float ring=exp(-pow((r-radius)/0.012,2.0));
 float ring2=exp(-pow((r-radius*0.72)/0.009,2.0))*0.4;
 float ripple=(ring+ring2)*pow(max(0.0,1.0-age/1.5),1.7)*water*local_water;
 vec2 sole=p/vec2(0.065,0.115)/species_size;
 float footprint=1.0-smoothstep(0.65,1.0,length(sole));
 // Split toe silhouette rather than a round blot.
 footprint*=smoothstep(0.0,0.012,abs(p.x)+smoothstep(-0.03,0.03,p.y)*0.04);
 float print_fade=smoothstep(0.0,0.08,age)*(1.0-smoothstep(3.0,7.0,age));
 float stamp=footprint*print_fade*(1.0-water)*(1.0-local_water*(1.0-step(0.025,landing_point.y)));
 ALBEDO=mix(vec3(0.17,0.19,0.20),vec3(0.69,0.76,0.76),water);
 ALPHA=clamp(ripple*0.40+stamp*0.24,0.0,0.45);
}
