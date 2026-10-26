extends Node2D

signal settings_changed

const ROOT := "res://experiments/anime_hub_demo_v07/assets/audio/"
const BUS_NAMES := {"master":"KingdomMaster","music":"KingdomMusic","ambience":"KingdomAmbience","effects":"KingdomEffects"}
const FX_VOICES := 12
const CONFIG := "user://kingdom_audio.cfg"
var hub: Node2D
var levels := {"master":.85,"music":.65,"ambience":.60,"effects":.80}
var muted := false
var persist_settings := true
var catalog: Dictionary
var streams: Dictionary = {}
var music: Array[AudioStreamPlayer] = []
var gains: Array[float] = [0.0,0.0]
var music_ids: Array[String] = ["",""]
var music_positions: Dictionary = {}
var music_target := -1
var music_id := ""
var music_changes := 0
var beds: Array[AudioStreamPlayer] = []
var props: Array[AudioStreamPlayer2D] = []
var voices: Array[AudioStreamPlayer2D] = []
var voice_serial: Array[int] = []
var listener: AudioListener2D
var step_phase: Dictionary = {}
var last_event: Dictionary = {}
var event_counts: Dictionary = {}
var elapsed := 0.0
var decision_left := 0.0
var battle_hold := 0.0
var serial := 0
var paused := false
var active_zone := ""

func _ready() -> void:
	for key in BUS_NAMES:
		if AudioServer.get_bus_index(BUS_NAMES[key])<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,BUS_NAMES[key])
		AudioServer.set_bus_send(AudioServer.get_bus_index(BUS_NAMES[key]),"Master" if key=="master" else BUS_NAMES.master)
	var master := AudioServer.get_bus_index(BUS_NAMES.master)
	if AudioServer.get_bus_effect_count(master)==0:
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.threshold_db = -2.0
		AudioServer.add_bus_effect(master,limiter)
	load_settings()
	catalog = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json")).clips
	for id in catalog:
		if id=="soundtrack_preview":
			continue
		var stream := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(ROOT+catalog[id].file))
		if catalog[id].loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(catalog[id].frames)
		streams[id] = stream
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_NAMES.music
		add_child(player)
		music.append(player)
		var bed := AudioStreamPlayer.new()
		bed.bus = BUS_NAMES.ambience
		bed.stream = streams["birds_breeze" if i==0 else "night_air"]
		bed.volume_db = -60
		add_child(bed)
		bed.play()
		beds.append(bed)
		var prop := AudioStreamPlayer2D.new()
		prop.bus = BUS_NAMES.ambience
		prop.max_distance = 650
		prop.attenuation = 1.2
		add_child(prop)
		props.append(prop)
	for i in FX_VOICES:
		var voice := AudioStreamPlayer2D.new()
		voice.bus = BUS_NAMES.effects
		voice.attenuation = 1.2
		voice.panning_strength = .75
		add_child(voice)
		voices.append(voice)
		voice_serial.append(0)
	_apply_levels()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG)!=OK:
		return
	for key in levels:
		levels[key] = clampf(float(config.get_value("volume",key,levels[key])),0,1)
	muted = bool(config.get_value("volume","muted",false))

func _save_settings() -> void:
	if not persist_settings:
		return
	var config := ConfigFile.new()
	for key in levels:
		config.set_value("volume",key,levels[key])
	config.set_value("volume","muted",muted)
	config.save(CONFIG)

func _apply_levels() -> void:
	for key in levels:
		var index := AudioServer.get_bus_index(BUS_NAMES[key])
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.0001,levels[key])))
		AudioServer.set_bus_mute(index,levels[key]<=.0001 or (key=="master" and muted))

func set_volume(key: String, value: float, persist := true) -> void:
	if not levels.has(key):
		return
	levels[key] = clampf(value,0,1)
	_apply_levels()
	if persist:
		_save_settings()
	settings_changed.emit()

func set_muted(value: bool, persist := true) -> void:
	muted = value
	_apply_levels()
	if persist:
		_save_settings()
	settings_changed.emit()

func bind_player(player: Node2D) -> void:
	get_viewport().audio_listener_enable_2d = true
	if not is_instance_valid(listener):
		listener = AudioListener2D.new()
		listener.name = "PlayerEars"
		player.add_child(listener)
	listener.make_current()

func enter_zone(zone: String) -> void:
	active_zone = zone
	battle_hold = 0
	step_phase.clear()
	last_event.clear()
	for voice in voices:
		voice.stop()
	for prop in props:
		prop.stop()
	if zone in ["town","district"]:
		props[0].stream = streams.fountain
		props[0].position = Vector2(970,700) if zone=="town" else hub.Map.District.iso(5,5)+Vector2(0,30)
		props[0].max_distance = 620
		props[0].volume_db = -10
		props[0].play()
	elif zone=="bakery":
		props[0].stream = streams.oven
		props[0].position = Vector2(1331,427)
		props[0].max_distance = 530
		props[0].volume_db = -9
		props[0].play()
	elif zone=="river":
		props[0].stream = streams.river
		props[0].position = hub.Map.point(940,440)
		props[0].max_distance = 1600
		props[0].volume_db = -9
		props[0].play()
	_select_music()

func _select_music() -> void:
	var night: bool = hub.clock>=2.65 or hub.clock<.35
	var desired := "music_night" if night else ("music_town" if active_zone in ["town","district","bakery"] else "music_woodland")
	if active_zone=="wilds" and hub.combat_active and battle_hold>0:
		desired = "music_battle"
	request_music(desired)

