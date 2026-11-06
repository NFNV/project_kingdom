extends Control
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
const PAGES := preload("res://experiments/anime_hub_demo_v07/assets/field_ui/journal_pages.png")
const COVER := preload("res://experiments/anime_hub_demo_v07/assets/field_ui/journal_cover.png")
var hub: Node2D
var board_mode := false
var banner: Label
var heading: Label
var close_button: Button
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
var guidance: Label
var footer: Label

func _ready() -> void:
	size = Vector2(1920,1080)
	UI.shade(self)
	var sheet := UI.image(self,PAGES,Vector2(306,104),Vector2(1308,872))
	banner = UI.text(sheet,"THE TRAVELLER'S JOURNAL",Vector2(112,79),480,15,Color("8a6237"))
	heading = UI.text(sheet,"Stories along the road",Vector2(110,105),500,36,UI.INK,true)
	tally = UI.text(sheet,"",Vector2(112,164),480,17,UI.MUTED)
	var row := 0
	for entry in hub.state.journal_entries():
		var card := UI.button(sheet,"",Vector2(112,206+row*103),Vector2(466,90))
		card.pressed.connect(func(): selected=entry.id; refresh())
		cards[entry.id] = card
		names[entry.id] = UI.text(card,entry.title,Vector2(19,14),424,24,Color("f7e8c5"),true)
		statuses[entry.id] = UI.text(card,"",Vector2(20,57),424,14,Color("d7c392"))
		row += 1
	guidance = UI.text(sheet,"",Vector2(114,635),462,20,UI.INK,true)
	guidance.max_lines_visible = 3
	guidance.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer = UI.text(sheet,"",Vector2(114,708),462,15,UI.MUTED)
	title = UI.text(sheet,"",Vector2(726,101),465,34,UI.INK,true)
	giver = UI.text(sheet,"",Vector2(728,161),470,17,Color("8a6237"))
	summary = UI.text(sheet,"",Vector2(728,220),468,20,UI.MUTED)
	objectives = UI.text(sheet,"",Vector2(728,333),465,20,UI.INK)
	route = UI.text(sheet,"",Vector2(728,530),465,18,UI.MUTED)
	reward = UI.text(sheet,"",Vector2(728,632),465,20,UI.GREEN,true)
	track_button = UI.button(sheet,"Track this quest",Vector2(728,711),Vector2(218,44))
	track_button.pressed.connect(func():
		hub.state.tracked_quest = selected
		hub.queue_autosave()
		hub._update_hud()
		refresh()
	)
	close_button = UI.button(sheet,"Close   ·   J / Esc",Vector2(965,711),Vector2(226,44))
	close_button.pressed.connect(func(): hub.toggle_journal())
	hide()

func open(from_board := false) -> void:
	board_mode = from_board
	banner.text = "GARDEN SQUARE QUEST BOARD" if board_mode else "THE TRAVELLER'S JOURNAL"
	heading.text = "Town notices and requests" if board_mode else "Stories along the road"
	close_button.text = "Close   ·   E / Esc" if board_mode else "Close   ·   J / Esc"
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
