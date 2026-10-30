extends Node
## Persistent game data and the adapter between gameplay, GLoot and Questify.
## Scenes read this state; rebuilding a zone never resets it.

signal changed
const ROOT := "res://experiments/anime_hub_demo_v07/"
const QUEST_ID := "briarwood_patrol"
const QUEST_PATH := ROOT+"data/briarwood_patrol.tres"
const SMITH_PATH := ROOT+"data/emberforge_tools.tres"
const CAPTAIN_ID := "wild_dog_3_2"
const SLOTS := ["head","chest","legs","gloves","boots","weapon","charm"]
const SLOT_NAMES := {"head":"Helmet","chest":"Chest","legs":"Pants","gloves":"Gloves","boots":"Boots","weapon":"Weapon","charm":"Charm"}
const STARTER := {"head":"","chest":"traveller_tunic","legs":"field_trousers","gloves":"riding_gloves","boots":"trail_boots","weapon":"travel_sword","charm":""}
const FORGE_STOCK := ["leather_cap","reinforced_vest","hunter_boots","swift_charm"]
static var shared_prototypes: JSON
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"data/items.json"))
var bag: Inventory
var weapon: ItemSlot
var charm: ItemSlot
var equipment: Dictionary = {}
var manager: Node
var quest: QuestResource
var smith_quest: QuestResource
var smith_accepted := false
var smith_rewarded := false
var tools_recovered := false
var tracked_quest := "briarwood_patrol"
var coins := 12
var delivery_stage := 0
var discoveries: Dictionary = {}
var district_places: Dictionary = {}
var forest_defeated: Dictionary = {}
# Separate current patrol casualties from one-time quest/reward history.
var forest_patrol_defeated: Dictionary = {}
var forest_recoveries := 0
var pending_loot: Dictionary = {}
var accepted := false
var rewarded := false
var clock := 1.0
var health := 5
var maximum_health: int:
	get: return int(stats().hearts)

func _ready() -> void:
	# GLoot caches by JSON resource identity. Reuse one resource across fresh
	# journeys rather than retaining a new cached prototree on every R/reload.
	if shared_prototypes==null:
		shared_prototypes = JSON.new()
		shared_prototypes.data = definitions
	var prototypes := shared_prototypes
	bag = Inventory.new()
	bag.name = "Satchel"
	bag.protoset = prototypes
	add_child(bag)
	for key in SLOTS:
		var slot := ItemSlot.new()
		slot.name = SLOT_NAMES[key]
		slot.protoset = prototypes
		add_child(slot)
		equipment[key] = slot
		if STARTER[key]!="":
			slot.equip(InventoryItem.new(prototypes,STARTER[key]))
	weapon = equipment.weapon
	charm = equipment.charm
	manager = get_tree().root.get_node("Questify")
	manager.condition_query_requested.connect(_query)

func count(id: String) -> int:
	var total := 0
	for item in bag.get_items_with_prototype_id(id):
		total += item.get_stack_size()
	return total

func item_counts() -> Dictionary:
	var counts := {}
	for id in definitions:
		counts[id] = count(id)
	return counts

func equipped_id(slot: String) -> String:
	if not equipment.has(slot) or equipment[slot].get_item()==null:
		return ""
	return equipment[slot].get_item().get_prototype().get_id()

func equipped_ids() -> Dictionary:
	var ids := {}
	for slot in SLOTS:
		ids[slot] = equipped_id(slot)
	return ids

func owned(id: String) -> int:
	var total := count(id)
	for slot in SLOTS:
		total += int(equipped_id(slot)==id)
	return total

func stats(replacements: Dictionary = {}) -> Dictionary:
	var result := {"hearts":5,"attack":0,"recharge":6.0,"speed":1.0,"wind":0}
	for slot in SLOTS:
		var id: String = replacements.get(slot,equipped_id(slot))
		if not definitions.has(id):
			continue
		var item: Dictionary = definitions[id]
		result.hearts += int(item.get("hearts",0))
		result.attack += int(item.get("attack",0))
		result.recharge -= float(item.get("haste",0))
		result.speed += float(item.get("speed",0))
	result.wind = 2+int(result.attack) if int(result.attack)>0 else 0
	return result

