shader_type canvas_item;
varying vec4 ground_modulate;

void vertex() {
	ground_modulate = COLOR;
}

// Mirror-repeat the original painted ground at local scenery scale. This keeps
// brush detail sharp across a large world without repeating hard image seams.
void fragment() {
	vec2 tile = mod(UV * vec2(2.4), vec2(2.0));
	vec2 ground_uv = vec2(1.0) - abs(tile - vec2(1.0));
	COLOR = texture(TEXTURE, ground_uv) * ground_modulate;
}
