shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

void fragment() {
	float distance_from_center = length((UV-0.5)*2.0);
	ALBEDO = vec3(0.035,0.055,0.05);
	ALPHA = (1.0-smoothstep(0.25,1.0,distance_from_center))*0.30;
}
