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
var body_origin := Vector2.ZERO
var registered := false


func configure(id: String, height: float, phase_offset := 0.0) -> void:
	actor_id = id
	display_height = height
	idle_clock = phase_offset
	metadata = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))[id]
	sprite_frames = load(ROOT+id+"_frames.tres")
	centered = false
	offset = Vector2(-256,-256) if id=="cat" else Vector2(-256,-488)
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
		set_pose(gait,heading,int(phase*8)%8,delta)
	else:
		if vector.length_squared()>.01:
			facing_direction = direction_for(vector)
		if gesture_clock>=0 and sprite_frames.has_animation("gesture_se"):
			gesture_clock += delta
			if gesture_clock<1.15:
				set_pose("gesture","se",mini(3,int(gesture_clock/.2875)),delta)
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
		set_pose("idle",facing_direction,frame_index,delta)


func greet() -> void:
	gesture_clock = 0.0
	gesture_count += 1


func set_pose(next_state: String, direction_name: String, frame_index: int, transition_delta := 0.0) -> void:
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
	if metadata[direction_name].has("body_registration"):
		var registration: Dictionary = metadata[direction_name]["body_registration"][next_state]
		var pose: Dictionary = registration["poses"][frame]
		scale *= float(pose["scale"])
		var target := Vector2(0,-float(registration["head_ground_height"])*base_scale)
		# Keep a small forward lean in the run, and ease the stance when starting,
		# stopping or turning. Per-frame size correction stays exact: smoothing it
		# would briefly restore the swelling head at each pose change.
		if next_state=="run":
			target.x = cos(DIRECTIONS.find(direction_name)*PI/4.0)*4.0*display_height/108.0
		body_origin = body_origin.lerp(target,1.0-exp(-transition_delta/.075)) if registered and transition_delta>0 else target
		registered = true
		var bob := 0.0 if next_state=="idle" else sin(frame*PI/2.0)*(.65 if next_state=="walk" else 1.2)*display_height/108.0
		# Texture-space offset leaves the actor/preview placement and physics foot
		# origin untouched, including when a caller positions this sprite directly.
		offset = Vector2(-256,-256)+(body_origin+Vector2(0,bob))/scale
