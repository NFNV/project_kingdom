extends AnimatedSprite2D

# Drawn cycles advance by travelled distance. No timer-driven stepping into walls.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/motion/"
const DIRECTIONS := ["e","se","s","sw","w","nw","n","ne"]
const DIAGONALS := ["se","sw","nw","ne"]
var actor_id := "cat"
var facing_direction := "se"
var state := "idle"
var phase := 0.0
var idle_clock := 0.0
var gesture_clock := -1.0
var display_height := 108.0
var metadata: Dictionary = {}
var eight_directions := true
var base_scale := 1.0
var distance_accumulated := 0.0
var gesture_count := 0


func configure(id: String, height: float, phase_offset := 0.0) -> void:
	actor_id = id
	display_height = height
	idle_clock = phase_offset
	metadata = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))[id]
	sprite_frames = load(ROOT+id+"_frames.tres")
	centered = false
	offset = Vector2(-256,-488)
	eight_directions = id=="cat"
	set_pose("idle","se",0)


func direction_for(vector: Vector2) -> String:
	if vector.length_squared()<.001:
		return facing_direction
	var angle := vector.angle()
	if eight_directions:
		var current := DIRECTIONS.find(facing_direction)*PI/4.0
		# A small deadband prevents a rapidly flipping facing at sector boundaries.
		if absf(angle_difference(current,angle))<PI/8.0+.07:
			return facing_direction
		return DIRECTIONS[posmod(int(floorf((angle+PI/8.0)/(PI/4.0))),8)]
	if not metadata.has("se"):
		return "se"
	return ("se" if vector.x>=0 else "sw") if vector.y>=0 else ("ne" if vector.x>=0 else "nw")


func tick(delta: float, travelled: float, vector: Vector2, running := false) -> void:
	idle_clock += delta
	if travelled>.025:
		var heading := direction_for(vector)
		var gait := "run" if running and eight_directions else "walk"
		var cycle_length := 164.0 if gait=="run" else (118.0 if actor_id=="cat" else 100.0)
		if state=="idle" or state=="gesture":
			phase = 0.0
		phase = fposmod(phase+travelled/cycle_length,1.0)
		distance_accumulated += travelled
		gesture_clock = -1
		set_pose(gait,heading,int(phase*8)%8)
	else:
		if vector.length_squared()>.01:
			facing_direction = direction_for(vector)
		if gesture_clock>=0 and sprite_frames.has_animation("gesture_se"):
			gesture_clock += delta
			if gesture_clock<1.15:
				set_pose("gesture","se",mini(3,int(gesture_clock/.2875)))
				return
			gesture_clock = -1
		var count := sprite_frames.get_frame_count("idle_"+facing_direction)
		var frame_index := 0
		var idle_phase := fposmod(idle_clock,4.8)
		if count==4:
			frame_index = 1 if idle_phase>3.5 and idle_phase<3.95 else (2 if idle_phase>=3.95 and idle_phase<4.08 else (3 if idle_phase>=4.08 else 0))
		else:
			# Blink frames are deliberately brief, rather than closed eyes for a whole beat.
			var times := [2.2,.5,.5,.5,.09,.10,.41,.5]
			var cursor := fposmod(idle_clock,4.8)
			for i in 8:
				if cursor<times[i]:
					frame_index = i
					break
				cursor -= times[i]
		set_pose("idle",facing_direction,frame_index)


func greet() -> void:
	gesture_clock = 0.0
	gesture_count += 1


func set_pose(next_state: String, direction_name: String, frame_index: int) -> void:
	state = next_state
	facing_direction = direction_name
	var key := next_state+"_"+direction_name
	if not sprite_frames.has_animation(key):
		key = next_state+"_se"
		direction_name = "se"
	animation = key
	speed_scale = 0
	frame = mini(frame_index,sprite_frames.get_frame_count(key)-1)
	base_scale = display_height/float(metadata[direction_name]["height"])
	scale = Vector2.ONE*base_scale
