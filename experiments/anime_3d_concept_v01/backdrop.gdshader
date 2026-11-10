shader_type sky;

uniform vec4 horizon : source_color = vec4(.87,.86,.74,1.0);
uniform vec4 zenith : source_color = vec4(.59,.75,.80,1.0);

void sky() {
	float gradient = smoothstep(-.38,.22,EYEDIR.y);
	COLOR = mix(horizon.rgb,zenith.rgb,gradient);
}
