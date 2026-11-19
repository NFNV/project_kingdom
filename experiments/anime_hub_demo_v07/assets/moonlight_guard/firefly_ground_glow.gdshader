shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float night_weight : hint_range(0.0,1.0) = 1.0;
uniform float glow_strength : hint_range(0.0,1.0) = 0.45;
varying float mote_phase;
varying float mote_speed;
void vertex() {
	mote_phase = INSTANCE_CUSTOM.r;
	mote_speed = INSTANCE_CUSTOM.g;
	// Project the light onto the ground below the hovering insect.
	VERTEX *= vec2(7.0,3.8);
	VERTEX.y += 0.8;
}
void fragment() {
	vec2 point = UV*2.0-1.0;
	float radius = length(point);
	float falloff = exp(-dot(point,point)*4.5)*(1.0-smoothstep(0.7,1.0,radius));
	float pulse = 0.25+0.75*pow(0.5+0.5*sin(TIME*(1.1+mote_speed)+mote_phase*6.28318),2.0);
	COLOR = vec4(1.0,0.85,0.34,falloff*pulse*glow_strength*night_weight);
}
