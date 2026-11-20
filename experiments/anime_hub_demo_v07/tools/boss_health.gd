extends Control
## Screen-space boss banner keeps the world clock and enemy artwork clear.
const EnemyHealth := preload("res://experiments/anime_hub_demo_v07/tools/enemy_health.gd")
var hub: Node2D
var target: Node2D

func _ready() -> void:
	size = Vector2(760,104)
	position = Vector2((1920-size.x)*.5,18)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func _process(_delta: float) -> void:
	target = null
	if not is_instance_valid(hub.player):
		hide()
		return
	for dog in hub.dogs:
		if not dog.active or not dog.enemy: continue
		var boss: bool = dog.has_method("is_boss") and dog.is_boss()
		if boss or dog.get("captain")==true:
			if boss or dog.alerted or dog.position.distance_to(hub.player.position)<500:
				target = dog
				break
	visible = is_instance_valid(target) and not hub.paused and not hub.transitioning and not hub.talk_panel.visible
	if visible: queue_redraw()

func _draw() -> void:
	if is_instance_valid(target) and target.active:
		EnemyHealth.boss(self,Rect2(Vector2.ZERO,size),target.enemy_name,target.level,target.health,target.maximum_health)
