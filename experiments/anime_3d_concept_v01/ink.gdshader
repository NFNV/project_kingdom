shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 ink : source_color = vec4(.20,.13,.10,1.0);
uniform float width = .008;

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = ink.rgb;
}