func equip_item(id: String, destination := "") -> bool:
	if not definitions.has(id) or not definitions[id].has("slot"):
		return false
	var key: String = definitions[id].slot
	if destination!="" and destination!=key:
		return false
	var item := bag.get_item_with_prototype_id(id)
	if item==null:
		return false
	var target: ItemSlot = equipment[key]
	var old := target.get_item()
	if old!=null and not bag.add_item(old):
		return false
	if not target.equip(item):
		if old!=null:
			target.equip(old)
		return false
	health = mini(health,maximum_health)
	changed.emit()
	return true

func unequip_item(slot: String) -> bool:
	if not equipment.has(slot) or equipment[slot].get_item()==null:
		return false
	if not bag.add_item(equipment[slot].get_item()):
		return false
	health = mini(health,maximum_health)
	changed.emit()
	return true

func buy_equipment(id: String) -> bool:
	if id not in FORGE_STOCK or owned(id)>0 or coins<int(definitions[id].price):
		return false
	if not add_item(id):
		return false
	coins -= int(definitions[id].price)
	changed.emit()
	return true

func equipment_summary(id: String) -> String:
	var item: Dictionary = definitions[id]
	var parts: PackedStringArray = []
	if item.has("hearts"):
		parts.append("+%d maximum heart%s" % [int(item.hearts),"s" if int(item.hearts)!=1 else ""])
	if item.has("speed"):
		parts.append("+%d%% walk and run speed" % roundi(float(item.speed)*100))
	if item.has("haste"):
		parts.append("Wind Slash recharge: %.1f seconds" % (6-float(item.haste)))
	if item.has("attack"):
		parts.append("%d sword damage" % int(item.attack))
	parts.append(SLOT_NAMES[item.slot])
	return "  ·  ".join(parts)

func add_item(id: String, amount := 1) -> bool:
	if not definitions.has(id) or amount<=0 or count(id)+amount>999:
		return false
	if definitions[id].has("slot") and owned(id)+amount>1:
		return false
	# Bound stack sizes through GLoot; the bag itself has no capacity limit.
	var remaining := amount
	for item in bag.get_items_with_prototype_id(id):
		var portion := mini(remaining,item.get_max_stack_size()-item.get_stack_size())
		if portion>0:
			item.set_stack_size(item.get_stack_size()+portion)
			remaining -= portion
	while remaining>0:
		var item := bag.create_and_add_item(id)
		if item==null:
			return false
		var portion := mini(remaining,item.get_max_stack_size())
		item.set_stack_size(portion)
		remaining -= portion
	update_quest()
	changed.emit()
	return true

func remove_item(id: String, amount := 1) -> bool:
	if amount<=0 or count(id)<amount:
		return false
	var remaining := amount
	for item in bag.get_items_with_prototype_id(id).duplicate():
		var portion := mini(remaining,item.get_stack_size())
		if portion==item.get_stack_size():
			bag.remove_item(item)
		else:
			item.set_stack_size(item.get_stack_size()-portion)
		remaining -= portion
		if remaining==0:
			break
	changed.emit()
	return true

func equip_charm() -> bool:
	return equip_item("warden_charm")

func unequip_charm() -> bool:
	return unequip_item("charm")

func accept_quest() -> bool:
	if accepted:
		return false
	accepted = true
	tracked_quest = QUEST_ID
	_rebuild_quest()
	changed.emit()
	return true

func _dispose_quest() -> void:
	_release_graph(quest)
	_release_graph(smith_quest)
	quest = null
	smith_quest = null

func _release_graph(graph: QuestResource) -> void:
	if graph==null:
		return
	var keep: Array[QuestResource] = []
	for other in manager.get_quests():
		if other!=graph:
			keep.append(other)
	manager.set_quests(keep)
	# QuestNode holds its owning graph. Break that resource cycle on teardown.
	for node in graph.nodes:
		node.set_graph(null)

func _rebuild_quest() -> void:
	_dispose_quest()
	if accepted:
		quest = load(QUEST_PATH).instantiate()
		manager.start_quest(quest)
		update_quest()
	if smith_accepted:
		smith_quest = load(SMITH_PATH).instantiate()
		manager.start_quest(smith_quest)
		update_quest()