func request_music(id: String) -> void:
	if id==music_id:
		return
	music_id = id
	music_changes += 1
	var slot := music_ids.find(id)
	if slot<0 or not music[slot].playing:
		slot = 0 if gains[0]<=gains[1] else 1
		if music[slot].playing:
			music_positions[music_ids[slot]] = music[slot].get_playback_position()
		music[slot].stop()
		music[slot].stream = streams[id]
		music_ids[slot] = id
		music[slot].volume_db = -70
		music[slot].play(float(music_positions.get(id,0.0)))
		music[slot].stream_paused = paused
	music_target = slot

func _process(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	battle_hold = maxf(0,battle_hold-delta)
	decision_left -= delta
	if decision_left<=0 and is_instance_valid(hub.player):
		decision_left = .25
		if active_zone=="wilds" and hub.combat_active:
			for dog in hub.dogs:
				if dog.active and dog.alerted and dog.position.distance_to(hub.player.position)<600:
					battle_hold = 7.0
					break
		else:
			battle_hold = 0
		_select_music()
	for i in music.size():
		gains[i] = move_toward(gains[i],1.0 if i==music_target else 0.0,delta/1.6)
		music[i].volume_db = linear_to_db(maxf(.0001,gains[i]))-8.0-(2.0 if active_zone=="bakery" else 0.0)
		if gains[i]<=0 and i!=music_target and music[i].playing:
			music_positions[music_ids[i]] = music[i].get_playback_position()
			music[i].stop()
	var night := smoothstep(2.35,3.0,hub.clock) if hub.clock>=1 else 1.0-smoothstep(0,.6,hub.clock)
	var indoors := active_zone=="bakery"
	beds[0].volume_db = move_toward(beds[0].volume_db,-48.0 if indoors else lerpf(-13,-34,night),delta*18)
	beds[1].volume_db = move_toward(beds[1].volume_db,-55.0 if indoors else lerpf(-45,-12,night),delta*18)

func set_paused(value: bool) -> void:
	paused = value
	for group in [music,beds,props]:
		for player in group:
			player.stream_paused = value
			player.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	# Positional play() can still be queued until the next physics tick. Drop
	# transients on pause, so a queued sword/step cannot start behind the menu.
	for player in voices:
		if value:
			player.stop()
		player.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

func shutdown() -> void:
	for group in [music,beds,props,voices]:
		for player in group:
			player.stop()
			player.stream = null
	streams.clear()

func _exit_tree() -> void:
	shutdown()
	for key in ["effects","ambience","music","master"]:
		var index := AudioServer.get_bus_index(BUS_NAMES[key])
		if index>=0:
			AudioServer.remove_bus(index)

func surface_at(point: Vector2) -> String:
	if active_zone=="bakery":
		return "wood"
	if active_zone=="district":
		var delta: Vector2 = point-hub.Map.District.ORIGIN
		var uv := Vector2((delta.x/240+delta.y/120)*.5,(delta.y/120-delta.x/240)*.5)
		return "grass" if Rect2(7.17,4.17,1.66,1.66).has_point(uv) and absf(uv.x-8)>.12 and absf(uv.y-5)>.12 else "stone"
	if active_zone=="town":
		return "stone"
	if active_zone=="river" and Geometry2D.is_point_in_polygon(point,hub.Map.polygon([[780,329],[795,281],[1010,160],[1140,206],[960,325],[850,380]])):
		return "wood"
	return "grass" if active_zone=="trail" else "earth"

func footsteps(actor: Node2D, distance: float, running := false) -> void:
	if paused or hub.transitioning or distance<=.025:
		return
	if not actor.controlled and actor.position.distance_to(hub.player.position)>310:
		return
	var id := actor.get_instance_id()
	var stride := (55.0 if running else 40.0) if actor.controlled else 33.0
	var phase: float = float(step_phase.get(id,0.0))+distance
	if phase>=stride:
		phase = fposmod(phase,stride)
		play_event("step_"+surface_at(actor.position)+"_"+str(serial%4),actor.position,-7.0 if actor.controlled else -17.0,1.0)
	step_phase[id] = phase

func play_event(id: String, at: Vector2, gain_db := 0.0, pitch := 1.0) -> bool:
	if paused or hub.transitioning or not is_instance_valid(hub.player):
		return false
	if id=="bandit_alert" and elapsed-float(last_event.get(id,-100))<1.2:
		return false
	if id=="sword" or id=="hit":
		id += "_"+str(serial%3)
	if not streams.has(id) or at.distance_to(hub.player.position)>850:
		return false
	var slot := -1
	for i in voices.size():
		if not voices[i].playing:
			slot = i
			break
	if slot<0:
		slot = voice_serial.find(voice_serial.min())
	serial += 1
	var voice := voices[slot]
	voice.stop()
	voice.position = at
	voice.stream = streams[id]
	voice.max_distance = 330 if id.begins_with("step_") else 850
	voice.volume_db = gain_db
	voice.pitch_scale = pitch*(.97+(serial%7)*.01) if id.begins_with("step_") or id.begins_with("sword_") else pitch
	voice.stream_paused = false
	voice_serial[slot] = serial
	voice.play()
	last_event[id] = elapsed
	event_counts[id] = int(event_counts.get(id,0))+1
	return true
