extends CharacterBody2D

# The kit currently supplies one pose, so this demo deliberately has no walk cycle.
const WALK_SPEED := 88.0
const RUN_SPEED := 150.0
var visual: Node2D


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("town_left", "town_right", "town_up", "town_down")
	velocity = direction * (RUN_SPEED if Input.is_action_pressed("town_run") else WALK_SPEED)
	if direction.x != 0.0:
		visual.scale.x = -1.0 if direction.x < 0.0 else 1.0
	move_and_slide()
