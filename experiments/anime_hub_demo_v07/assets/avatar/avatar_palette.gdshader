shader_type canvas_item;

uniform vec3 coat = vec3(1.0);
uniform vec3 eyes = vec3(1.0);
uniform vec3 scarf = vec3(1.0);
uniform int markings = 0;
uniform bool dog_fur = false;
uniform vec4 head_box;
uniform vec4 eye_points = vec4(-1.0);
uniform sampler2D dog_material_mask : filter_linear, repeat_disable;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

float eye_mask(vec2 point, vec2 eye) {
	return 1.0 - smoothstep(0.68, 1.28, length((point - eye) / vec2(0.044, 0.077)));
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	vec3 ink = pixel.rgb;
	vec2 head = (UV - head_box.xy) / max(head_box.zw, vec2(0.00001));
	bool on_head = all(greaterThanEqual(head, vec2(0.0))) && all(lessThanEqual(head, vec2(1.0)));
	float red = smoothstep(0.095, 0.23, ink.r - ink.g) *
		(1.0 - smoothstep(0.095, 0.22, ink.g - ink.b)) * smoothstep(0.15, 0.32, ink.r);
	red *= 1.0 - smoothstep(0.62, 0.95, (ink.g - ink.b) / max(0.01, ink.r - ink.g));
	float warm = smoothstep(0.06, 0.22, ink.r - ink.g) * smoothstep(0.09, 0.20, ink.g - ink.b);
	float orange = warm * smoothstep(0.44, 0.70, ink.r);
	vec2 dog_material = vec2(0.0);
	if (dog_fur) {
		dog_material = texture(dog_material_mask, UV).rg;
		orange = dog_material.r;
	}
	float iris = 0.0;
	if (on_head) {
		float eye_area = max(eye_mask(head, eye_points.xy), eye_mask(head, eye_points.zw));
		iris = eye_area * smoothstep(0.075, 0.22, ink.r - ink.b) * smoothstep(0.18, 0.4, ink.r);
	}
	float lightness = dot(ink, vec3(0.2126, 0.7152, 0.0722));
	if (coat != vec3(1.0)) {
		ink = mix(ink, coat * (0.37 + 0.84 * lightness), orange * (1.0 - iris));
	}
	if (on_head && markings != 0) {
		if (markings == 1) {
			ink = mix(ink, ink + vec3(0.10, 0.07, 0.045), orange * (1.0 - smoothstep(0.40, 0.70, head.y)));
		} else {
			float blaze = (1.0 - smoothstep(0.045, 0.105, abs(head.x - 0.5))) *
				smoothstep(0.10, 0.28, head.y) * (1.0 - smoothstep(0.49, 0.70, head.y));
			ink = mix(ink, vec3(0.95, 0.87, 0.72) * (0.65 + 0.38 * lightness), orange * blaze * 0.9);
		}
	}
	if (eyes != vec3(1.0)) {
		ink = mix(ink, eyes * (0.30 + 1.40 * lightness), iris);
	}
	if (scarf != vec3(1.0)) {
		float face_center = 1.0 - smoothstep(0.10, 0.24, abs(head.x - 0.5));
		float scarf_band = smoothstep(0.73 + 0.13 * face_center, 0.84 + 0.13 * face_center, head.y) *
			(1.0 - smoothstep(1.14, 1.35, head.y));
		float scarf_weight = dog_fur ? dog_material.g : red * scarf_band;
		ink = mix(ink, scarf * (0.30 + 1.45 * lightness), scarf_weight);
	}
	COLOR = vec4(ink, pixel.a) * sprite_tint;
}
