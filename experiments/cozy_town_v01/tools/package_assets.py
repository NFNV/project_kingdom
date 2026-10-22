"""Copy selected image-generation outputs and author native Godot asset scenes.

Pillow is used for measurement only. Source PNG pixels are never edited.
"""
from pathlib import Path
from PIL import Image
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "res://experiments/cozy_town_v01/"
REQUESTS = json.loads((ROOT / "generation_requests.json").read_text())
ORDER = ["house", "community_shop", "tree", "resident", "old_car", "bench",
         "notice_board", "street_lamp", "fence", "planter", "grass_tile",
         "pavement_tile", "road_tile"]
LABELS = {"house": "House exterior", "community_shop": "Neighborhood shop",
          "tree": "Street tree", "resident": "Resident concept",
          "old_car": "Vintage car", "bench": "Park bench",
          "notice_board": "Community board", "street_lamp": "Street lamp",
          "fence": "Garden fence", "planter": "Flower planter",
          "grass_tile": "Sage grass", "pavement_tile": "Biscuit paving",
          "road_tile": "Warm gray road"}


def write_new_or_same(path, content):
    if path.exists() and path.read_bytes() == content:
        return
    path.write_bytes(content)


manifest = {"logical_grid": 32, "composition_size": [640, 384],
            "alpha_cutoff": 0.97, "assets": []}
requests = {item["id"]: item for item in REQUESTS["assets"]}
for folder in ["assets/sources", "assets/textures", "assets/scenes", "previews"]:
    (ROOT / folder).mkdir(parents=True, exist_ok=True)

for key in ORDER:
    request = requests[key]
    source = Path(request["source"])
    if not source.is_absolute():
        source = ROOT / source
    destination = ROOT / "assets/sources" / (key + ".png")
    content = source.read_bytes()
    if destination.exists() and destination.read_bytes() != content:
        raise RuntimeError(f"Refusing to overwrite a different source: {destination}")
    if not destination.exists():
        shutil.copy2(source, destination)
    image = Image.open(source).convert("RGBA")
    alpha = image.getchannel("A")
    is_ground = request["category"] == "ground"
    body = (0, 0, image.width, image.height) if is_ground else alpha.point(
        lambda value: 255 if value >= 248 else 0).getbbox()
    assert body is not None, key
    left, top, right, bottom = body
    region = [max(0, left - 3), max(0, top - 3),
              min(image.width, right + 3), min(image.height, bottom + 3)]
    rx, ry, rr, rb = region
    region = [rx, ry, rr - rx, rb - ry]
    if key == "grass_tile":
        # A quieter excerpt avoids compressing the whole dense texture into 32px.
        # This is an AtlasTexture region; the generated PNG remains unchanged.
        left, top, right, bottom = 450, 450, 706, 706
        body = (left, top, right, bottom)
        rx, ry = left, top
        region = [left, top, 256, 256]
    logical_w, logical_h = request["logical_size"]
    scale = min(logical_w / (right - left), logical_h / (bottom - top))
    anchor = [((left + right) / 2 - rx) * scale, (bottom - ry) * scale]
    histogram = alpha.histogram()
    status = "concept pose" if key == "resident" else (
        "mockup texture" if is_ground else "reusable scene candidate")
    item = {"id": key, "label": LABELS[key], "category": request["category"],
            "status": status, "source": "assets/sources/" + key + ".png",
            "texture": "assets/textures/" + key + ".tres",
            "scene": "assets/scenes/" + key + ".tscn",
            "source_size": list(image.size), "source_region": region,
            "body_bounds": list(body), "logical_target": [logical_w, logical_h],
            "display_body_size": [round((right-left)*scale, 2), round((bottom-top)*scale, 2)],
            "scale": scale, "anchor": anchor,
            "source_sha256": hashlib.sha256(content).hexdigest(),
            "fully_transparent_pixels": histogram[0],
            "partial_alpha_pixels": sum(histogram[1:255]),
            "source_was_edited_by_packager": False,
            "region_note": "quiet 256px excerpt; seams still require authoring" if key == "grass_tile" else "source body bounds",
            "detail_opacity": 0.25 if key == "grass_tile" else 1.0,
            "requires_alpha_cutout": not is_ground}
    manifest["assets"].append(item)

    texture = f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{PREFIX}assets/sources/{key}.png" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2({', '.join(str(v) for v in region)})
filter_clip = true
'''
    write_new_or_same(ROOT / item["texture"], texture.encode())
    shader = "" if is_ground else f'''
[ext_resource type="Shader" path="{PREFIX}tools/pixel_cutout.gdshader" id="2"]

[sub_resource type="ShaderMaterial" id="Cutout"]
shader = ExtResource("2")
shader_parameter/alpha_cutoff = 0.97
'''
    material = "" if is_ground else 'material = SubResource("Cutout")\n'
    position = [0, 0] if is_ground else [-anchor[0], -anchor[1]]
    grass_base = '''
[node name="QuietBase" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 0, 32, 0, 32, 32, 0, 32)
color = Color(0.611765, 0.682353, 0.486275, 1)
''' if key == "grass_tile" else ""
    modulation = 'modulate = Color(1, 1, 1, 0.25)\n' if key == "grass_tile" else ""
    scene = f'''[gd_scene load_steps={2 if is_ground else 4} format=3]

[ext_resource type="Texture2D" path="{PREFIX}{item['texture']}" id="1"]
{shader}
[node name="{key}" type="Node2D"]
texture_filter = 1
{grass_base}
[node name="Sprite" type="Sprite2D" parent="."]
{material}{modulation}position = Vector2({position[0]}, {position[1]})
scale = Vector2({scale}, {scale})
texture = ExtResource("1")
centered = false
'''
    write_new_or_same(ROOT / item["scene"], scene.encode())

(ROOT / "asset_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
for request in REQUESTS["assets"]:
    if Path(request["source"]).is_absolute():
        request["generation_output_file"] = Path(request["source"]).name
    request["source"] = "assets/sources/" + request["id"] + ".png"
    if "previous_source" in request:
        request["previous_generation_file"] = Path(request.pop("previous_source")).name
(ROOT / "generation_requests.json").write_text(json.dumps(REQUESTS, indent=2) + "\n")
print(f"Packaged {len(manifest['assets'])} original asset sources and native scenes.")
print("Source PNGs were copied without raster editing; scales/regions live in Godot resources.")
