extends AnimatedSprite2D
## Combat adapter for the reusable, foot-registered Moonlight Guard drawings.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight_guard/"
var facing_direction := "se"
var display_height := 90.0
var phase := 0.0
var pose_index := 0
var state := "idle"

func configure(role: String, height: float) -> void:
	display_height = height
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+role+"_catalog.json"))
	sprite_frames = load(ROOT+role+"_frames.tres")
	centered = false
	offset = Vector2(-float(data.canvas[0])*.5,-float(data.foot_line))
	scale = Vector2.ONE*height/float(data.reference_height)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_pose("idle","se",0)

func direction_for(vector: Vector2) -> String:
	if vector.length_squared()<.01: return facing_direction
	return ("se" if vector.x>=0 else "sw") if vector.y>=0 else ("ne" if vector.x>=0 else "nw")

func tick(_delta: float, distance: float, vector: Vector2, _running := false) -> void:
	if distance>.025:
		phase = fposmod(phase+distance/65.0,1.0)
		set_pose("walk",direction_for(vector),[1,2,3,2][int(phase*4)%4])
	else:
		set_pose("idle",direction_for(vector),0)

func set_pose(next_state: String, heading: String, index: int, _delta := 0.0) -> void:
	state = next_state
	facing_direction = heading
	pose_index = index
	animation = next_state+"_"+heading
	pause()
	# Walk animation order is 1,2,3,2; other combat clips are single poses.
	frame = [0,0,1,2][index] if next_state=="walk" else 0
