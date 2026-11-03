"""Read-only paw landmarks for carried gear; original sprite pixels stay intact."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'motion'

def components(mask):
    remaining = mask.copy()
    result = []
    for y, x in zip(*np.where(mask)):
        if not remaining[y, x]:
            continue
        remaining[y, x] = False
        queue, points = [(y, x)], []
        while queue:
            a, b = queue.pop()
            points.append((b, a))
            for u, v in ((a-1,b),(a+1,b),(a,b-1),(a,b+1)):
                if 0<=u<mask.shape[0] and 0<=v<mask.shape[1] and remaining[u,v]:
                    remaining[u,v] = False
                    queue.append((u,v))
        if 100<=len(points)<=1200:
            result.append((len(points),np.median(np.asarray(points),axis=0)))
    return result

def main():
    registration = json.loads((ROOT/'registration.json').read_text())
    result = {'notes':'Paw centers in each native AtlasTexture region; inferred hidden paws stay behind the body. Original PNGs are unchanged. Review with preview_equipment_alignment.gd.', 'directions':{}}
    for direction in ['e','se','s','sw','w','nw','n','ne']:
        data = registration['cat_'+direction]
        filename = 'cat_s_v2.png' if direction=='s' else 'cat_'+direction+'.png'
        pixels = np.asarray(Image.open(ROOT/filename).convert('RGBA')).astype(float)
        poses = []
        for index, frame in enumerate(data['frames']):
            x,y,w,h = frame['region']
            cell = pixels[y:y+h,x:x+w]
            r,g,b = cell[:,:,:3].transpose(2,0,1)
            yy,xx = np.indices((h,w))
            head = np.asarray(frame['head']['center'])
            width = frame['head']['width']
            running = 8<=index<16
            vertical = .88 if running else 1.12
            mask = (cell[:,:,3]>160)&(r>160)&(r>g*1.14)&(g>b*1.25)&(yy>head[1]+width*.7)&(yy<head[1]+width*1.9)
            candidates = components(mask)
            anchors = {}
            for item in ['weapon','shield']:
                right = item=='weapon'
                sign = 1 if direction in ['n','ne','nw'] else -1
                side = sign if right else -sign
                target = head+np.array([side*.5,vertical])*width
                hidden = (direction=='nw' and right) or (direction=='ne' and not right)
                pool = candidates
                if direction=='w':
                    # The near left arm crosses the torso while walking; its
                    # larger visible paw must not be mistaken for the far arm.
                    pool = [c for c in candidates if c[0]<350] if right else [c for c in candidates if c[0]>=350]
                if hidden:
                    pool = []
                if pool:
                    selected = max(pool,key=lambda c:c[0]) if direction=='w' and not right else min(pool,key=lambda c: np.linalg.norm((c[1]-target)/width)+max(0,c[0]-950)/600)
                    point = selected[1]
                    measured = (direction=='w' and not right) or np.linalg.norm((point-target)/width)<1.0
                else:
                    measured = False
                if not measured:
                    point = head+np.array([side*(.23 if hidden else .36),vertical])*width
                anchors[item] = {'point':[round(float(v),2) for v in point], 'measured':bool(measured)}
            if np.linalg.norm(np.asarray(anchors['weapon']['point'])-np.asarray(anchors['shield']['point']))<width*.22:
                # A single visible paw must never carry both items. Keep the
                # near arm's measurement and infer its occluded counterpart.
                far = 'weapon' if direction in ['w','sw','nw'] else 'shield'
                sign = (1 if direction in ['n','ne','nw'] else -1)*(1 if far=='weapon' else -1)
                point = head+np.array([sign*.30,vertical])*width
                anchors[far] = {'point':[round(float(v),2) for v in point], 'measured':False}
            poses.append(anchors)
        result['directions'][direction] = {'walk':poses[:8], 'run':poses[8:16], 'idle':poses[16:20]}
    (ROOT/'equipment_grips.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Registered 320 equipment grips across 160 original poses; PNGs unchanged.')

if __name__=='__main__':
    main()
