"""Read-only PNG QA and native atlas registration; never rewrites image pixels."""
from pathlib import Path
import hashlib
import json
import math
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RES = "res://experiments/anime_hub_assets_v06/"
SHEETS = {"cat_adventurer", "dog_warden"}
DISPLAY_HEIGHT = {
    "community_hall": 620, "bakery": 520, "grocer_shop": 520,
    "bookshop": 520, "ivy_cottage": 500, "balcony_cottage": 500,
    "bakery_stall": 210, "produce_stall": 225,
    "elm_tree": 500, "willow_tree": 510, "fountain": 225, "bench": 85,
    "street_lamp": 230, "notice_board": 175, "postbox": 115,
    "flower_planter": 85,
}


def bbox(mask):
    yy, xx = np.nonzero(mask)
    if not len(xx):
        raise ValueError("Empty sprite region")
    return [int(xx.min()), int(yy.min()), int(xx.max()+1-xx.min()), int(yy.max()+1-yy.min())]


def register_sheet(identifier, im):
    alpha = np.asarray(im.getchannel("A"))
    w, h = im.size
    frames = []
    def gap(projection, target, radius):
        lo, hi = max(0, target-radius), min(len(projection), target+radius+1)
        candidates = np.arange(lo, hi)
        empty = candidates[projection[lo:hi] == projection[lo:hi].min()]
        return int(empty[np.abs(empty-target).argmin()])
    columns = [0] + [gap((alpha>=32).sum(axis=0), i*w//4, w//16) for i in range(1,4)] + [w]
    for row in range(3):
        for col in range(4):
            x0, x1 = columns[col], columns[col+1]
            projection = (alpha[:,x0:x1]>=32).sum(axis=1)
            rows = [0] + [gap(projection, i*h//3, h//12) for i in range(1,3)] + [h]
            y0, y1 = rows[row], rows[row+1]
            x, y, fw, fh = bbox(alpha[y0:y1, x0:x1] >= 32)
            # Align the head/body horizontally, not the sword/tail bounding box.
            upper = alpha[y0+y:y0+y+max(1, int(fh*.30)), x0+x:x0+x+fw] >= 128
            head_x = float(np.median(np.nonzero(upper)[1])) + x0+x
            frames.append({"row": row, "column": col, "region": [x0+x, y0+y, fw, fh],
                           "source_partition": [x0,y0,x1-x0,y1-y0],
                           "anchor_x": round(head_x, 2),
                           "cell_padding": [x, y, x1-x0-x-fw, y1-y0-y-fh]})
    half = max(max(f["anchor_x"]-f["region"][0], f["region"][0]+f["region"][2]-f["anchor_x"]) for f in frames)+24
    canvas = [int(math.ceil(half)*2), max(f["region"][3] for f in frames)+48]
    text = [f'[gd_resource type="SpriteFrames" load_steps=14 format=3]',
            f'[ext_resource type="Texture2D" path="{RES}characters/{identifier}.png" id="1"]']
    for i, f in enumerate(frames):
        x, y, fw, fh = f["region"]
        mx = canvas[0]/2-(f["anchor_x"]-x)
        my = canvas[1]-24-fh
        f["margin"] = [round(mx, 2), my, canvas[0]-fw, canvas[1]-fh]
        text += [f'[sub_resource type="AtlasTexture" id="F{i}"]', 'atlas = ExtResource("1")',
                 f'region = Rect2({x}, {y}, {fw}, {fh})',
                 f'margin = Rect2({mx:.2f}, {my}, {canvas[0]-fw}, {canvas[1]-fh})']
    animations = []
    for col, direction in enumerate(["se", "sw", "ne", "nw"]):
        for name, indices, speed in [("idle", [col], 1), ("walk", [4+col, 8+col], 6)]:
            entries = ', '.join('{"duration": 1.0, "texture": SubResource("F%d")}' % i for i in indices)
            animations.append('{"frames": [%s], "loop": true, "name": &"%s_%s", "speed": %s.0}' % (entries, name, direction, speed))
    text += ['[resource]', 'animations = [\n'+',\n'.join(animations)+'\n]']
    (ROOT/"godot"/f"{identifier}_frames.tres").write_text('\n\n'.join(text)+'\n')
    return {"columns": 4, "rows": 3, "directions": ["se", "sw", "ne", "nw"],
            "frame_canvas": canvas, "foot_baseline_y": canvas[1]-24,
            "opaque_height_range": [min(f["region"][3] for f in frames), max(f["region"][3] for f in frames)],
            "frames": frames, "status": "registered draft: idle plus two walking poses per direction; no attack animation"}


def edge_image(path):
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=float)/255
    gray = rgb @ np.array([.2126, .7152, .0722])
    dy, dx = np.gradient(gray)
    edges = np.sqrt(dx*dx+dy*dy)
    return np.minimum(edges, np.quantile(edges, .985))


def phase_shift(a, b):
    window = np.outer(np.hanning(a.shape[0]), np.hanning(a.shape[1]))
    aa, bb = (a-a.mean())*window, (b-b.mean())*window
    cross = np.fft.fft2(aa)*np.conj(np.fft.fft2(bb))
    cross /= np.maximum(np.abs(cross), 1e-12)
    corr = np.abs(np.fft.ifft2(cross))
    yy, xx = np.unravel_index(corr.argmax(), corr.shape)
    yy = int(yy if yy<=a.shape[0]//2 else yy-a.shape[0])
    xx = int(xx if xx<=a.shape[1]//2 else xx-a.shape[1])
    return xx, yy, float(corr.max()/(corr.mean()+1e-12))


def registration():
    reference = edge_image(ROOT/"backgrounds/plaza_noon.png")
    h, w = reference.shape
    result = {"method": "Read-only integer phase correlation of luminance-gradient images, globally and on 32 local patches. No warping or image rewriting.",
              "limit": "Diagnostic only; zero measured shift is not proof of pixel-identical geometry between differently lit paintings.", "variants": {}}
    for time in ["dawn", "dusk", "night"]:
        other = edge_image(ROOT/f"backgrounds/plaza_{time}.png")
        if other.shape != reference.shape:
            result["variants"][time] = {"same_size": False, "status": "requires alignment"}
            continue
        gx, gy, confidence = phase_shift(reference, other)
        local = []
        for y in np.linspace(96, h-96, 4).astype(int):
            for x in np.linspace(96, w-96, 8).astype(int):
                dx, dy, score = phase_shift(reference[y-64:y+64, x-64:x+64], other[y-64:y+64, x-64:x+64])
                local.append({"center": [int(x), int(y)], "shift_px": [dx, dy], "confidence": round(score, 2)})
        shifts = [math.hypot(*p["shift_px"]) for p in local]
        result["variants"][time] = {"same_size": True, "global_shift_px": [gx, gy], "global_confidence": round(confidence, 2),
                                    "local_median_shift_px": round(float(np.median(shifts)), 2),
                                    "local_p95_shift_px": round(float(np.quantile(shifts, .95)), 2),
                                    "local_max_shift_px": round(max(shifts), 2), "patches": local,
                                    "status": "prototype candidate; inspect transitions before production"}
    return result


def main():
    doc = json.loads((ROOT/"generation_prompts.json").read_text())
    previous_path = ROOT/"catalog.json"
    previous = json.loads(previous_path.read_text()).get("assets", {}) if previous_path.exists() else {}
    assets, issues = {}, []
    for job in doc["jobs"]:
        path = ROOT/job["file"]
        im = Image.open(path)
        data = np.asarray(im)
        alpha = data[:, :, 3] if im.mode=="RGBA" else np.full((im.height, im.width), 255)
        transparent = job["transparent"]
        region = bbox(alpha>=32)
        x, y, w, h = region
        clear_fraction = float((alpha<16).mean())
        padding = [x, y, im.width-x-w, im.height-y-h]
        if transparent and (im.mode!="RGBA" or clear_fraction<.10):
            issues.append(job["id"]+": missing or insufficient real alpha")
        if transparent and min(padding)<3:
            issues.append(job["id"]+": inspect possible clipped edge or alpha specks")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        source = Path(job["source"])
        expected = hashlib.sha256(source.read_bytes()).hexdigest() if source.exists() else previous.get(job["id"], {}).get("sha256")
        if expected is None:
            issues.append(job["id"]+": no original or recorded hash available")
        elif digest != expected:
            issues.append(job["id"]+": source copy mismatch")
        asset = {"file": job["file"], "source": job["source"], "sha256": digest,
                 "size": list(im.size), "mode": im.mode, "transparent": transparent,
                 "clear_pixel_fraction": round(clear_fraction, 4), "opaque_bounds": region,
                 "transparent_padding": padding, "anchor_source": [x+w/2, y+h],
                 "recommended_height_at_1080p": DISPLAY_HEIGHT.get(job["id"], 112),
                 "category": job["file"].split('/')[0]}
        if job["id"] in SHEETS:
            asset["sheet"] = register_sheet(job["id"], im)
            if min(min(f["cell_padding"]) for f in asset["sheet"]["frames"])<1:
                issues.append(job["id"]+": pose touches partition; inspect slicing")
        elif transparent:
            (ROOT/"godot"/f"{job['id']}.tres").write_text(
                '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n'
                f'[ext_resource type="Texture2D" path="{RES}{job["file"]}" id="1"]\n'
                '[resource]\natlas = ExtResource("1")\n'
                f'region = Rect2({x}, {y}, {w}, {h})\n')
        assets[job["id"]] = asset
    report = {"source_png_count": len(assets), "transparent_png_count": sum(a["transparent"] for a in assets.values()),
              "issues": issues, "background_registration": registration(),
              "scope": "Checks actual alpha, padding, source hashes and frame registration. Does not certify drawing quality, pixel-perfect relighting or finished animation."}
    (ROOT/"catalog.json").write_text(json.dumps({"assets": assets}, indent=2)+'\n')
    (ROOT/"qa_report.json").write_text(json.dumps(report, indent=2)+'\n')
    groups = ["backgrounds", "buildings", "characters", "vendors", "scenery"]
    lines = ["# Hub asset catalog", "", "Original source PNGs generated with built-in imagegen; native atlas resources preserve the originals.", ""]
    for group in groups:
        lines += ["## "+group.title(), ""]
        for identifier, a in assets.items():
            if a["category"] != group:
                continue
            desc = "registered 4-direction idle/walk draft" if identifier in SHEETS else ("transparent cutout" if a["transparent"] else "lighting background")
            lines += [f"### {identifier.replace('_', ' ').title()}", "", f"[{a['file']}]({a['file']}) — {a['size'][0]} × {a['size'][1]}, {desc}.", "", f"![{identifier}]({a['file']})", ""]
    (ROOT/"CATALOG.md").write_text('\n'.join(lines))
    print(json.dumps({"pngs": len(assets), "cutouts": report["transparent_png_count"], "issues": issues,
                      "registration": {k: {key: value for key, value in v.items() if key!="patches"} for k,v in report["background_registration"]["variants"].items()}}, indent=2))
    if issues:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
