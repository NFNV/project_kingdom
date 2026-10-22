shader_type spatial;
render_mode unshaded;

void fragment() {
	// A painted interior and sky reflection give glass depth without extra lights.
	vec3 color = mix(vec3(0.18,0.31,0.33),vec3(0.72,0.53,0.29),UV.y);
	float curtain = max(1.0-smoothstep(0.14,0.22,UV.x),smoothstep(0.78,0.86,UV.x));
	vec3 linen = vec3(0.87,0.77,0.57)*(0.9+0.1*sin(UV.x*115.0));
	color = mix(color,linen,curtain);
	float reflection = 1.0-smoothstep(0.025,0.06,abs(UV.x-UV.y*0.28-0.48));
	color = mix(color,vec3(0.64,0.79,0.80),reflection*0.38);
	ALBEDO = pow(color,vec3(2.2));
}
