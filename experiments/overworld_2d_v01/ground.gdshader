shader_type canvas_item;
render_mode unshaded;
uniform vec2 camera_ground;
uniform vec2 camera_right = vec2(1.0,0.0);
uniform vec2 camera_forward = vec2(0.0,1.0);
uniform vec2 city_center = vec2(-47.0,39.0);
uniform float focal = 900.0;
uniform float camera_height = 14.0;
uniform float horizon = 245.0;
uniform float bend = 0.0014;
uniform float camera_lead = 28.0;
uniform float world_time = 0.0;
uniform bool grid = false;
uniform float river_z = 85.0;
uniform float river_wave = 8.0;
uniform float river_rate = 0.03;
uniform float river_half = 4.8;
uniform float bridge_x = 18.0;
uniform float bridge_half = 5.5;
uniform vec4 routes[32];
uniform int route_count = 0;
uniform vec4 terrain_tint = vec4(1.0);
uniform vec4 haze_color = vec4(.66,.79,.67,1.0);
uniform float night_weight = 0.0;

float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float segment_distance(vec2 p,vec2 a,vec2 b){ vec2 v=b-a; return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.0,1.0)); }
void fragment(){
 vec2 pixel=UV*vec2(1920,1080);
 float t=(pixel.y-horizon)/focal;
 float slope=(pixel.x-960.0)/focal;
 float effective_height=camera_height-bend*camera_lead*camera_lead;
 float disc=t*t-4.0*bend*(1.0+slope*slope)*effective_height;
 if(t<=0.0 || disc<=0.0){COLOR=vec4(0);}else{
  float depth=2.0*effective_height/(t+sqrt(disc));
  if(depth>360.0){COLOR=vec4(0);}else{
   vec2 p=camera_ground+camera_right*((pixel.x-960.0)*depth/focal)+camera_forward*depth;
   float n=noise(p*.22)*.65+noise(p*.7)*.22+noise(p*2.7)*.13;
   vec3 grass=mix(vec3(.32,.51,.25),vec3(.67,.75,.37),n);
   grass+=sin(p.x*.045+p.y*.031)*.025;
   float road=abs(p.x-sin(p.y*.016)*18.0);
   float path=road;
   for(int i=0;i<32;i++){
    if(i>=route_count){break;}
    path=min(path,segment_distance(p,routes[i].xy,routes[i].zw));
   }
   float forest=smoothstep(130.0,240.0,p.y)*(1.0-smoothstep(50.0,125.0,p.x));
   grass=mix(grass,grass*vec3(.77,.88,.79),forest*.65);
   float ridge=1.0-smoothstep(30.0,80.0,length(p-vec2(-135.0,155.0)));
   grass=mix(grass,vec3(.65,.70,.36)+n*.08,ridge*.5);
   float coast=198.0+sin(p.y*.02)*7.0;
   float shore=p.x-coast;
   float coast_region=smoothstep(100.0,116.0,p.y);
   grass=mix(grass,vec3(.86,.80,.58)+n*.04,smoothstep(-22.0,-4.0,shore)*coast_region);
   vec3 soil=mix(vec3(.66,.53,.33),vec3(.88,.77,.51),n);
   vec3 col=mix(grass,soil,1.0-smoothstep(2.6,4.2,path));
   // The city painting already contains its plaza. A second projected circle
   // appeared outside the cutout as the player moved past the town.
   float waterline=abs(p.y-(river_z+sin(p.x*river_rate)*river_wave));
   col=mix(col,vec3(.76,.73,.48),1.0-smoothstep(river_half,river_half+1.3,waterline));
   float water=1.0-smoothstep(river_half-.45,river_half,waterline);
   vec3 blue=mix(vec3(.18,.48,.54),vec3(.38,.72,.72),n);
   float ripple=pow(max(0.0,sin(p.y*2.7+sin(p.x*.85)*1.8+noise(p*.5)*2.0-world_time*1.7)),22.0);
   blue+=ripple*.075;
   col=mix(col,blue,water);
   float lake=length((p-vec2(145.0,205.0))/vec2(30.0,38.0));
   col=mix(col,vec3(.76,.74,.51),1.0-smoothstep(.99,1.08,lake));
   float lake_water=1.0-smoothstep(.97,1.0,lake);
   col=mix(col,blue*vec3(.87,1.02,1.02),lake_water);
   float sea=smoothstep(-.5,.8,shore)*coast_region;
   col=mix(col,blue*vec3(.78,.98,1.06),sea);
   float foam=(1.0-smoothstep(0.0,1.0,abs(shore-1.4-sin(p.y*.45+world_time)*.4)))*coast_region;
   col=mix(col,vec3(.85,.91,.80),foam*.6);
   if(abs(p.x-bridge_x)<bridge_half && waterline<river_half+2.0){
    col=mix(vec3(.46,.35,.22),vec3(.69,.53,.32),step(.08,fract(p.y*1.3)));
    float rail=step(bridge_half-.35,abs(p.x-bridge_x));
    col=mix(col,vec3(.28,.25,.16),rail);
   }
   vec2 tuft=fract(p*3.0)-.5;
   float speck=step(.95,hash(floor(p*3.0)))*(1.0-smoothstep(.1,.34,length(tuft*vec2(1.2,.8))))*(1.0-smoothstep(45.0,110.0,depth));
   col=mix(col,vec3(.94,.87,.55),speck*(1.0-max(water,max(lake_water,sea)))*smoothstep(3.5,5.0,path)*.5);
   if(grid){
    vec2 cell=abs(fract(p/10.0-.5)-.5)*10.0;
    float line=1.0-smoothstep(.03,.12,min(cell.x,cell.y));
    col=mix(col,vec3(.17,.32,.27),line*.5);
   }
   col*=terrain_tint.rgb;
   // A soft moon reflection keeps water readable without brightening the shore.
   if(night_weight>.001){
    float reflection=pow(max(0.0,sin(p.y*1.2+sin(p.x*.5)*.7-world_time*.4)),14.0);
    col+=vec3(.12,.17,.23)*reflection*max(water,max(lake_water,sea))*night_weight;
   }
   float haze=smoothstep(90.0,340.0,depth);
   col=mix(col,haze_color.rgb,haze*.8);
   COLOR=vec4(col,1.0-smoothstep(320.0,360.0,depth));
  }
 }
}
