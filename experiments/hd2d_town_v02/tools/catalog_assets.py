"""Read source PNGs; preserve every pixel and write native texture regions only."""
import hashlib
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
catalog = {}
for path in sorted((root / "assets").glob("*.png")):
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    box = alpha.point(lambda a: 255 if a >= 230 else 0).getbbox()
    x, y, right, bottom = box
    catalog[path.stem] = {
        "file": path.name,
        "source_size": list(image.size),
        "region": [x, y, right - x, bottom - y],
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "readiness": "Animation concept sheet; needs pixel registration review" if path.stem == "resident_walk" else "Fixed-angle scenery card; baked local shading",
    }
    if path.stem == "resident_walk":
        # Generated sheets do not guarantee an exact grid. Detect the sixteen
        # separate silhouettes, then register their feet with AtlasTexture margins.
        width, height = image.size
        mask = bytearray(1 if a >= 230 else 0 for a in alpha.tobytes())
        components = []
        for start in range(width * height):
            if not mask[start]:
                continue
            mask[start] = 0
            stack = [start]
            count = 0
            left = right = start % width
            top = bottom = start // width
            while stack:
                point = stack.pop()
                y, x = divmod(point, width)
                count += 1
                left, right = min(left, x), max(right, x)
                top, bottom = min(top, y), max(bottom, y)
                for nx, ny in ((x-1,y), (x+1,y), (x,y-1), (x,y+1)):
                    if not (0 <= nx < width and 0 <= ny < height):
                        continue
                    index = ny * width + nx
                    if mask[index]:
                        mask[index] = 0
                        stack.append(index)
            if count > 1000:
                components.append([left, top, right-left+1, bottom-top+1])
        assert len(components) == 16, f"Expected sixteen silhouettes, found {len(components)}"
        components.sort(key=lambda box: box[1])
        frames = []
        for row in range(4):
            frames.extend(sorted(components[row*4:row*4+4], key=lambda box: box[0]))
        catalog[path.stem]["frames"] = frames
        catalog[path.stem]["frame_canvas"] = [180, 300]
(root / "assets" / "catalog.json").write_text(json.dumps(catalog, indent=2) + "\n")
print(f"Cataloged {len(catalog)} original PNGs without modifying source pixels.")
