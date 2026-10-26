"""Read-only body/head registration. Originals remain byte-identical PNGs."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image
from register_combat_transitions import components

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'bandits'

def register(role):
    path = ROOT / f'{role}_v1.png'
    image = np.asarray(Image.open(path).convert('RGBA'))
    height, width = image.shape[:2]
    yy, xx = np.where(image[:, :, 3] > 180)
    bodies = sorted(components(yy*width+xx, width), key=len, reverse=True)[:32]
    assert len(bodies) == 32 and min(map(len, bodies)) > 1200
    bodies.sort(key=lambda body: float(np.mean(body//width)))
    directions = {}
    for row, direction in enumerate(['se', 'sw', 'ne', 'nw']):
        entries = []
        group = sorted(bodies[row*8:row*8+8], key=lambda body: float(np.mean(body%width)))
        for index, body in enumerate(group):
            ys, xs = body//width, body%width
            x0, x1 = int(xs.min()), int(xs.max()+1)
            y0, y1 = int(ys.min()), int(ys.max()+1)
            rgb = image[ys, xs, :3].astype(float)
            if role == 'raider':
                fur = (rgb[:,0]>80)&(rgb[:,0]>rgb[:,1]*1.12)&(rgb[:,1]>rgb[:,2]*1.12)
            else:
                fur = (np.abs(rgb[:,0]-rgb[:,1])<22)&(np.abs(rgb[:,1]-rgb[:,2])<25)&(rgb[:,0]<155)
            fur &= ys < y0+(y1-y0)*.58
            head = max(components(body[fur],width),key=len)
            hy, hx = head//width, head%width
            hw = int(hx.max()-hx.min()+1)
            assert hw > 25, (role,direction,index,hw)
            entries.append({'region':[x0,y0,x1-x0,y1-y0], 'head_x':float(hx.min()+hx.max())/2, 'head_y':float(hy.min()+hy.max())/2, 'head_width':hw, 'foot_y':y1})
        directions[direction] = entries
    result = {'asset':path.name,'size':[width,height],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'directions':directions,'poses':['idle','walk_left','walk_pass','walk_right','windup','strike','recover','hurt'],'notes':'32 separate original drawings. Native alpha contours isolate figures and prevent neighboring swords from leaking across generated grid cells. Head-width registration and grounded boots control scale; no source pixels are rewritten.'}
    (ROOT/f'{role}_catalog.json').write_text(json.dumps(result,indent=2)+'\n')
    print(role,{direction:[entry['head_width'] for entry in poses] for direction,poses in directions.items()})

if __name__ == '__main__':
    for role in ['raider','mauler']:
        register(role)
