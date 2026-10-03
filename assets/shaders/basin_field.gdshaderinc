float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float field(vec2 p) { return noise(p)*0.58 + noise(p*2.13+13.2)*0.28 + noise(p*4.17-4.3)*0.14; }
float basin_field(vec2 p) {
 vec2 warp = vec2(field(p*0.065),field(p*0.065+31.7))*6.0;
 // Broad connected pools with broken, metre-scale tidal margins.
 return field((p+warp)*vec2(0.105,0.29)) + (field(p*1.3)-0.5)*0.045 + (noise(p*5.7)-0.5)*0.009;
}
