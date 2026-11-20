shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float night_weight : hint_range(0.0,1.0) = 0.0;
uniform float energy = 0.6;
uniform float core = 0.0;
void fragment() {
	vec2 point = UV*2.0-1.0;
	float radius = length(point);
	float distance_squared = dot(point,point);
	float falloff = exp(-distance_squared*4.0)*(1.0-smoothstep(0.75,1.0,radius));
	float flame = 0.97+sin(TIME*3.1)*0.02+sin(TIME*7.7)*0.01;
	float lens = exp(-distance_squared*80.0)*core;
	vec3 warmth = mix(vec3(1.0,0.69,0.27),vec3(1.0,0.96,0.76),clamp(lens,0.0,1.0));
	COLOR = vec4(warmth,(falloff+lens)*energy*night_weight*flame);
}
