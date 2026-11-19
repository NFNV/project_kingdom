shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float night_weight : hint_range(0.0,1.0) = 1.0;
varying float mote_phase;
varying float mote_speed;
void vertex() {
	mote_phase = INSTANCE_CUSTOM.r;
	mote_speed = INSTANCE_CUSTOM.g;
}
void fragment() {
	float frame = mod(floor(TIME*(7.0+mote_speed*4.0)+mote_phase*8.0),8.0);
	vec2 atlas_uv = (UV+vec2(mod(frame,4.0),floor(frame/4.0)))/vec2(4.0,2.0);
	vec4 painted = texture(TEXTURE,atlas_uv);
	float pulse = 0.25+0.75*pow(0.5+0.5*sin(TIME*(1.1+mote_speed)+mote_phase*6.28318),2.0);
	COLOR = vec4(painted.rgb,painted.a*night_weight*pulse);
}
