"""Bake fur (red) and scarf (green) material channels for the painted spaniel.

Registration coordinates match the original sprite sheets. Head seams follow
the ears and muzzle, with extra clearance around the scarf and backpack strap.
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1] / "assets" / "avatar"
SHEETS = {
    "motion": "spaniel_motion",
    "run": "spaniel_sprint",
    "combat": "spaniel_combat",
    "mounted": "spaniel_mounted",
}
HEAD_SEAMS = {
    "s": [(0, 1.02), (.24, 1.02), (.31, .81), (.42, .85), (.55, .86),
          (.66, .80), (.72, 1.02), (1.02, 1.02)],
    "se": [(0, 1.02), (.34, 1.02), (.46, .79), (.67, .82),
           (.77, .75), (.82, .94), (1.02, .94)],
    "e": [(0, 1.02), (.49, 1.02), (.61, .79), (.79, .81), (1.02, .78)],
    "ne": [(0, .92), (.22, .93), (.32, .78), (.41, .86),
           (.52, 1.02), (.80, 1.02), (.89, .80), (1.02, .79)],
    "n": [(0, 1.02), (.23, 1.02), (.33, .79), (.45, .86),
          (.56, .85), (.68, .79), (.76, 1.02), (1.02, 1.02)],
}
# These tails lie across the legs, so trace the seam instead of using a
# neighborhood around the tip as for tails that project beyond the clothing.
REAR_TAILS = {
    "motion": [
        [(1352, 239), (1364, 242), (1368, 251), (1375, 263), (1370, 278),
         (1362, 287), (1353, 290), (1344, 281), (1338, 269), (1339, 253)],
        [(1362, 566), (1366, 581), (1358, 599), (1344, 610), (1326, 618),
         (1315, 614), (1308, 605), (1317, 585), (1334, 576)],
        [(1352, 906), (1368, 912), (1376, 925), (1378, 940), (1368, 953),
         (1357, 960), (1342, 954), (1334, 944), (1338, 928)],
    ],
    "mounted": [
        [(1924, 493), (1941, 488), (1956, 497), (1971, 519), (1974, 546),
         (1961, 576), (1938, 602), (1920, 588), (1907, 569), (1900, 544),
         (1907, 515)],
    ],
    "run": [
        [(1241, 175), (1268, 172), (1280, 179), (1271, 193), (1250, 200),
         (1228, 198), (1217, 190)],
        [(1241, 439), (1268, 435), (1282, 445), (1270, 459), (1249, 470),
         (1222, 472), (1207, 461), (1221, 450)],
        [(1240, 727), (1265, 721), (1280, 728), (1271, 744), (1248, 756),
         (1223, 756), (1216, 745)],
        [(1241, 1005), (1269, 999), (1283, 1008), (1275, 1024), (1255, 1035),
         (1230, 1033), (1218, 1025)],
    ],
}


def smooth(low, high, values):
    t = np.clip((values - low) / (high - low), 0, 1)
    return t * t * (3 - 2 * t)


def polygon(size, points):
    layer = Image.new("L", size)
    ImageDraw.Draw(layer).polygon(points, fill=255)
    return np.asarray(layer) / 255.0


def palette_cel(cel, pixels, direction, kind, frame):
    x, y, w, h = cel["region"]
    hx, hy, hw, hh = cel["head"]
    rgb = pixels[:, :, :3] / 255.0
    r, g, b = rgb.transpose(2, 0, 1)
    ys, xs = np.indices((h, w))
    u, v = (xs - hx) / hw, (ys - hy) / hh
    seam = [(hx + px * hw, hy + py * hh) for px, py in HEAD_SEAMS[direction]]
    head = polygon((w, h), [(hx, 0), (hx + hw * 1.02, 0), *reversed(seam)])

    def patch(center, radii):
        px, py = center
        rx, ry = radii
        distance = np.hypot((u - px) / rx, (v - py) / ry)
        return 1 - smooth(.78, 1.03, distance)

    # Red fabric has a different pigment from the chestnut ears and the
    # brown leather. Use that distinction to find the folds inside the scarf.
    pigment = (g - b) / np.maximum(r - g, .01)
    red = smooth(.045, .13, r - g) * (1 - smooth(.23, .35, pigment))
    sx, sy, sr, sb = cel["scarf"]
    scarf = red * ((u >= sx - .035) & (u <= sr + .025) & (v >= sy - .04) & (v <= sb + .045))

    coat = smooth(.065, .16, r - g) * smooth(.17, .34, r - b) * smooth(.16, .39, r)
    paws = np.maximum(patch(cel["fur"][0], (.101, .133)), patch(cel["fur"][1], (.101, .133)))
    # Ivory cuffs have less chroma than the painted paws.
    paws *= smooth(.22, .37, r - b) * smooth(.085, .16, r - g)
    tail = patch(cel["fur"][2], (.155, .174))
    if direction == "n" and kind in REAR_TAILS:
        tail = polygon((w, h), [(px - x, py - y) for px, py in REAR_TAILS[kind][frame]])
    tail *= (1 - smooth(.57, .70, pigment))
    # Preserve the cloth even when Crimson is selected and does not get tinted.
    fur = coat * np.maximum.reduce((head, paws, tail)) * (1 - np.maximum(scarf, red))
    covered = pixels[:, :, 3] > 0
    return np.stack((fur, scarf, np.zeros_like(fur)), axis=-1) * covered[:, :, None]


def main():
    catalog = json.loads((ROOT / "spaniel_registration.json").read_text())
    for kind, sheet in SHEETS.items():
        image = np.asarray(Image.open(ROOT / (sheet + ".png")).convert("RGBA"))
        mask = np.zeros((*image.shape[:2], 3), dtype=np.uint8)
        for direction, frames in catalog[kind].items():
            for index, cel in enumerate(frames):
                x, y, w, h = cel["region"]
                pixels = image[y:y + h, x:x + w]
                mask[y:y + h, x:x + w] = np.rint(255 * palette_cel(cel, pixels, direction, kind, index)).astype(np.uint8)
        Image.fromarray(mask).save(ROOT / (sheet + "_palette.png"), optimize=True)


if __name__ == "__main__":
    main()
