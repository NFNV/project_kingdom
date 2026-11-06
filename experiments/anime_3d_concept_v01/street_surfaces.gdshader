shader_type spatial;
render_mode specular_disabled;

uniform vec4 pigment : source_color;
uniform vec4 secondary : source_color;
uniform int pattern = 0;
varying vec3 surface_point;
varying vec3 surface_normal;

void vertex() {
	surface_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	surface_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float hash2(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}

float noise2(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 w = f*f*(3.0-2.0*f);
	return mix(mix(hash2(cell),hash2(cell+vec2(1,0)),w.x),
		mix(hash2(cell+vec2(0,1)),hash2(cell+1.0),w.x),w.y);
}

float brush_edge(float position, float width) {
	return 1.0-smoothstep(width*.45,width,position);
}

void fragment() {
	vec2 p = surface_point.xz;
	vec3 n = abs(surface_normal);
	if (n.y < .65) {
		p = vec2(n.z > n.x ? surface_point.x : surface_point.z,surface_point.y);
	}
	float fine = noise2(p*49.0);
	float wash = noise2(p*2.8)*.58 + noise2(p*13.0)*.28 + fine*.14;
	vec3 color = mix(pigment.rgb,secondary.rgb,wash*.78);
	float roughness = .94;
	if (pattern == 1 || pattern == 2 || pattern == 3) {
		vec2 brick = p / vec2(.57,.232);
		if (pattern == 2) brick = p / vec2(.82,.74);
		if (pattern == 3) brick = p / vec2(.36,.27);
		if (pattern != 2) brick.x += mod(floor(brick.y),2.0)*.5;
		vec2 tile = fract(brick + (noise2(p*31.0)-.5)*.022);
		vec2 edge = min(tile,1.0-tile);
		float bevel = min(edge.x,edge.y);
		float aa = min(fwidth(bevel)*.65,.019);
		float mortar = 1.0-smoothstep(.016-aa,.031+aa,bevel);
		float variation = hash2(floor(brick));
		color = mix(pigment.rgb,secondary.rgb,.08 + .42*variation + .35*wash);
		color *= mix(.78,1.06,smoothstep(.008,.085,tile.y));
		color *= mix(.955,1.052,smoothstep(.40,.79,fine));
		if (pattern == 1) {
			float abrasion = smoothstep(.60,.88,noise2(vec2(p.x*10.0,p.y*26.0)));
			float face = smoothstep(.030,.060,bevel);
			color = mix(color,vec3(.76,.52,.35),abrasion*.18*face);
			color *= mix(.68,1.0,smoothstep(.12,.96,surface_point.y+wash*.16));
			color *= 1.0+.13*brush_edge(1.0-tile.y,.038)*face;
		}
		if (pattern == 2) {
			float stain = smoothstep(.55,.85,noise2(p*1.9)*.65+noise2(p*12.0)*.35);
			color = mix(color,vec3(.36,.37,.20),stain*.28);
			float fracture = abs(noise2(p*4.2)-.53);
			float hairline = 1.0-smoothstep(.007,.022,fracture);
			color *= 1.0-hairline*smoothstep(.72,.91,variation)*smoothstep(.16,.56,tile.x)*.20;
		}
		vec3 grout = pattern == 1 ? vec3(.28,.215,.157) : pigment.rgb*.58;
		color = mix(color,grout,mortar*.71);
	}
	if (pattern == 4) {
		float board = fract(p.y/.24 + noise2(p*18.0)*.018);
		color *= mix(.72,1.035,smoothstep(.0,.19,board));
		float grain = noise2(vec2(p.x*5.0,p.y*88.0));
		color *= .91+grain*.18;
		color = mix(color,vec3(.49,.43,.30),smoothstep(.78,.94,grain)*.13);
		color *= mix(.79,1.0,smoothstep(.14,.91,surface_point.y+wash*.17));
	}
	if (pattern == 5) {
		float patch = smoothstep(.2,.7,noise2(p*.78)*.75+noise2(p*2.2)*.25);
		color = mix(pigment.rgb,secondary.rgb,patch*.72);
		color *= .91 + wash*.21;
	}
	if (pattern == 6) {
		float cloud = noise2(p*3.5)*.64+noise2(p*9.0)*.36;
		float diagonal = smoothstep(.62,.83,fract(p.y*.87-p.x*.29+cloud*.06));
		float fresnel = pow(1.0-max(dot(normalize(NORMAL),VIEW),0.0),3.0);
		color = mix(pigment.rgb,secondary.rgb,.10+cloud*.37+diagonal*.27+fresnel*.14);
		roughness = .38;
	}
	ALBEDO = color;
	ROUGHNESS = roughness;
}
