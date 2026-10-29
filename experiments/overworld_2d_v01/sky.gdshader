shader_type canvas_item;
render_mode unshaded;
uniform sampler2D day_sky : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D night_sky : source_color, filter_linear_mipmap, repeat_enable;
uniform float camera_yaw = 0.0;
uniform float focal = 900.0;
uniform float world_time = 0.0;
uniform float night = 0.0;
uniform float twilight = 0.0;
uniform vec4 sky_tint : source_color = vec4(1.0);
const float SKY_TAU=6.283185307179586;
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
vec3 panorama(sampler2D painting, vec2 uv){
 // Overlap the final strip with the first; both samples retain x detail.
 float band=.07;
 float x=uv.x*(1.0-band);
 vec3 base=texture(painting,vec2(x,uv.y)).rgb;
 vec3 wrap=texture(painting,vec2(min(x+1.0-band,1.0),uv.y)).rgb;
 return mix(wrap,base,smoothstep(0.0,band,x));
}
void fragment(){
 // Cast the same horizontal viewing ray used by terrain and celestial objects.
 // A screen-sized sliding image otherwise moves too slowly and shears on turns.
 float bearing=camera_yaw+atan((UV.x-.5)*1920.0/focal);
 // These paintings are scenic strips, not 360-degree panoramas. Repeat three
 // strips around the horizon to retain their authored cloud size at this FOV.
 // Keep the vertical mapping fixed: yaw must not roll or tilt the sky.
 vec2 uv=vec2(.5+bearing*3.0/SKY_TAU,UV.y*.92);
 // Crossfade the panorama at its wrap seam instead of exposing a hard edge.
 float x=fract(uv.x);
 vec2 sample_uv=vec2(x,uv.y);
 vec3 col;
 if(night>.999){col=panorama(night_sky,sample_uv);}
 else if(night<.001){col=panorama(day_sky,sample_uv)*sky_tint.rgb;}
 else{col=mix(panorama(day_sky,sample_uv)*sky_tint.rgb,panorama(night_sky,sample_uv),night);}
 float horizon=exp(-pow((UV.y-.46)/.3,2.0));
 col+=vec3(.24,.08,.035)*twilight*horizon*(1.0-night);
 // A sparse second star layer twinkles over the much richer painted stars.
 if(night>.001){
 vec2 grid=vec2(fract(.5+bearing/SKY_TAU)*480.0,uv.y*90.0);
 vec2 cell=floor(grid); vec2 local=fract(grid)-vec2(hash(cell),hash(cell+71.0));
 float star=(1.0-smoothstep(.01,.065,length(local)))*step(.95,hash(cell+17.0));
 float pulse=.55+.45*sin(world_time*(.45+hash(cell)) +hash(cell+3.0)*6.283185);
 col+=vec3(.65,.72,.9)*star*pulse*night;
 }
 COLOR=vec4(col,1.0);
}
