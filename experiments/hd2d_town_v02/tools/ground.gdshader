shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled;

uniform int surface_kind = 0; // grass, stone, asphalt
varying vec3 ground;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = ground.xz;
	float grain = hash(floor(p * 95.0));
	float patch = hash(floor(p * 11.0));
	vec3 col;
	if (surface_kind == 1) {
		vec2 grid = p * vec2(1.28, 1.5);
		grid.x += mod(floor(grid.y), 2.0) * 0.5;
		vec2 f = fract(grid);
		float joint = min(min(f.x, 1.0-f.x), min(f.y, 1.0-f.y));
		float stone = hash(floor(grid));
		col = mix(vec3(0.63,0.51,0.34), vec3(0.88,0.77,0.56), stone * 0.65 + 0.24);
		col += (grain - 0.5) * 0.075 + (patch - 0.5) * 0.025;
		col = mix(vec3(0.36,0.34,0.25), col, smoothstep(0.012,0.027,joint));
		col += smoothstep(0.027,0.038,joint) * (1.0-smoothstep(0.038,0.050,joint)) * 0.11;
	} else if (surface_kind == 2) {
		col = vec3(0.32,0.34,0.36) + (grain - 0.5) * 0.085 + (patch - 0.5) * 0.033;
		float cracks = abs(sin(p.x * 2.2 + sin(p.y * 8.0) * 0.14));
		col *= 1.0 - step(cracks, 0.009) * 0.12;
	} else {
		col = mix(vec3(0.24,0.36,0.13), vec3(0.47,0.57,0.18), patch * 0.7 + grain * 0.3);
		float blade = step(0.86, hash(floor(p * 45.0)));
		col += blade * vec3(0.11,0.13,0.025);
	}
	// Palette values above are authored in sRGB; spatial ALBEDO is linear.
	ALBEDO = pow(col, vec3(2.2));
	ROUGHNESS = 1.0;
}
