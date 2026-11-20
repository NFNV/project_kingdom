extends RefCounted
const ART := "res://experiments/anime_hub_assets_v06/"
const PAINTED := "res://experiments/overworld_2d_v01/art/architecture/"
const PALESTONE_ART := "res://experiments/overworld_2d_v01/art/palestone_kit/"
const HOUSE_KINDS := ["ivy_cottage","balcony_cottage","bakery","grocer_shop","bookshop","country_hall","palestone_cottage"]
const BUILDING_KINDS := HOUSE_KINDS+["city_illustration","windmill","watermill","lighthouse","ruins","moonlight_entrance"]
const TREE_KINDS := ["oak","pine","willow","coastal_pine","lakeside_alder"]
const LAMP_KINDS := ["lamp","coastal_lantern"]
const CATALOG := {
 "moonlight_entrance":"res://experiments/anime_hub_demo_v07/assets/moonlight/forest_entrance.png",
 "oak":ART+"scenery/elm_tree.png", "willow":ART+"scenery/willow_tree.png",
 "pine":"res://experiments/overworld_2d_v01/art/region/pine_grove.png",
 "rock":"res://experiments/overworld_2d_v01/art/region/coastal_rocks.png",
 "bush":"res://experiments/overworld_2d_v01/art/bush.svg",
 "windmill":"res://experiments/overworld_2d_v01/art/region/windmill.png",
 "ruins":"res://experiments/overworld_2d_v01/art/region/ruins.png",
 "city_illustration":PAINTED+"mosswood_painted_v1.png",
 "ivy_cottage":PAINTED+"cottage_sage_drawn_v1.png", "balcony_cottage":PAINTED+"cottage_ochre_drawn_v1.png",
 "bakery":PAINTED+"village_shop_drawn_v1.png", "grocer_shop":PAINTED+"village_shop_drawn_v1.png",
 "bookshop":PAINTED+"cottage_sage_drawn_v1.png", "country_hall":PAINTED+"cottage_ochre_drawn_v1.png",
 "bakery_stall":ART+"vendors/bakery_stall.png", "produce_stall":ART+"vendors/produce_stall.png",
 "flowers":ART+"scenery/flower_planter.png", "bench":ART+"scenery/bench.png",
 "lamp":ART+"scenery/street_lamp.png",
 "coastal_lantern":PALESTONE_ART+"coastal_lantern.png",
 "coastal_pine":PALESTONE_ART+"coastal_pine.png",
 "lakeside_alder":PALESTONE_ART+"lakeside_alder.png",
 "palestone_cottage":PALESTONE_ART+"palestone_cottage.png",
 "watermill":"res://experiments/overworld_2d_v01/art/region/watermill_v1.png",
 "lighthouse":"res://experiments/overworld_2d_v01/art/region/lighthouse_v1.png"
}
# Legacy cropped UVs for landmarks. Pixel-calibrated entries below override
# these positions when their textures are cached.
const EMITTERS := {
 "moonlight_entrance":[Vector2(.38,.70),Vector2(.63,.70)],
 "city_illustration":[Vector2(.20,.58),Vector2(.44,.35),Vector2(.71,.36),Vector2(.79,.63)],
 "ivy_cottage":[Vector2(.29,.67),Vector2(.60,.73)],
 "balcony_cottage":[Vector2(.29,.67),Vector2(.60,.73)],
 "bakery":[Vector2(.29,.67),Vector2(.60,.73)],
 "grocer_shop":[Vector2(.29,.67),Vector2(.60,.73)],
 "bookshop":[Vector2(.29,.67),Vector2(.60,.73)],
 "country_hall":[Vector2(.29,.67),Vector2(.60,.73)],
 "windmill":[Vector2(.43,.78),Vector2(.78,.81)],
 "watermill":[Vector2(.37,.64),Vector2(.50,.65)],
 "lighthouse":[Vector2(.35,.25),Vector2(.60,.76)],
 "lamp":[Vector2(.5,.18)]
}
# Original painting pixels, converted through the same runtime crop as the feet.
# Calibrate each house instead of placing the same two glows on every facade.
const SAGE_WINDOWS := [Vector2(438,664),Vector2(875,739),Vector2(671,405),Vector2(1156,461),Vector2(728,692)]
const OCHRE_WINDOWS := [Vector2(406,612),Vector2(874,704),Vector2(683,347),Vector2(1234,638),Vector2(1235,412),Vector2(713,615)]
const SHOP_WINDOWS := [Vector2(585,392),Vector2(1020,445),Vector2(386,765),Vector2(771,846),Vector2(1104,756),Vector2(230,631)]
const EMITTER_PIXELS := {
 "ivy_cottage":SAGE_WINDOWS,"bookshop":SAGE_WINDOWS,
 "balcony_cottage":OCHRE_WINDOWS,"country_hall":OCHRE_WINDOWS,
 "bakery":SHOP_WINDOWS,"grocer_shop":SHOP_WINDOWS,
 "lamp":[Vector2(508,373)],
 "coastal_lantern":[Vector2(767,586)],
 "palestone_cottage":[Vector2(811,593),Vector2(487,636),Vector2(1094,611)],
 "lighthouse":[Vector2(564,320),Vector2(798,888)],
 "city_illustration":[Vector2(345,335),Vector2(373,350),Vector2(475,291),Vector2(439,347),Vector2(496,340),Vector2(530,413),Vector2(596,375),Vector2(651,441),Vector2(699,284),Vector2(850,282),Vector2(690,348),Vector2(859,350),Vector2(1020,332),Vector2(1067,339),Vector2(1126,288),Vector2(951,438),Vector2(1023,449),Vector2(1097,458),Vector2(1210,438),Vector2(1247,453),Vector2(1311,438),Vector2(1355,433),Vector2(355,542),Vector2(247,580),Vector2(450,545),Vector2(516,690),Vector2(545,626),Vector2(677,664),Vector2(1060,648),Vector2(1090,588),Vector2(1205,617),Vector2(1165,687),Vector2(1228,678),Vector2(632,533),Vector2(925,573),Vector2(675,855),Vector2(966,839)]
}

static func make_prop(kind: String, at: Vector2, height: float, radius: float,tint := Color.WHITE) -> Dictionary:
 var result := {"p":at,"kind":kind,"height":height,"radius":radius,"tint":tint,"phase":float(posmod(hash(at),100))*.1,"dressed":true}
 if kind=="moonlight_entrance":
  result.anchor_uv = Vector2(.5,.95)
  # Tall trees surround a shallow threshold, not a deep building foundation.
  result.ground_radius = 3.5
  result.max_height = 650.0
  result.max_width = 1000.0
 if kind in HOUSE_KINDS:
  result.max_height = 180.0
  result.max_width = 230.0
 return result
