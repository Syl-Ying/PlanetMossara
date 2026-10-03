shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform bool raised_silt = false;
uniform bool reflection_enabled = false;
uniform sampler2D reflection_texture : source_color, filter_linear, repeat_disable;
uniform mat4 reflection_projection;
varying vec3 ground_position;
varying float bank_height;
#include "res://assets/shaders/basin_field.gdshaderinc"
vec2 cells(vec2 p) {
 vec2 base=floor(p); vec2 f=fract(p); float a=8.0; float b=8.0;
 for(int y=-1;y<=1;y++) { for(int x=-1;x<=1;x++) {
  vec2 g=vec2(float(x),float(y)); vec2 r=g+vec2(hash(base+g),hash(base+g+17.8))-f;
  float d=dot(r,r); if(d<a) {b=a;a=d;} else {b=min(b,d);}
 }}
 return vec2(sqrt(a),sqrt(b));
}
void vertex() { bank_height = VERTEX.y; ground_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p = ground_position.xz;
 float basin=basin_field(p);
 float aa=max(fwidth(basin),0.001);
 float dry=smoothstep(0.48-aa,0.48+aa,basin);
 float wet=1.0-smoothstep(0.483,0.535,basin);
 if (raised_silt) { dry=1.0; wet=1.0-smoothstep(0.015,0.13,bank_height); }
 float deposits=field(p*0.7);
 float mottles=field(p*3.1);
 float detail_fade=1.0-smoothstep(0.04,0.20,length(fwidth(p)));
 // Mineral-grey clay, warm exposed silt, cooler saturated margins.
 vec3 clay=mix(vec3(0.38,0.355,0.37),vec3(0.53,0.49,0.435),smoothstep(0.25,0.76,deposits));
 clay += (mottles-0.5)*0.075;
 clay=mix(clay,vec3(0.275,0.29,0.31),wet*0.58);
 float tideline=(1.0-smoothstep(0.002,0.014,abs(basin-0.508)))*smoothstep(0.36,0.66,mottles);
 clay=mix(clay,vec3(0.64,0.60,0.51),tideline*0.36);
 // Discontinuous fine drying cracks, kept off the wet mud and filtered at distance.
 vec2 cell=cells(p*3.6+vec2(noise(p*1.9),noise(p*1.9+9.1))*0.55);
 float edge=cell.y-cell.x;
 float crack=(1.0-smoothstep(0.012,0.035+length(fwidth(p))*2.0,edge))*detail_fade;
 crack*=smoothstep(0.53,0.59,basin)*smoothstep(0.4,0.65,deposits);
 clay*=1.0-crack*0.16;
 float grain=(noise(p*43.0)-0.5)*detail_fade;
 clay+=grain*0.035;
 if (raised_silt) {
  float strata=sin(bank_height*185.0+noise(p*5.0)*1.6);
  clay *= 0.94+0.06*strata;
  clay = mix(clay,vec3(0.235,0.255,0.27), (1.0-smoothstep(0.0,0.035,bank_height))*0.5);
 }
 float fleck=step(0.94,hash(floor(p*28.0)))*detail_fade;
 clay-=fleck*0.025;
 // Pale cloudy sky response, with shallow sediment visible along the pool edge.
 float sky=field(p*vec2(0.075,0.15)+vec2(0.0,TIME*0.002));
 vec3 water=mix(vec3(0.40,0.48,0.51),vec3(0.66,0.70,0.69),smoothstep(0.26,0.77,sky));
 float shallows=smoothstep(0.435,0.48,basin);
 // Submerged sediment remains visible close to shore; deeper pools turn cool and dark.
 vec3 submerged_silt=mix(vec3(0.36,0.365,0.34),vec3(0.49,0.46,0.39),mottles);
 water=mix(water,submerged_silt,shallows*0.75);
 water*=mix(0.82,1.0,shallows);
 float lip=1.0-smoothstep(aa,aa+0.003,abs(basin-0.48));
 vec3 color=mix(water,clay,dry);
 color=mix(color,vec3(0.24,0.27,0.29),lip*0.20);
 // Water stays smooth; mud has a subtle physical surface response and receives shadows.
 float ripple=sin(p.x*3.7+p.y*5.3+TIME*0.55)*0.025;
 vec3 normal_detail=vec3((noise(p*18.0)-0.5)*0.18,(noise(p*18.0+13.0)-0.5)*0.18,1.0);
 NORMAL_MAP=normalize(mix(vec3(ripple,ripple*0.4,1.0),normal_detail,dry*detail_fade))*0.5+0.5;
 ROUGHNESS=mix(0.24,mix(0.94,0.67,wet),dry);
 SPECULAR=mix(0.5,0.18,dry);
 float distance_fade=smoothstep(45.0,190.0,length(p));
 ALBEDO=mix(color,vec3(0.50,0.53,0.57),distance_fade*0.68)*mix(0.38,0.52,dry);
 if (reflection_enabled && !raised_silt && dry < 0.999) {
  vec4 reflected_clip=reflection_projection*vec4(ground_position,1.0);
  vec2 uv=reflected_clip.xy/reflected_clip.w*vec2(0.5,-0.5)+0.5;
  vec2 drift=vec2(sin(p.y*5.0+TIME*0.55),sin(p.x*3.7+p.y*2.1-TIME*0.4))*0.0012;
  uv+=drift*(1.0-shallows*0.6);
  float border=smoothstep(0.0,0.025,min(min(uv.x,uv.y),min(1.0-uv.x,1.0-uv.y)));
  vec3 reflected=texture(reflection_texture,clamp(uv,vec2(0.001),vec2(0.999))).rgb;
  float fresnel=pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),3.0);
  float strength=(1.0-dry)*border*mix(0.30,0.68,fresnel)*(1.0-shallows*0.62);
  ALBEDO*=1.0-strength;
  EMISSION=reflected*vec3(0.90,0.96,0.98)*strength;
 }
}
