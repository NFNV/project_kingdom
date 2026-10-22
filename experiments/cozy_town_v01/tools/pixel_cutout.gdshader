shader_type canvas_item;
render_mode unshaded;

// Experimental presentation cleanup. Source PNGs retain their original alpha.
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.97;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	if (texel.a < alpha_cutoff) {
		discard;
	}
	COLOR = vec4(texel.rgb, 1.0) * vertex_tint;
}
