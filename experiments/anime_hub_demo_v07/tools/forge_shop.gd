extends Control
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
const Art := preload("res://experiments/anime_hub_demo_v07/tools/equipment_art.gd")
var hub: Node2D
var balance: Label
var feedback: Label
var quest_text: Label
var quest_button: Button
var buy_buttons: Dictionary = {}

func _ready() -> void:
	size = Vector2(1920,1080)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	UI.shade(self)
	var sheet := UI.panel(self,Vector2(220,150),Vector2(1480,780))
	UI.text(sheet,"EMBERFORGE WORKSHOP  /  TOMAS",Vector2(30,22),1000,13,UI.GOLD)
	UI.text(sheet,"Good steel. A steady hand.",Vector2(30,48),1100,36,UI.INK,true)
	balance = UI.text(sheet,"",Vector2(1190,63),250,20,UI.MUTED)
	var row := 0
	for id in hub.state.FORGE_STOCK:
		var item: Dictionary = hub.state.definitions[id]
		var card := UI.panel(sheet,Vector2(30,124+row*123),Vector2(850,111))
		UI.image(card,Art.icon(id,hub.state.definitions),Vector2(13,13),Vector2(83,83))
		UI.text(card,item.name,Vector2(115,15),540,24,UI.INK,true)
		UI.text(card,hub.state.equipment_summary(id),Vector2(116,57),492,17,UI.MUTED)
		var button := UI.button(card,"",Vector2(668,33),Vector2(160,46))
		button.pressed.connect(func(): hub.buy_forge(id))
		buy_buttons[id] = button
		row += 1
	var quest := UI.panel(sheet,Vector2(910,124),Vector2(540,550))
	UI.text(quest,"A REQUEST FROM TOMAS",Vector2(24,20),490,13,UI.GOLD)
	UI.text(quest,"The stolen tools",Vector2(24,48),490,30,UI.INK,true)
	UI.image(quest,Art.icon("smith_tools",hub.state.definitions),Vector2(182,100),Vector2(170,158))
	quest_text = UI.text(quest,"",Vector2(24,277),490,20,UI.INK)
	UI.text(quest,"Rook waits in Briarwood's southeast clearing.\nReward: Embersteel sword + 12 coins.",Vector2(24,377),490,18,UI.MUTED)
	quest_button = UI.button(quest,"Accept quest",Vector2(24,472),Vector2(492,48))
	quest_button.pressed.connect(func(): hub.smith_quest_action())
	feedback = UI.text(sheet,"",Vector2(32,635),830,18,UI.GOLD)
	var close := UI.button(sheet,"Back to the workshop  /  E or Esc",Vector2(510,713),Vector2(460,42))
	close.pressed.connect(func(): hub.close_shop())
	hide()

func refresh(message := "") -> void:
	balance.text = "Your purse: %d coins" % hub.coins
	if message!="":
		feedback.text = message
	quest_text.text = hub.state.smith_text() if hub.state.smith_accepted else "Rook made off with my hammer and tongs. Bring them back, and I'll forge you a better blade."
	quest_button.text = "Completed · Thank you!" if hub.state.smith_rewarded else ("Return the stolen tools" if hub.state.can_claim_smith() else ("Accept quest" if not hub.state.smith_accepted else "Quest in progress"))
	quest_button.disabled = hub.state.smith_accepted and not hub.state.can_claim_smith()
	for id in buy_buttons:
		var owned: bool = hub.state.owned(id)>0
		buy_buttons[id].text = "Owned" if owned else "Buy · %d coins" % int(hub.state.definitions[id].price)
		buy_buttons[id].disabled = owned or hub.coins<int(hub.state.definitions[id].price)
