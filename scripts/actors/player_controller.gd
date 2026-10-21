extends Node

@onready var actor: KingdomActor = get_parent() as KingdomActor


func _physics_process(_delta: float) -> void:
	if actor.health.is_dead():
		actor.move_intent = Vector2.ZERO
		return
	actor.move_intent = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var aim := actor.facing
	if not actor.move_intent.is_zero_approx() and not actor.melee.attacking:
		aim = actor.move_intent.normalized()
	if Input.is_action_pressed("attack"):
		actor.try_attack(aim)
