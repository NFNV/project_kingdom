extends Control
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
var hub: Node2D
var selected := "briarwood_patrol"
var cards: Dictionary = {}
var names: Dictionary = {}
var statuses: Dictionary = {}
var title: Label
var giver: Label
var summary: Label
var objectives: Label
var route: Label
var reward: Label
var tally: Label
var track_button: Button

func _ready() -> void:
	size = Vector2(1920,1080)
	UI.shade(self)
	var sheet := UI.panel(self,Vector2(300,145),Vector2(1320,790))
	UI.text(sheet,"THE TRAVELLER'S JOURNAL",Vector2(32,24),1000,13,UI.GOLD)
	UI.text(sheet,"Stories along the road",Vector2(32,51),950,36,UI.INK,true)
	tally = UI.text(sheet,"",Vector2(1000,68),280,17,UI.MUTED)
	var row := 0
	for entry in hub.state.journal_entries():
		var card := UI.button(sheet,"",Vector2(30,133+row*125),Vector2(338,111))
		card.pressed.connect(func(): selected=entry.id; refresh())
		cards[entry.id] = card
		names[entry.id] = UI.text(card,entry.title,Vector2(15,18),305,21,Color("f7e8c5"),true)
		statuses[entry.id] = UI.text(card,"",Vector2(16,72),300,14,Color("d7c392"))
		row += 1
	var page := UI.panel(sheet,Vector2(390,132),Vector2(900,565))
	title = UI.text(page,"",Vector2(25,22),850,30,UI.INK,true)
	giver = UI.text(page,"",Vector2(27,72),845,17,UI.GOLD)
	summary = UI.text(page,"",Vector2(27,112),845,20,UI.MUTED)
	objectives = UI.text(page,"",Vector2(27,200),845,21,UI.INK)
	route = UI.text(page,"",Vector2(27,390),845,17,UI.MUTED)
	reward = UI.text(page,"",Vector2(27,463),845,19,UI.GREEN,true)
	track_button = UI.button(sheet,"Track this quest",Vector2(390,717),Vector2(360,43))
	track_button.pressed.connect(func():
		hub.state.tracked_quest = selected
		hub.queue_autosave()
		hub._update_hud()
		refresh()
	)
	var close := UI.button(sheet,"Return  /  J or Esc",Vector2(930,717),Vector2(360,43))
	close.pressed.connect(func(): hub.toggle_journal())
	hide()

func open() -> void:
	selected = hub.state.tracked_quest
	refresh()
	show()

func refresh() -> void:
	var entries: Array = hub.state.journal_entries()
	var complete := 0
	for entry in entries:
		complete += int(entry.status=="Completed")
		statuses[entry.id].text = entry.status.to_upper()+("  ·  TRACKED" if hub.state.tracked_quest==entry.id else "")
		cards[entry.id].add_theme_stylebox_override("normal",UI.style(true,entry.id==selected))
		if entry.id!=selected:
			continue
		title.text = entry.title
		giver.text = entry.giver+"  ·  "+entry.status
		summary.text = entry.summary
		var lines: PackedStringArray = []
		for objective in entry.objectives:
			lines.append(("✓  " if objective.done else "○  ")+objective.text)
		objectives.text = "\n".join(lines)
		route.text = "Route: "+entry.route
		reward.text = "Reward: "+entry.reward
		track_button.disabled = hub.state.tracked_quest==entry.id
		track_button.text = "Currently tracked" if track_button.disabled else "Track this quest"
	tally.text = "%d / %d stories completed" % [complete,entries.size()]
