extends Node
const ROOT := "res://experiments/anime_hub_demo_v07/"
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
var game: Node2D
var save_path := "user://kingdom_journey.json"
var menu: Control
var confirmation: Control
var continue_button: Button
var summary: Label

func _ready() -> void:
	spawn_game()
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	menu = Control.new()
	menu.size = Vector2(1920,1080)
	layer.add_child(menu)
	UI.shade(menu)
	var title := UI.text(menu,"Project Kingdom",Vector2(300,132),1320,70,Color("f8e7bc"),true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := UI.text(menu,"Stories of Mosswood",Vector2(500,226),920,26,Color("e0c995"),true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sheet := UI.panel(menu,Vector2(660,310),Vector2(600,444))
	UI.text(sheet,"A ROAD WAITING TO BE WALKED",Vector2(35,25),530,13,UI.GOLD)
	continue_button = UI.button(sheet,"Continue your journey",Vector2(35,75),Vector2(530,62))
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.pressed.connect(continue_journey)
	summary = UI.text(sheet,"",Vector2(38,156),524,17,UI.MUTED)
	var start := UI.button(sheet,"New journey",Vector2(35,260),Vector2(530,58))
	start.focus_mode = Control.FOCUS_ALL
	start.pressed.connect(func(): begin_new())
	UI.text(sheet,"Progress is saved at safe travel and quest milestones.\nF5 saves now; F9 continues the latest save.",Vector2(38,354),524,16,UI.MUTED)
	var help := UI.text(menu,"WASD walk   ·   E interact   ·   I equipment   ·   J journal   ·   F11 full screen",Vector2(400,926),1120,18,Color("efe2bd"))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation = Control.new()
	confirmation.size = Vector2(1920,1080)
	layer.add_child(confirmation)
	UI.shade(confirmation)
	var prompt := UI.panel(confirmation,Vector2(630,365),Vector2(660,310))
	UI.text(prompt,"Begin a new journey?",Vector2(32,28),596,32,UI.INK,true)
	UI.text(prompt,"A new autosave will begin. Your last manual save is kept.",Vector2(34,100),590,21,UI.MUTED)
	var yes := UI.button(prompt,"Begin",Vector2(34,220),Vector2(280,48))
	yes.pressed.connect(func(): begin_new(true))
	var back := UI.button(prompt,"Back",Vector2(346,220),Vector2(280,48))
	back.pressed.connect(func(): confirmation.hide())
	confirmation.hide()
	show_title()
	if "--continue" in OS.get_cmdline_user_args():
		continue_journey.call_deferred()

func spawn_game() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	add_child(game)
	game.save_path = save_path

func show_title() -> void:
	game.backpack_open = false
	game.journal_open = false
	game.shopping = false
	game.ui.satchel.hide()
	game.ui.journal_view.hide()
	game.ui.forge_view.hide()
	game.ui.merchant.hide()
	game.title_active = true
	game.autosave_enabled = false
	game.autosave_queued = false
	game.set_paused(true)
	game.ui.hide()
	game.player.stop_motion()
	menu.show()
	var document: Dictionary = game.saves.latest_document(save_path)
	continue_button.disabled = document.is_empty()
	if document.is_empty():
		summary.text = "A fresh start in Garden Square. Meet the neighbours and find your own path." if not game.saves.has_journey(save_path) else game.saves.last_error
	else:
		summary.text = "%s\n%d coins · %d bandits defeated\nYour equipment and quest progress are waiting." % [game.Map.NAMES[document.player.zone],int(document.state.coins),document.state.forest_defeated.size()]
		continue_button.grab_focus()

func begin_new(confirmed := false) -> void:
	if game.saves.has_journey(save_path) and not confirmed:
		confirmation.show()
		return
	remove_child(game)
	game.free()
	spawn_game()
	finish_menu()
	game.queue_autosave()

func continue_journey() -> bool:
	if not game.load_game():
		summary.text = game.saves.last_error
		return false
	finish_menu()
	return true

func finish_menu() -> void:
	menu.hide()
	confirmation.hide()
	game.title_active = false
	game.autosave_enabled = true
	game.ui.show()
	game.set_paused(false)

func return_to_title() -> bool:
	if game.transitioning or not game.player.active:
		return false
	# A menu action is a stable event boundary. Persist facts, not the current
	# swing/projectile, before suspending this world behind the title screen.
	if not game.saves.write_document(game.make_save_document(),save_path+".auto"):
		game.ui.show_notice(game.saves.last_error)
		return false
	show_title()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(menu) or not menu.visible:
		return
	if event.is_action_pressed("hub_load") and not continue_button.disabled:
		continue_journey()
	elif event.is_action_pressed("hub_pause") and confirmation.visible:
		confirmation.hide()
	elif event.is_action_pressed("hub_fullscreen"):
		get_window().mode = Window.MODE_WINDOWED if get_window().mode==Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
