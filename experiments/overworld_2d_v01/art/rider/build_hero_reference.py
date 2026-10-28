"""Read-only atlas metadata extraction; protagonist PNGs are never modified."""
from pathlib import Path
import re,json,math,hashlib
out=Path(__file__).resolve().parent
root=out.parents[3]
folder=root/'experiments/anime_hub_demo_v07/assets/motion'
text=(folder/'cat_frames.tres').read_text()
paths={key:path for path,key in re.findall(r'\[ext_resource type="Texture2D" path="([^"]+)" id="([^"]+)"\]',text)}
sections=dict(re.findall(r'\[sub_resource type="AtlasTexture" id="([^"]+)"\]\n(.*?)(?=\n\[)',text,re.S))
catalog=json.loads((folder/'catalog.json').read_text())['cat']
heads={}
for direction in ['n','ne','e','se','s','sw','w','nw']:
 line=next(line for line in text.splitlines() if '"name": &"idle_'+direction+'"' in line)
 fid=re.search(r'SubResource\("([^"]+)"\)',line).group(1)
 section=sections[fid];source=paths[re.search(r'ExtResource\("([^"]+)"\)',section).group(1)]
 region=[float(v) for v in re.search(r'region = Rect2\(([^)]+)\)',section).group(1).split(',')]
 pose=catalog[direction]['body_registration']['idle']['poses'][0]
 width=pose['head_width'];cx,cy=pose['head_center']
 crop=[int(region[0]+math.floor(cx-width*.64)),int(region[1]),math.ceil(width*1.28),math.ceil(cy*2)]
 file=root/source.removeprefix('res://')
 heads[direction]={'source':source,'crop':crop,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'idle_frame':fid}
(out/'hero_reference.json').write_text(json.dumps({'source':'Existing playable protagonist SpriteFrames + body registration','mode':'Godot runtime head extraction; source images unchanged','directions':heads},indent=2)+'\n')
print('Eight exact protagonist head references recorded.')
