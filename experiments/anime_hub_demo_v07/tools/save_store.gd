extends RefCounted
## Whitelisted, versioned JSON. Validate everything before touching live state.
const VERSION := 1
const DEFAULT_PATH := "user://kingdom_journey.json"
const ZONES := ["town","bakery","district","trail","river","wilds"]
const MEMORIES := ["old_elm","meadow","river_view"]
const PLACES := ["north_place_plaza","north_place_park","north_place_civic"]
const ITEMS := ["bread","tea","honey","bandit_badge","travel_sword","warden_charm"]
var last_error := ""
var used_backup := false

static func enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for camp in 4:
		for member in 3:
			ids.append("wild_dog_%d_%d" % [camp,member])
	return ids

static func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floorf(float(value)) and value>=low and value<=high

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high

static func ids_valid(value: Variant, allowed: Array) -> bool:
	if not value is Array or value.size()>allowed.size():
		return false
	var seen := {}
	for id in value:
		if not id is String or id not in allowed or seen.has(id):
			return false
		seen[id] = true
	return true

static func pair_valid(value: Variant, max_x: float, max_y: float) -> bool:
	return value is Array and value.size()==2 and number(value[0],0,max_x) and number(value[1],0,max_y)

func validate(doc: Variant) -> bool:
	last_error = "The save is incomplete or contains invalid game data."
	if not doc is Dictionary or doc.get("format")!="project_kingdom":
		return false
	if not whole(doc.get("version"),VERSION,VERSION):
		last_error = "This save version is not supported. Your current journey was kept."
		return false
	var data: Variant = doc.get("state")
	var player: Variant = doc.get("player")
	if not data is Dictionary or not player is Dictionary:
		return false
	if not whole(data.get("coins"),0,999999) or not whole(data.get("delivery_stage"),0,5) or not number(data.get("clock"),0,3.99999999) or not whole(data.get("forest_recoveries"),0,999999):
		return false
	if not ids_valid(data.get("discoveries"),MEMORIES) or not ids_valid(data.get("district_places"),PLACES) or not ids_valid(data.get("forest_defeated"),enemy_ids()):
		return false
	var items: Variant = data.get("items")
	var equipment: Variant = data.get("equipment")
	var quest: Variant = data.get("quest")
	if not items is Dictionary or not equipment is Dictionary or not quest is Dictionary:
		return false
	if items.size()!=ITEMS.size():
		return false
	for id in ITEMS:
		if not whole(items.get(id),0,999):
			return false
	if equipment.get("weapon")!="travel_sword" or equipment.get("charm") not in ["","warden_charm"]:
		return false
	if not quest.get("accepted") is bool or not quest.get("rewarded") is bool:
		return false
	var charm_count: int = int(items.warden_charm)+(1 if equipment.charm=="warden_charm" else 0)
	if int(items.travel_sword)!=0 or charm_count!=(1 if quest.rewarded else 0):
		return false
	if quest.rewarded and (not quest.accepted or data.forest_defeated.size()<3):
		return false
	var loot: Variant = data.get("loot")
	if not loot is Dictionary or loot.size()>12:
		return false
	for id in loot:
		if id not in data.forest_defeated or not loot[id] is Dictionary or not pair_valid(loot[id].get("position"),4608,2592):
			return false
	# Every defeated bandit yields one badge, either on the ground, in the bag,
	# or among the three already handed in. A damaged save cannot duplicate it.
	if int(items.bandit_badge)+loot.size()+(3 if quest.rewarded else 0)!=data.forest_defeated.size():
		return false
	var sizes := {"town":Vector2(1920,1080),"bakery":Vector2(1920,1080),"district":Vector2(6400,3840),"trail":Vector2(1920,1080),"river":Vector2(1920,1080),"wilds":Vector2(4608,2592)}
	if player.get("zone") not in ZONES:
		return false
	var dimensions: Vector2 = sizes[player.zone]
	if not pair_valid(player.get("position"),dimensions.x,dimensions.y) or not whole(player.get("health"),1,5+(1 if equipment.charm=="warden_charm" else 0)):
		return false
	var facing: Variant = player.get("facing")
	if not facing is Array or facing.size()!=2 or not number(facing[0],-1,1) or not number(facing[1],-1,1) or Vector2(facing[0],facing[1]).length_squared()<.01 or not number(player.get("skill_cooldown"),0,6):
		return false
	last_error = ""
	return true

func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null:
		last_error = "No saved journey was found. Press F5 to save."
		return {}
	if file.get_length()>524288:
		last_error = "The save file is too large. Your current journey was kept."
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text())!=OK:
		last_error = "The save file could not be read. Your current journey was kept."
		return {}
	if not validate(parser.data):
		return {}
	return parser.data

func load_document(path := DEFAULT_PATH) -> Dictionary:
	used_backup = false
	var document := _read(path)
	if not document.is_empty():
		return document
	var original_error := last_error
	# Do not silently downgrade a save from a future version.
	if original_error.contains("version"):
		return {}
	if FileAccess.file_exists(path+".bak"):
		document = _read(path+".bak")
		if not document.is_empty():
			used_backup = true
			return document
	last_error = original_error
	return {}

func write_document(document: Dictionary, path := DEFAULT_PATH) -> bool:
	if not validate(document):
		return false
	var temporary := path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:
		last_error = "Could not write the save. Your previous save was kept."
		return false
	file.store_string(JSON.stringify(document,"  ")+"\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error!=OK or _read(temporary).is_empty():
		last_error = "Could not finish the save. Your previous save was kept."
		return false
	var existing_valid := not _read(path).is_empty() if FileAccess.file_exists(path) else false
	if existing_valid:
		# Copy a known-good prior document before the atomic replacement.
		var backup_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".bak"))
		if backup_error!=OK:
			last_error = "Could not preserve the previous save. Saving was cancelled."
			return false
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))
	if result!=OK:
		last_error = "Could not replace the save. Your previous save was kept."
		return false
	last_error = ""
	return true
