shader_type canvas_item;
render_mode unshaded;
varying vec4 canvas_tint;
uniform bool animate_water = false;
uniform vec2 panel_origin = vec2(0.0);

void vertex() {
 canvas_tint = COLOR;
}

void fragment() {
 // Neighbouring paintings share a 128 × 72 world-unit border.
 vec2 edge = min(UV, vec2(1.0) - UV);
 vec2 weight = smoothstep(vec2(0.0), vec2(1.0 / 9.0), edge);
 // World UVs keep the ripple phase continuous across overlapping panels.
 vec2 world_uv = (panel_origin + UV * vec2(1152.0,648.0)) / vec2(3072.0,1728.0);
 float water = 0.0;
 if (animate_water) {
  water = smoothstep(0.299,0.316,world_uv.x) * (1.0-smoothstep(0.678,0.695,world_uv.x));
  water *= smoothstep(0.408,0.428,world_uv.y) * (1.0-smoothstep(0.676,0.697,world_uv.y));
 }
 vec2 ripple = vec2(sin(world_uv.y*97.0+TIME*0.8),cos(world_uv.x*83.0+TIME*0.7));
 vec2 displacement = ripple * water * 0.0008 * vec2(3072.0,1728.0) / vec2(1152.0,648.0);
 COLOR = texture(TEXTURE, UV+displacement) * canvas_tint;
 COLOR.rgb *= 1.0+sin(world_uv.x*140.0+world_uv.y*89.0+TIME*0.8)*water*0.025;
 COLOR.a *= weight.x * weight.y;
}
