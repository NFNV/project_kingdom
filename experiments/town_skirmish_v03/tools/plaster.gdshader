shader_type spatial;
render_mode diffuse_lambert_wrap;

uniform sampler2D plaster_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float eave_height = 4.5;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX*NORMAL);
}

void fragment() {
	vec3 weights = pow(abs(world_normal),vec3(4.0));
	weights /= max(dot(weights,vec3(1.0)),0.001);
	vec3 p = world_position*0.35;
	ALBEDO = texture(plaster_texture,p.zy).rgb*weights.x
		+ texture(plaster_texture,p.xz).rgb*weights.y
		+ texture(plaster_texture,p.xy).rgb*weights.z;
	// Gentle material-local cavity shading avoids a full-screen AO pass.
	float foundation = mix(0.70,1.0,smoothstep(0.15,0.8,world_position.y));
	float cornice = mix(0.86,1.0,smoothstep(0.0,0.35,abs(world_position.y-eave_height)));
	AO = foundation*cornice;
	AO_LIGHT_AFFECT = 0.35;
	ROUGHNESS = 0.95;
	SPECULAR = 0.18;
}
