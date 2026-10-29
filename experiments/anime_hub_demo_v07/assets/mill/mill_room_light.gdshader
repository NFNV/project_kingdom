shader_type canvas_item;
render_mode unshaded;
uniform sampler2D night_painting : source_color, filter_linear_mipmap;
uniform float night_weight : hint_range(0.0,1.0) = 0.0;
void fragment(){
 // Both the whole room and its foreground counter use this exact blend.
 // The night painting removes the sunlight baked into the daytime floor.
 COLOR=mix(texture(TEXTURE,UV),texture(night_painting,UV),night_weight);
}
