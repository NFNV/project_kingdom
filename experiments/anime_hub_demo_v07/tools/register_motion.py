"""Register generated originals using native AtlasTexture margins; never rewrite PNG pixels."""
from pathlib import Path
import hashlib
import json
import shutil
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'motion'
RES = 'res://experiments/anime_hub_demo_v07/assets/motion/'


def head_landmark(pixels):
    """Measure the connected orange head, excluding the separate tail and paws."""
    rgb = pixels[:, :, :3].astype(float)
    r, g, b = rgb.transpose(2, 0, 1)
    yy, _ = np.indices(r.shape)
    mask = (pixels[:, :, 3] > 96) & (r > 145) & (r > g*1.17) & (g > b*1.2) & (yy < r.shape[0]*.56)
    unseen = mask.copy()
    largest = []
    for y, x in zip(*np.where(mask)):
        if not unseen[y, x]:
            continue
        unseen[y, x] = False
        pending, points = [(y, x)], []
        while pending:
            a, c = pending.pop()
            points.append((a, c))
            for v, u in ((a-1,c),(a+1,c),(a,c-1),(a,c+1)):
                if 0 <= v < unseen.shape[0] and 0 <= u < unseen.shape[1] and unseen[v,u]:
                    unseen[v,u] = False
                    pending.append((v,u))
        if len(points) > len(largest):
            largest = points
    if len(largest) < 1500:
        raise ValueError('Head landmark needs review')
    y, x = np.asarray(largest).T
    xlo, xhi = np.percentile(x, [2,98])
    ylo, yhi = np.percentile(y, [2,98])
    return {'center':[float((xlo+xhi)/2),float((ylo+yhi)/2)], 'width':float(xhi-xlo)}


def partitions(mask, count, axis):
    length = mask.shape[axis]
    projection = mask.sum(axis=1-axis)
    edges = [0]
    for index in range(1, count):
        ideal = length * index / count
        low = max(edges[-1]+20, round(ideal-length/count*.30))
        high = min(length-20, round(ideal+length/count*.30))
        quiet = np.flatnonzero(projection[low:high] <= 2)+low
        runs = np.split(quiet, np.where(np.diff(quiet)>1)[0]+1)
        runs = [r for r in runs if len(r)]
        edge = round(float(min(runs, key=lambda r: abs(r.mean()-ideal)).mean())) if runs else low+int(np.argmin(projection[low:high]))
        edges.append(edge)
    return edges+[length]


