shader_type canvas_item;

// A gentle shared ink/ivory response before the existing day/night modulation.
// No outlines, dithering, pixel snapping or replacement of the authored frames.
varying vec4 sprite_tint;
void vertex() {
	sprite_tint = COLOR;
}
void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float lightness = dot(texel.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 pigment = mix(vec3(lightness), texel.rgb, 0.94);
	pigment = mix(pigment, vec3(0.24, 0.30, 0.31), 0.075 * (1.0 - smoothstep(0.05, 0.50, lightness)));
	pigment = mix(pigment, pigment * vec3(1.0, 0.98, 0.94), 0.30 * smoothstep(0.45, 1.0, lightness));
	COLOR = vec4(pigment, texel.a) * sprite_tint;
}
