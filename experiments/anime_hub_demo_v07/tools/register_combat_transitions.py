"""Analyze original art; native polygons select figures without rewriting pixels."""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'combat'

def components(keys, width):
    remaining = set(map(int, keys))
    result = []
    while remaining:
        stack = [remaining.pop()]
        part = []
        while stack:
            value = stack.pop()
            part.append(value)
            for neighbor in (value-width, value+width, value-1, value+1):
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    stack.append(neighbor)
        result.append(np.asarray(part))
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--asset', default='cat_transitions_v2.png')
    parser.add_argument('--catalog', default='transitions_catalog.json')
    args = parser.parse_args()
    path = ROOT / args.asset
    image = np.asarray(Image.open(path).convert('RGBA'))
    h, w = image.shape[:2]
    yy, xx = np.where(image[:, :, 3] > 220)
    bodies = sorted(components(yy*w+xx, w), key=len, reverse=True)[:16]
    if len(bodies) != 16 or min(map(len, bodies)) < 2500:
        raise ValueError('Expected sixteen complete, separate characters')
    bodies.sort(key=lambda points: np.mean(points//w))
    directions = {}
    for row, direction in enumerate(['se', 'sw', 'ne', 'nw']):
        entries = []
        group = sorted(bodies[row*4:row*4+4], key=lambda points: np.mean(points%w))
        for body in group:
            ys, xs = body//w, body%w
            x0, x1, y0, y1 = int(xs.min()), int(xs.max()+1), int(ys.min()), int(ys.max()+1)
            rgb = image[ys, xs, :3].astype(float)
            fur = (rgb[:,0]>130)&(rgb[:,1]>65)&(rgb[:,0]>rgb[:,1]*1.15)&(rgb[:,2]<rgb[:,1]*.85)&(ys<y0+(y1-y0)*.64)
            head = max(components(body[fur], w), key=len)
            hy, hx = head//w, head%w
            width = int(hx.max()-hx.min()+1)
            if not 65 < width < 230:
                raise ValueError(f'Unexpected head size {width}')
            entries.append({'region':[x0,y0,x1-x0,y1-y0], 'foot_x':float(hx.min()+hx.max())/2, 'foot_y':y1, 'head_width':width, 'head_center_y':float(hy.min()+hy.max())/2, 'head_bottom_y':int(hy.max()+1), 'display_scale':round(31.5/width,6)})
        directions[direction] = entries
    report = {'asset':path.name, 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'size':[w,h], 'directions':directions, 'notes':'Read-only component and anatomical head registration. Sixteen original drawings are sampled with native alpha polygons; transparent margins and original pixels remain unchanged.'}
    (ROOT/args.catalog).write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({direction:[round((entry['foot_y']-entry['head_center_y'])*entry['display_scale'],2) for entry in entries] for direction,entries in directions.items()}))

if __name__ == '__main__':
    main()
