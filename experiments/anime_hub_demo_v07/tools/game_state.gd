extends Node
## Persistent game data and the adapter between gameplay, GLoot and Questify.
## Scenes read this state; rebuilding a zone never resets it.

signal changed
const ROOT := "res://experiments/anime_hub_demo_v07/"
const QUEST_ID := "briarwood_patrol"
const QUEST_PATH := ROOT+"data/briarwood_patrol.tres"
static var shared_prototypes: JSON
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"data/items.json"))
var bag: Inventory
var weapon: ItemSlot
var charm: ItemSlot
var manager: Node
var quest: QuestResource
var coins := 12
var delivery_stage := 0
var discoveries: Dictionary = {}
var district_places: Dictionary = {}
var forest_defeated: Dictionary = {}
var forest_recoveries := 0
var pending_loot: Dictionary = {}
var accepted := false
var rewarded := false
var clock := 1.0
var health := 5
var maximum_health: int:
	get: return 5+(1 if charm!=null and charm.get_item()!=null else 0)

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
	weapon = ItemSlot.new()
	weapon.name = "Weapon"
	weapon.protoset = prototypes
	add_child(weapon)
	charm = ItemSlot.new()
	charm.name = "Charm"
	charm.protoset = prototypes
	add_child(charm)
	weapon.equip(InventoryItem.new(prototypes,"travel_sword"))
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

func add_item(id: String, amount := 1) -> bool:
	if not definitions.has(id) or amount<=0 or count(id)+amount>999:
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
	if charm.get_item()!=null:
		return false
	var item := bag.get_item_with_prototype_id("warden_charm")
	if item==null or not charm.equip(item):
		return false
	changed.emit()
	return true

func unequip_charm() -> bool:
	if charm.get_item()==null or not bag.add_item(charm.get_item()):
		return false
	health = mini(health,maximum_health)
	changed.emit()
	return true

func accept_quest() -> bool:
	if accepted:
		return false
	accepted = true
	_rebuild_quest()
	changed.emit()
	return true

func _dispose_quest() -> void:
	if quest==null:
		return
	var keep: Array[QuestResource] = []
	for other in manager.get_quests():
		if other!=quest:
			keep.append(other)
	manager.set_quests(keep)
	# QuestNode holds its owning graph. Break that resource cycle on teardown.
	for node in quest.nodes:
		node.set_graph(null)
	quest = null

func _rebuild_quest() -> void:
	_dispose_quest()
	if accepted:
		quest = load(QUEST_PATH).instantiate()
		manager.start_quest(quest)
		update_quest()

func _query(type: String, key: String, value: Variant, condition: QuestCondition) -> void:
	if type!="kingdom" or quest==null or condition not in quest.nodes:
		return
	match key:
		"defeats": condition.set_completed(forest_defeated.size()>=int(value))
		"badges": condition.set_completed(rewarded or count("bandit_badge")>=int(value))
		"rewarded": condition.set_completed(rewarded==value)

func update_quest() -> void:
	if quest!=null:
		quest.update()

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
	coins += 2
	pending_loot[id] = {"position":[at.x,at.y]}
	update_quest()
	changed.emit()
	return true

func collect_loot(id: String) -> bool:
	if not pending_loot.has(id) or not add_item("bandit_badge"):
		return false
	pending_loot.erase(id)
	update_quest()
	changed.emit()
	return true

func snapshot() -> Dictionary:
	return {"coins":coins,"delivery_stage":delivery_stage,"clock":clock,
		"discoveries":discoveries.keys(),"district_places":district_places.keys(),
		"forest_defeated":forest_defeated.keys(),"forest_recoveries":forest_recoveries,
		"loot":pending_loot.duplicate(true),"items":item_counts(),
		"equipment":{"weapon":"travel_sword","charm":"warden_charm" if charm.get_item()!=null else ""},
		"quest":{"accepted":accepted,"rewarded":rewarded}}

func restore(data: Dictionary, player_health: int) -> void:
	# SaveStore validates the complete document before this mutates live data.
	_dispose_quest()
	bag.clear()
	charm.clear()
	coins = int(data.coins)
	delivery_stage = int(data.delivery_stage)
	clock = float(data.clock)
	forest_recoveries = int(data.forest_recoveries)
	discoveries.clear()
	district_places.clear()
	forest_defeated.clear()
	for pair in [[discoveries,data.discoveries],[district_places,data.district_places],[forest_defeated,data.forest_defeated]]:
		for id in pair[1]:
			pair[0][id] = true
	pending_loot = data.loot.duplicate(true)
	accepted = bool(data.quest.accepted)
	rewarded = bool(data.quest.rewarded)
	for id in data.items:
		if int(data.items[id])>0:
			add_item(id,int(data.items[id]))
	if data.equipment.charm=="warden_charm":
		charm.equip(InventoryItem.new(bag.protoset,"warden_charm"))
	health = player_health
	_rebuild_quest()
	changed.emit()

func _exit_tree() -> void:
	if is_instance_valid(manager):
		_dispose_quest()
	if bag!=null:
		bag.clear()
	if weapon!=null:
		weapon.clear()
	if charm!=null:
		charm.clear()
