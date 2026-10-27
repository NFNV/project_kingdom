extends Node

const ROOT := "res://experiments/anime_hub_demo_v07/"
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	run.call_deferred()

func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		push_error(text)

func run() -> void:
	var prototypes := JSON.new()
	prototypes.data = {"bread":{"name":"Bread","max_stack_size":99},"charm":{"name":"Charm"}}
	var bag := Inventory.new()
	bag.protoset = prototypes
	get_tree().root.add_child(bag)
	var loaf := bag.create_and_add_item("bread")
	check(loaf!=null and loaf.set_stack_size(3),"GLoot creates a real stack")
	check(loaf.get_stack_size()==3 and not loaf.set_stack_size(100),"GLoot enforces stack limits")
	var second := Inventory.new()
	get_tree().root.add_child(second)
	check(second.deserialize(bag.serialize()),"GLoot serialization round trip succeeds")
	check(second.get_items()[0].get_stack_size()==3,"GLoot preserves stack quantity")
	var slot := ItemSlot.new()
	slot.protoset = prototypes
	get_tree().root.add_child(slot)
	var charm := bag.create_and_add_item("charm")
	check(slot.equip(charm) and not bag.has_item(charm),"GLoot equips by transferring ownership")
	check(bag.add_item(slot.get_item()) and slot.get_item()==null,"GLoot unequips back into the bag")
	var quest: QuestResource = load(ROOT+"data/briarwood_patrol.tres").instantiate()
	var manager := get_tree().root.get_node("Questify")
	var query := func(_type: String, _key: String, _value: Variant, condition: QuestCondition): condition.set_completed(true)
	manager.condition_query_requested.connect(query)
	manager.start_quest(quest)
	check(quest.started and not quest.completed,"Questify starts an independent resource instance")
	manager.update_quests()
	check(quest.completed,"Questify follows objective conditions to the end node")
	var restored: QuestResource = load(ROOT+"data/briarwood_patrol.tres").instantiate()
	restored.deserialize(quest.serialize())
	check(restored.completed and restored.started,"Questify state round trip succeeds")
	check(not ProjectSettings.get_setting("questify/general/update_polling"),"Questify uses event updates, with polling disabled")
	manager.condition_query_requested.disconnect(query)
	manager.clear()
	for instance in [quest,restored]:
		for node in instance.nodes:
			node.set_graph(null)
	bag.clear()
	second.clear()
	bag.free()
	second.free()
	slot.free()
	var report := {"engine":Engine.get_version_info().string,"checks":checks,"passed":checks-failures.size(),"failures":failures,"gloot":"3.0.2","questify":"1.6.0"}
	FileAccess.open(ROOT+"addon_test_results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Addon compatibility: ",checks-failures.size(),"/",checks)
	get_tree().quit(0 if failures.is_empty() else 1)
