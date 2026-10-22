extends CharacterBody3D

var camera: Camera3D
var sprite: Sprite3D
var frames: Array[Texture2D] = []
var phase := 0.0
var moving := false
var facing_row := 0
var can_move := true
const WALK_SPEED := 3.0
const RUN_SPEED := 4.7


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("hd_left", "hd_right", "hd_up", "hd_down") if can_move else Vector2.ZERO
	var right := camera.global_basis.x
	right.y = 0.0
	right = right.normalized()
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var direction := (right * input.x + forward * -input.y).normalized()
	var speed := RUN_SPEED if Input.is_action_pressed("hd_run") else WALK_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= 20.0 * delta
	move_and_slide()
	moving = input.length_squared() > 0.01
	if moving:
		phase += delta * (10.0 if speed == RUN_SPEED else 7.0)
		if absf(input.x) > absf(input.y):
			facing_row = 2 if input.x < 0 else 1
		else:
			facing_row = 3 if input.y < 0 else 0
	else:
		phase = 0.0
	if sprite != null and frames.size() == 16:
		sprite.texture = frames[facing_row * 4 + (int(phase) % 4 if moving else 0)]
