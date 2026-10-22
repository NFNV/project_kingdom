shader_type canvas_item;

uniform float amplitude_px = 7.0;
uniform float speed = 0.7;
uniform float phase = 0.0;
varying vec4 sprite_modulate;

void vertex() {
	sprite_modulate = COLOR;
}

void fragment() {
	// The transparent source padding accommodates the displacement. Root stays still.
	float height_weight = smoothstep(0.12,0.64,1.0-UV.y);
	float breeze = sin(TIME*speed+phase)*0.75 + sin(TIME*speed*1.83+UV.y*5.0+phase)*0.25;
	vec2 sample_uv = UV-vec2(breeze*amplitude_px*TEXTURE_PIXEL_SIZE.x*height_weight,0.0);
	vec4 texel = texture(TEXTURE,sample_uv);
	COLOR = texel*sprite_modulate;
}
