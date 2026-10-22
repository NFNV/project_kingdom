shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled;

uniform int surface_kind = 0; // grass, stone, asphalt
varying vec3 ground;

float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float meadow_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1.0,0.0)),f.x),
		mix(hash(cell+vec2(0.0,1.0)),hash(cell+vec2(1.0)),f.x),f.y);
}

void vertex() {
	ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = ground.xz;
	// Fade subpixel grain before it sparkles during camera movement.
	float footprint = max(length(dFdx(p * 55.0)), length(dFdy(p * 55.0)));
	float grain_strength = 1.0-smoothstep(0.65,1.65,footprint);
	float grain = mix(0.5,hash(floor(p * 55.0)),grain_strength);
	float patch = meadow_noise(p * 5.0);
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
		col = mix(vec3(0.28,0.40,0.14), vec3(0.43,0.52,0.20), patch * 0.7 + grain * 0.3);
		float blade = step(0.86, hash(floor(p * 45.0))) * grain_strength;
		col += blade * vec3(0.11,0.13,0.025);
	}
	// Palette values above are authored in sRGB; spatial ALBEDO is linear.
	ALBEDO = pow(col, vec3(2.2));
	ROUGHNESS = 1.0;
}
