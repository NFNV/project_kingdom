"""Copy imagegen originals unchanged; author native Godot atlas margins and scale."""
from pathlib import Path
import hashlib
import json
import shutil
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RES = 'res://experiments/anime_hub_assets_v08_humans/'


def divide(mask, axis):
    length = mask.shape[axis]
    projection = mask.sum(axis=1-axis)
    lo, hi = round(length*.38), round(length*.62)
    quiet = np.flatnonzero(projection[lo:hi] <= 2)+lo
    runs = [r for r in np.split(quiet, np.where(np.diff(quiet)>1)[0]+1) if len(r)]
    if not runs:
        raise ValueError('No clear sheet gutter; review the source layout')
    middle = round(float(min(runs, key=lambda r: abs(r.mean()-length/2)).mean()))
    return [0,middle,length]


def main():
    manifest = json.loads((ROOT/'generation_prompts.json').read_text())
    for folder in ['characters','resources','previews']:
        (ROOT/folder).mkdir(exist_ok=True)
    catalog = {'animal_reference_height':108,'canvas':[1024,1024],
               'sprite_offset':[-512,-984],'assets':{}}
    for job in manifest['jobs']:
        filename = 'characters/'+job['id']+'.png'
        target = ROOT/filename
        shutil.copyfile(job['source'],target)
        pixels = np.asarray(Image.open(target).convert('RGBA'))
        mask = pixels[:,:,3] >= 64
        clear = float((pixels[:,:,3]==0).mean())
        assert clear>.4, f'Insufficient alpha transparency: {job["id"]}'
        xs, ys = divide(mask,1), divide(mask,0)
        frames, resources, animations = {}, [], []
        for i, direction in enumerate(job['directions']):
            row, col = divmod(i,2)
            x0,x1,y0,y1 = xs[col],xs[col+1],ys[row],ys[row+1]
            yy,xx = np.where(mask[y0:y1,x0:x1])
            left,right,top,bottom = int(xx.min()),int(xx.max()+1),int(yy.min()),int(yy.max()+1)
            w,h = right-left,bottom-top
            boots = mask[y0+top+round(h*.82):y0+bottom,x0:x1]
            _,boot_x = np.where(boots)
            anchor_x = float(np.median(boot_x))
            region = [x0+left,y0+top,w,h]
            margin = [512-(anchor_x-left),984-h,1024-w,1024-h]
            assert min(margin)>=0 and h>300 and w>100, f'Unexpected pose bounds: {job["id"]} {direction}'
            frames[direction] = {'region':region,'margin':margin,'height':h,
                                 'anchor_source':[x0+anchor_x,y0+bottom],
                                 'scale_at_recommended_height':job['height']/h}
            resources.append(f'[sub_resource type="AtlasTexture" id="{direction}"]\natlas = ExtResource("P")\nregion = Rect2({", ".join(map(str,region))})\nmargin = Rect2({", ".join(map(str,margin))})\nfilter_clip = true')
            animations.append('{"frames": [{"duration": 1.0, "texture": SubResource("'+direction+'")}], "loop": true, "name": &"idle_'+direction+'", "speed": 1.0}')
        assert job['height']>=108*1.5
        native_file = 'resources/'+job['id']+'_frames.tres'
        native = '[gd_resource type="SpriteFrames" load_steps=6 format=3]\n\n'
        native += f'[ext_resource type="Texture2D" path="{RES}{filename}" id="P"]\n\n'
        native += '\n\n'.join(resources)+'\n\n[resource]\nanimations = [\n'+',\n'.join(animations)+'\n]\n'
        (ROOT/native_file).write_text(native)
        catalog['assets'][job['id']] = {'name':job['name'],'file':filename,'native_frames':native_file,
            'source':job['source'],'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
            'byte_identical_copy':target.read_bytes()==Path(job['source']).read_bytes(),
            'size':[pixels.shape[1],pixels.shape[0]],'transparent_fraction':round(clear,4),
            'recommended_height_at_1080p':job['height'],'height_vs_animals':round(job['height']/108,3),
            'directions':job['directions'],'x_partitions':xs,'y_partitions':ys,'frames':frames}
    (ROOT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n')
    print('Prepared 4 human adults, 16 transparent directional poses; 1.56–1.67 times the animal height. PNGs unchanged.')


if __name__ == '__main__':
    main()