func _query(type: String, key: String, value: Variant, condition: QuestCondition) -> void:
	if type=="forge" and smith_quest!=null and condition in smith_quest.nodes:
		match key:
			"captain": condition.set_completed(forest_defeated.has(CAPTAIN_ID))
			"tools": condition.set_completed(tools_recovered)
			"rewarded": condition.set_completed(smith_rewarded)
		return
	if type!="kingdom" or quest==null or condition not in quest.nodes:
		return
	match key:
		"defeats": condition.set_completed(forest_defeated.size()>=int(value))
		"badges": condition.set_completed(rewarded or count("bandit_badge")>=int(value))
		"rewarded": condition.set_completed(rewarded==value)

func update_quest() -> void:
	if quest!=null:
		quest.update()
	if smith_quest!=null:
		smith_quest.update()

func accept_smith_quest() -> bool:
	if smith_accepted:
		return false
	smith_accepted = true
	tracked_quest = "emberforge_tools"
	_rebuild_quest()
	changed.emit()
	return true

func can_claim_smith() -> bool:
	return smith_accepted and not smith_rewarded and tools_recovered and count("smith_tools")==1

func claim_smith_reward() -> bool:
	if not can_claim_smith():
		return false
	smith_rewarded = true
	remove_item("smith_tools")
	coins += 12
	if owned("tempered_sword")==0:
		add_item("tempered_sword")
	update_quest()
	changed.emit()
	return true

func smith_text() -> String:
	if not smith_accepted:
		return "Meet Tomas inside Emberforge in Northgate's Market Lane."
	if smith_rewarded:
		return "Complete. Your Embersteel sword is ready for the road."
	if tools_recovered:
		return "Return the stolen tools to Tomas at Emberforge."
	if forest_defeated.has(CAPTAIN_ID):
		return "Collect Tomas's tools from Rook's fallen pouch."
	return "Defeat Rook, the club captain in Briarwood's southeast clearing."

func journal_entries() -> Array[Dictionary]:
	return [
		{"id":"morning_rounds","title":"Morning rounds","status":"Completed" if delivery_stage>=5 else ("Active" if delivery_stage>0 else "Available"),"giver":"Pippa · Garden Square","summary":"Help the square wake up: warm bread, a fruit basket and a letter connect the neighbours.","route":"Garden Square: bakery cart → Elder Mallow → Moss → Pip → red postbox.","reward":"The neighbours' thanks, and a town full of familiar faces.","objectives":[{"text":"Collect Pippa's warm loaf","done":delivery_stage>=1},{"text":"Deliver the loaf to Elder Mallow","done":delivery_stage>=2},{"text":"Collect Moss's fruit basket","done":delivery_stage>=3},{"text":"Bring the basket to Pip","done":delivery_stage>=4},{"text":"Post Pip's letter","done":delivery_stage>=5}]},
		{"id":QUEST_ID,"title":"Badges from Briarwood","status":"Completed" if rewarded else ("Active" if accepted else "Available"),"giver":"Bram · Garden Square fountain","summary":"Bram needs help keeping the woodland paths safe. Recover three bandit badges and bring them home.","route":"Garden Square southeast gate → Mosswood → Riverbend bridge → Briarwood. Return to Bram.","reward":"10 coins + Warden's charm (+1 maximum heart).","objectives":[{"text":"Defeat three bandits (%d / 3)" % mini(forest_defeated.size(),3),"done":forest_defeated.size()>=3},{"text":"Collect three fallen badges","done":rewarded or count("bandit_badge")>=3},{"text":"Return the badges to Bram","done":rewarded}]},
		{"id":"emberforge_tools","title":"The stolen tools","status":"Completed" if smith_rewarded else ("Active" if smith_accepted else "Available"),"giver":"Tomas · Emberforge, Northgate Market Lane","summary":"Rook stole Tomas's favourite hammer and tongs. Recover them and the smith will forge a better sword for you.","route":"Northgate Emberforge → Briarwood's southeast clearing → collect Rook's pouch → return to Tomas.","reward":"12 coins + Embersteel sword (2 sword damage, 4 Wind Slash damage).","objectives":[{"text":"Defeat Rook, the club captain","done":forest_defeated.has(CAPTAIN_ID)},{"text":"Collect the stolen hammer and tongs","done":tools_recovered},{"text":"Return the tools to Tomas","done":smith_rewarded}]}
	]

func can_claim() -> bool:
	return accepted and not rewarded and forest_defeated.size()>=3 and count("bandit_badge")>=3

func claim_reward() -> bool:
	if not can_claim():
		return false
	# Commit the unique reward flag before emitting inventory changes.
	rewarded = true
	remove_item("bandit_badge",3)
	coins += 10
	add_item("warden_charm")
	update_quest()
	changed.emit()
	return true

