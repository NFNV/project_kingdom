shader_type canvas_item;
render_mode unshaded;
varying vec4 canvas_tint;

void vertex() {
	canvas_tint = COLOR;
}

void fragment() {
	// Keep the painted stone rim fixed while water inside catches moving light.
	float mask = smoothstep(0.299, 0.316, UV.x) * (1.0 - smoothstep(0.678, 0.695, UV.x));
	mask *= smoothstep(0.408, 0.428, UV.y) * (1.0 - smoothstep(0.676, 0.697, UV.y));
	vec2 ripple = vec2(sin(UV.y * 97.0 + TIME * 0.8), cos(UV.x * 83.0 + TIME * 0.7));
	vec4 painting = texture(TEXTURE, UV + ripple * mask * 0.0008);
	painting.rgb *= 1.0 + sin(UV.x * 140.0 + UV.y * 89.0 + TIME * 0.8) * mask * 0.025;
	COLOR = painting * canvas_tint;
}