def main():
    jobs = json.loads((ROOT/'generation_prompts.json').read_text())['jobs']
    catalog, report = {}, {}
    groups = {}
    for spec in jobs:
        data = json.loads((ROOT/(spec['id']+'.json')).read_text())
        path = ROOT/data.get('file',spec['id']+'.png')
        spec = dict(spec, texture_file=path.name)
        shutil.copyfile(data['source'],path)
        pixels = np.asarray(Image.open(path).convert('RGBA'))
        mask = pixels[:,:,3] >= 64
        xs = partitions(mask, spec['columns'], 1)
        ys = partitions(mask, spec['rows'], 0)
        frames, hashes = [], []
        for row in range(spec['rows']):
            for col in range(spec['columns']):
                x0,x1,y0,y1 = xs[col],xs[col+1],ys[row],ys[row+1]
                cell = mask[y0:y1,x0:x1]
                yy,xx = np.where(cell)
                if not len(xx):
                    raise ValueError(f'Empty pose {spec["id"]} {row} {col}')
                left,right,top,bottom = xx.min(),xx.max()+1,yy.min(),yy.max()+1
                head = cell[top:top+max(8,round((bottom-top)*.30)),:]
                column_weights = head.sum(axis=0)
                cumulative = np.cumsum(column_weights)
                anchor_x = int(np.searchsorted(cumulative,cumulative[-1]*.5))
                region = [int(x0+left),int(y0+top),int(right-left),int(bottom-top)]
                # A common canvas and a planted boot baseline. Only texture margins change.
                margin = [int(256-(anchor_x-left)),int(488-(bottom-top)),int(512-(right-left)),int(512-(bottom-top))]
                if min(margin[2:]) < 0:
                    raise ValueError('Pose exceeds the registration canvas')
                frames.append({'region':region,'margin':margin,'source_anchor':[int(x0+anchor_x),int(y0+bottom)],'height':int(bottom-top)})
                if spec['kind'] == 'cat':
                    frames[-1]['head'] = head_landmark(pixels[y0+top:y0+bottom,x0+left:x0+right])
                hashes.append(hashlib.sha256(pixels[y0:y1,x0:x1].tobytes()).hexdigest())
        kind = spec['kind']
        actor = kind if kind != 'resident' else spec['id']
        direction = spec.get('direction','se')
        height = float(np.median([f['height'] for f in frames[-4:]] if kind!='resident' else [f['height'] for f in frames[:8]]))
        catalog.setdefault(actor,{})[direction] = {'height':height,'source':path.name}
        if kind == 'cat':
            # Align a rigid anatomical landmark, never the alternating/lifted boot.
            # Match head size across walk/run/idle without touching source pixels.
            head_width = float(np.median([f['head']['width'] for f in frames[16:20]]))
            calibration = {}
            for state, indices in {'walk':range(8),'run':range(8,16),'idle':range(16,20)}.items():
                poses = []
                for i in indices:
                    f = frames[i]
                    hx, hy = f['head']['center']
                    w, h = f['region'][2:]
                    correction = head_width/f['head']['width']
                    if not .75 < correction < 1.3:
                        raise ValueError(f'Unexpected head scale: {spec["id"]} {i}')
                    f['foot_margin'] = f['margin']
                    f['margin'] = [256-hx,256-hy,512-w,512-h]
                    f['source_anchor'] = [f['region'][0]+hx,f['region'][1]+hy]
                    poses.append({'scale':correction,'head_width':f['head']['width'], 'head_center':[hx,hy]})
                # Preserve the average stance/crouch of each gait. Only the body's
                # deliberate bob remains; individual boot extremes cannot move it.
                ground_height = float(np.median([(frames[i]['height']-frames[i]['head']['center'][1])*poses[j]['scale'] for j,i in enumerate(indices)]))
                calibration[state] = {'head_ground_height':ground_height,'poses':poses}
            catalog[actor][direction]['body_registration'] = calibration
            catalog[actor][direction]['head_width'] = head_width
        groups.setdefault(actor,[]).append((spec,frames))
        report[spec['id']] = {'source':data['source'],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'byte_identical_copy':path.read_bytes()==Path(data['source']).read_bytes(),'size':[int(pixels.shape[1]),int(pixels.shape[0])],'transparent_fraction':round(float((pixels[:,:,3]==0).mean()),4),'x_partitions':xs,'y_partitions':ys,'pose_count':len(frames),'distinct_pose_regions':len(set(hashes)),'height_range':[min(f['height'] for f in frames),max(f['height'] for f in frames)],'frames':frames}
    for actor,sheets in groups.items():
        resources,subs,anims = [],[],[]
        frame_number = 0
        for sheet_number,(spec,frames) in enumerate(sheets):
            ext = str(sheet_number+1)
            resources.append(f'[ext_resource type="Texture2D" path="{RES}{spec["texture_file"]}" id="{ext}"]')
            ids = []
            for frame in frames:
                uid = f'F{frame_number}'
                frame_number += 1
                ids.append(uid)
                subs.append(f'[sub_resource type="AtlasTexture" id="{uid}"]\natlas = ExtResource("{ext}")\nregion = Rect2({", ".join(map(str,frame["region"]))})\nmargin = Rect2({", ".join(map(str,frame["margin"]))})\nfilter_clip = true')
            direction = spec.get('direction','se')
            sequences = {'walk':ids[:8],'run':ids[8:16],'idle':ids[16:20]} if spec['kind']=='cat' else ({'walk':ids[:8],'idle':ids[8:12]} if spec['kind']=='warden' else {'idle':ids[:8],'gesture':ids[8:12]})
            for state,sequence in sequences.items():
                parts = ', '.join('{"duration": 1.0, "texture": SubResource("'+uid+'")}' for uid in sequence)
                anims.append('{"frames": ['+parts+'], "loop": true, "name": &"'+state+'_'+direction+'", "speed": 1.0}')
        output = f'[gd_resource type="SpriteFrames" load_steps={1+len(resources)+len(subs)} format=3]\n\n'+'\n\n'.join(resources+subs)+'\n\n[resource]\nanimations = [\n'+',\n'.join(anims)+'\n]\n'
        (ROOT/(actor+'_frames.tres')).write_text(output)
    (ROOT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n')
    (ROOT/'registration.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'Registered {sum(r["pose_count"] for r in report.values())} poses across {len(report)} original sheets. PNGs preserved byte for byte.')


if __name__ == '__main__':
    main()
