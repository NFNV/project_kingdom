"""Read-only pixel checks for the specific yaw/tail discontinuity in south art."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets' / 'motion'


def measure(filename, registration):
    pixels = np.asarray(Image.open(ART / filename).convert('RGBA')).astype(float)
    measured = []
    for index, frame in enumerate(registration['frames']):
        x, y, w, h = frame['region']
        cell = pixels[y:y+h, x:x+w]
        r, g, b = cell[:, :, :3].transpose(2, 0, 1)
        yy, xx = np.indices((h, w))
        hx, hy = frame['head']['center']
        width = frame['head']['width']
        opaque = cell[:, :, 3] > 128
        orange = opaque & (r > 140) & (r > 1.17*g) & (g > 1.2*b)
        lower = orange & (yy > hy+width*.85) & (yy < hy+width*1.65)
        left = int((lower & (xx < hx-width*.55)).sum())
        right = int((lower & (xx > hx+width*.55)).sum())
        muzzle = opaque & (r > 165) & (g > r*.86) & (b > g*.72)
        muzzle &= (yy > hy+width*.23) & (yy < hy+width*.50) & (abs(xx-hx) < width*.48)
        _, mx = np.where(muzzle)
        bias = float((np.median(mx)-hx)/width) if len(mx) else 1.0
        measured.append({'pose': index, 'muzzle_center_bias': round(bias, 4),
                         'left_peripheral_orange_pixels': left, 'right_peripheral_orange_pixels': right,
                         'front_centered': abs(bias) < .05, 'tail_stays_right': right > max(200, 3*left)})
    return {'poses': measured, 'front_centered_count': sum(f['front_centered'] for f in measured),
            'tail_stays_right_count': sum(f['tail_stays_right'] for f in measured),
            'max_muzzle_bias': round(max(abs(f['muzzle_center_bias']) for f in measured), 4)}


def main():
    previous = json.loads((ART / 'cat_s_v1_reference.json').read_text())
    selected = json.loads((ART / 'registration.json').read_text())['cat_s']
    baseline = measure('cat_s.png', previous['registration'])
    current = measure('cat_s_v2.png', selected)
    report = {'previous': baseline, 'selected': current,
              'notes': 'Read-only color/landmark heuristics for this orange cat, with native visual review. Muzzle bias is normalized by head width. Peripheral orange detects the tail side, with some paw pixels. These checks target the recorded discontinuities; they do not certify animation quality or gait anatomy.'}
    assert baseline['front_centered_count'] < 20 and baseline['tail_stays_right_count'] < 20, 'Audit must catch the recorded faulty sheet'
    assert current['front_centered_count'] == 20, 'A south pose turns away from the centered front view'
    assert current['tail_stays_right_count'] == 20, 'A south pose moves the tail to the wrong side'
    (ART / 'front_cycle_v2_audit.json').write_text(json.dumps(report, indent=2)+'\n')
    print(f'Front art: {current["front_centered_count"]}/20 centered faces; {current["tail_stays_right_count"]}/20 consistent tail sides. Old sheet fails both checks.')


if __name__ == '__main__':
    main()
