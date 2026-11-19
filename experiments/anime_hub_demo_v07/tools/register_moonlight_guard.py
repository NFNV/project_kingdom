"""Register native sprite regions and emit Godot resources; never rewrite PNGs."""
from pathlib import Path
import hashlib
import json
import math
import numpy as np
from PIL import Image
from register_combat_transitions import components

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'moonlight_guard'
DIRECTIONS = ['se', 'sw', 'ne', 'nw']
POSES = ['idle', 'walk_left', 'walk_pass', 'walk_right', 'windup', 'strike', 'recover', 'hurt']
ANIMATIONS = {'idle': ([0], 2, True), 'walk': ([1, 2, 3, 2], 7, True),
              'windup': ([4], 4, False), 'strike': ([5], 4, False),
              'recover': ([6], 4, False), 'hurt': ([7], 4, False),
              'attack': ([4, 5, 6], 5, False)}


def figures(filename, columns, rows):
    path = ROOT / filename
    image = np.asarray(Image.open(path).convert('RGBA'))
    height, width = image.shape[:2]
    alpha = image[:, :, 3]
    assert (alpha == 0).mean() > .20, f'{filename}: background is not transparent'
    yy, xx = np.where(alpha > 180)
    blobs = sorted(components(yy * width + xx, width), key=len, reverse=True)
    count = columns * rows
    assert len(blobs) >= count and len(blobs[count - 1]) > 1200, (filename, 'missing figures')
    assert len(blobs) == count or len(blobs[count]) < len(blobs[count - 1]) * .08, (filename, 'split/connected figures')
    bodies = sorted(blobs[:count], key=lambda b: float(np.median(b // width)))
    result = []
    for row in range(rows):
        group = sorted(bodies[row * columns:(row + 1) * columns], key=lambda b: float(np.median(b % width)))
        for column, body in enumerate(group):
            ys, xs = body // width, body % width
            x0, x1, y0, y1 = int(xs.min()), int(xs.max() + 1), int(ys.min()), int(ys.max() + 1)
            # Median body mass ignores narrow projecting spear/sword tips.
            torso = (ys > y0 + (y1-y0)*.3) & (ys < y0 + (y1-y0)*.7)
            pivot = float(np.median(xs[torso]))
            feet = ys[(abs(xs-pivot) < width/columns*.26) & (ys > y0+(y1-y0)*.55)]
            foot = float(np.percentile(feet, 99.8)) + 1
            result.append({'asset': filename, 'region': [x0, y0, x1-x0, y1-y0], 'pivot_x': pivot, 'foot_y': foot})
    return result, {'asset': filename, 'size': [width, height], 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def resource(role, directions, sources):
    entries = [p for poses in directions.values() for p in poses]
    half_width = math.ceil(max(max(p['pivot_x']-p['region'][0], p['region'][0]+p['region'][2]-p['pivot_x']) for p in entries))+4
    foot_line = math.ceil(max(p['foot_y']-p['region'][1] for p in entries))+4
    bottom = math.ceil(max(p['region'][1]+p['region'][3]-p['foot_y'] for p in entries))+4
    canvas = [half_width*2, foot_line+bottom]
    catalog = {'role': role, 'directions': directions, 'poses': POSES, 'sources': sources,
               'canvas': canvas, 'foot_line': foot_line,
               'reference_height': directions['se'][0]['region'][3],
               'notes': 'Native PNGs unchanged. Regions isolate 32 figures; transparent AtlasTexture margins register feet and body mass. Draft directional actions, no combat behavior attached.'}
    (ROOT / f'{role}_catalog.json').write_text(json.dumps(catalog, indent=2)+'\n')
    assets = list(dict.fromkeys(p['asset'] for p in entries))
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(assets)+len(entries)+1} format=3]', '']
    for i, asset in enumerate(assets):
        lines += [f'[ext_resource type="Texture2D" path="res://experiments/anime_hub_demo_v07/assets/moonlight_guard/{asset}" id="{i+1}"]', '']
    for i, p in enumerate(entries):
        x, y, w, h = p['region']
        left = half_width-(p['pivot_x']-x)
        top = foot_line-(p['foot_y']-y)
        assert left >= 0 and top >= 0
        lines += [f'[sub_resource type="AtlasTexture" id="Frame_{i}"]',
                  f'atlas = ExtResource("{assets.index(p["asset"])+1}")',
                  f'region = Rect2({x}, {y}, {w}, {h})',
                  f'margin = Rect2({left}, {top}, {canvas[0]-w}, {canvas[1]-h})', '',]
    animations = []
    for d, direction in enumerate(DIRECTIONS):
        for name, (indices, fps, loop) in ANIMATIONS.items():
            frames = ', '.join('{"duration": 1.0, "texture": SubResource("Frame_%d")}' % (d*8+i) for i in indices)
            animations.append('{"frames": [%s], "loop": %s, "name": &"%s_%s", "speed": %s}' % (frames, str(loop).lower(), name, direction, fps))
    lines += ['[resource]', 'animations = ['+',\n'.join(animations)+']', '']
    (ROOT / f'{role}_frames.tres').write_text('\n'.join(lines))
    print(role, '32 registered figures', 'canvas', canvas)


def main():
    for role in ['ashen_vanguard', 'briar_spearman', 'gloam_arbalist']:
        poses, source = figures(role+'.png', 8, 4)
        resource(role, {d: poses[i*8:(i+1)*8] for i, d in enumerate(DIRECTIONS)}, [source])
    directions, sources = {}, []
    for d in DIRECTIONS:
        directions[d], source = figures('blackthorn_'+d+'.png', 4, 2)
        sources.append(source)
    resource('blackthorn_captain', directions, sources)


if __name__ == '__main__':
    main()