func quest_text() -> String:
	if not accepted:
		return "Speak to Bram in Garden Square about the Briarwood bandits."
	if rewarded:
		return "Complete. Thank you for helping keep the forest paths safe."
	if forest_defeated.size()<3:
		return "Briarwood: defeat bandits %d / 3, collect their badges." % mini(forest_defeated.size(),3)
	if count("bandit_badge")<3:
		return "Collect the fallen badges in Briarwood: %d / 3." % count("bandit_badge")
	return "Return three bandit badges to Bram in Garden Square."

func record_defeat(id: String, at: Vector2) -> bool:
	if forest_defeated.has(id):
		return false
	forest_defeated[id] = true
	if forest_defeated.size()==12:
		# Keep this first clear empty until the next actual visit. Loading a
		# completed encounter must not immediately resurrect the last enemy.
		forest_patrol_defeated = forest_defeated.duplicate()
	coins += 2
	pending_loot[id] = {"position":[at.x,at.y]}
	update_quest()
	changed.emit()
	return true

func begin_forest_visit() -> void:
	if forest_defeated.size()==12 and forest_patrol_defeated.size()==12:
		forest_patrol_defeated.clear()
		changed.emit()

func record_patrol_defeat(id: String) -> bool:
	if forest_defeated.size()!=12 or not forest_defeated.has(id) or forest_patrol_defeated.has(id):
		return false
	forest_patrol_defeated[id] = true
	changed.emit()
	return true

func collect_loot(id: String) -> bool:
	if not pending_loot.has(id) or not add_item("bandit_badge"):
		return false
	if id==CAPTAIN_ID and not tools_recovered:
		tools_recovered = true
		add_item("smith_tools")
	pending_loot.erase(id)
	update_quest()
	changed.emit()
	return true

func snapshot() -> Dictionary:
	return {"coins":coins,"delivery_stage":delivery_stage,"clock":clock,
		"discoveries":discoveries.keys(),"district_places":district_places.keys(),
		"forest_defeated":forest_defeated.keys(),"forest_recoveries":forest_recoveries,
		"forest_patrol_defeated":forest_patrol_defeated.keys(),
		"loot":pending_loot.duplicate(true),"items":item_counts(),
		"equipment":equipped_ids(),"tracked_quest":tracked_quest,
		"smith":{"accepted":smith_accepted,"rewarded":smith_rewarded,"tools_recovered":tools_recovered},
		"quest":{"accepted":accepted,"rewarded":rewarded}}

func restore(data: Dictionary, player_health: int) -> void:
	# SaveStore validates the complete document before this mutates live data.
	_dispose_quest()
	bag.clear()
	for slot in equipment.values():
		slot.clear()
	coins = int(data.coins)
	delivery_stage = int(data.delivery_stage)
	clock = float(data.clock)
	forest_recoveries = int(data.forest_recoveries)
	discoveries.clear()
	district_places.clear()
	forest_defeated.clear()
	forest_patrol_defeated.clear()
	for pair in [[discoveries,data.discoveries],[district_places,data.district_places],[forest_defeated,data.forest_defeated]]:
		for id in pair[1]:
			pair[0][id] = true
	# Older saves have only the permanent defeat history. A fully cleared old
	# forest starts a fresh patrol, preserving every existing quest and item.
	for id in data.get("forest_patrol_defeated",[]):
		forest_patrol_defeated[id] = true
	pending_loot = data.loot.duplicate(true)
	accepted = bool(data.quest.accepted)
	rewarded = bool(data.quest.rewarded)
	smith_accepted = bool(data.smith.accepted)
	smith_rewarded = bool(data.smith.rewarded)
	tools_recovered = bool(data.smith.tools_recovered)
	tracked_quest = data.tracked_quest
	for id in data.items:
		if int(data.items[id])>0:
			add_item(id,int(data.items[id]))
	for key in SLOTS:
		if data.equipment[key]!="":
			equipment[key].equip(InventoryItem.new(bag.protoset,data.equipment[key]))
	health = player_health
	_rebuild_quest()
	changed.emit()

func _exit_tree() -> void:
	if is_instance_valid(manager):
		_dispose_quest()
	if bag!=null:
		bag.clear()
	for slot in equipment.values():
		slot.clear()
