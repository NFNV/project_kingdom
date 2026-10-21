extends Node2D

const PLAYER_SCENE := preload("res://scenes/actors/player.tscn")
const ENEMY_SCENE := preload("res://scenes/actors/enemy.tscn")
const ACTOR_SCENE := preload("res://scenes/actors/actor.tscn")

var player: KingdomActor
var finished: bool = false
@onready var world: KingdomMap = $World
@onready var hud: KingdomHUD = $HUD


func _ready() -> void:
	if OS.is_debug_build():
		get_window().title = "Project Kingdom — Cat Warrior Debug"
	player = PLAYER_SCENE.instantiate() as KingdomActor
	player.position = Vector2(510, 1400)
	player.facing = Vector2(1, -0.5).normalized()
	world.entities.add_child(player)
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.reset_smoothing()
	var guard := ACTOR_SCENE.instantiate() as KingdomActor
	guard.position = Vector2(610, 1365)
	guard.faction = player.faction
	guard.display_name = "Cat outpost guard"
	guard.maximum_health = 8
	guard.is_guard = true
	world.entities.add_child(guard)
	_spawn_enemy(Vector2(880, 1190), Vector2(80, -25), false)
	_spawn_enemy(Vector2(1210, 930), Vector2(-60, 20), false)
	_spawn_enemy(Vector2(1550, 790), Vector2(65, -25), false)
	_spawn_enemy(Vector2(1800, 595), Vector2(-35, 40), true)
	_spawn_enemy(Vector2(2055, 650), Vector2(0, 55), true)
	_spawn_enemy(Vector2(1925, 820), Vector2(-55, -15), true)
	world.castle.player = player
	world.castle.captured.connect(_on_keep_captured)
	hud.pause_requested.connect(_toggle_pause)
	hud.restart_requested.connect(_restart)
	hud.refresh(player, world.castle)


func _spawn_enemy(point: Vector2, patrol_offset: Vector2, defender: bool) -> KingdomActor:
	var enemy := ENEMY_SCENE.instantiate() as KingdomActor
	enemy.position = point
	enemy.display_name = "Dog sentry" if defender else "Dog patrol"
	world.entities.add_child(enemy)
	var controller: KingdomEnemyController = enemy.get_node("Controller")
	controller.home = point
	controller.patrol_end = point + patrol_offset
	controller.target = player
	controller.map = world
	if defender:
		world.castle.defenders.append(enemy)
		controller.chase_distance = 255.0
		controller.leash_distance = 340.0
	return enemy


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		hud.refresh(player, world.castle)


func _on_player_died(_actor: KingdomActor) -> void:
	if finished:
		return
	finished = true
	await get_tree().create_timer(0.65).timeout
	get_tree().paused = true
	hud.show_result(false)


func _on_keep_captured() -> void:
	if finished:
		return
	finished = true
	await get_tree().create_timer(0.65).timeout
	hud.refresh(player, world.castle)
	get_tree().paused = true
	hud.show_result(true)


func _toggle_pause() -> void:
	if finished:
		return
	get_tree().paused = not get_tree().paused
	hud.show_pause(get_tree().paused)


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
