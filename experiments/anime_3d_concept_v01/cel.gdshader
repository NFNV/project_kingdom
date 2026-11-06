shader_type spatial;
render_mode specular_disabled;

uniform vec4 pigment : source_color = vec4(1.0);
uniform vec4 stripe_color : source_color = vec4(.74,.36,.14,1.0);
uniform vec4 cream_color : source_color = vec4(1.0,.88,.69,1.0);
uniform sampler2D face_art : source_color, filter_linear_mipmap, repeat_disable;
uniform bool tabby = false;
uniform bool tail = false;
varying vec3 model_point;

void vertex() {
	model_point = VERTEX * 2.0;
}

float brush(float distance, float width) {
	return 1.0 - smoothstep(width * .73, width, abs(distance));
}

void fragment() {
	vec3 color = pigment.rgb;
	if (tabby) {
		vec3 p = model_point;
		float cheek = -.142 + .075 * p.x * p.x + .074 * cos(p.x * 8.0);
		float cream = (1.0 - smoothstep(cheek - .04, cheek + .045, p.y)) * smoothstep(.04, .32, p.z);
		color = mix(color, cream_color.rgb, cream * mix(.82,1.0,smoothstep(.0,.67,p.z)));
		float stripe = brush(p.x + .035 * sin(p.y * 5.0), .046 + max(p.y,0.0)*.043)
			* smoothstep(.35, .48, p.y);
		stripe = max(stripe, brush(abs(p.x) - .25 - .18 * (1.0 - p.y), .045 + max(p.y,0.0)*.030)
			* smoothstep(.29, .47, p.y));
		float side = brush(p.y - (.10 + .34 * (abs(p.x) - .7)), .060)
			+ brush(p.y + .095 - .31 * (abs(p.x) - .7), .046);
		stripe = max(stripe, side * smoothstep(.52,.87,abs(p.x)) * smoothstep(-.22,.34,p.z));
		float nape = brush(p.x + .05 * sin(p.y * 7.0), .086) + brush(abs(p.x) - .36, .065);
		stripe = max(stripe, nape * (1.0 - smoothstep(-.65,-.32,p.z)) * smoothstep(-.31,.29,p.y));
		color = mix(color, stripe_color.rgb, clamp(stripe,0.0,1.0) * (1.0-cream) * .77);
		vec2 face_uv = vec2(.5 + p.x*.60, .54 - p.y*.66);
		vec4 features = texture(face_art, face_uv);
		color = mix(color, features.rgb, features.a * smoothstep(.35,.63,p.z));
	}
	if (tail) {
		float flow = .34 * model_point.x + .24 * model_point.y;
		float rings = smoothstep(.34,.72,cos(flow * 37.0));
		color = mix(color, stripe_color.rgb, rings*.63);
		color = mix(color, cream_color.rgb, smoothstep(.99,1.065,flow));
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = color * (.055 + rim * .085);
}

void light() {
	float facing = dot(NORMAL,LIGHT);
	float band = .38 + .44 * smoothstep(-.02,.17,facing) + .18 * smoothstep(.59,.88,facing);
	vec3 bounce = mix(vec3(.87,.90,1.0),vec3(1.0),smoothstep(-.1,.35,facing));
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * bounce * (band * ATTENUATION / PI);
}
