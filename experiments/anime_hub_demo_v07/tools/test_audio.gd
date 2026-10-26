extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame

func count_prefix(prefix: String) -> int:
	var count := 0
	for id in game.audio.event_counts:
		if id.begins_with(prefix):
			count += int(game.audio.event_counts[id])
	return count

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	game.player.automated = true
	game.dialogue_left = 0
	var sound = game.audio
	sound.persist_settings = false
	sound.set_muted(false,false)
	for key in sound.levels:
		sound.set_volume(key,.7,false)
	await ticks(5)
	check(sound.streams.size()==43 and sound.voices.size()==12,"All 43 gameplay clips are preloaded and effects use a fixed 12-voice pool")
	check(sound.listener.get_parent()==game.player,"The listener follows the actual cat through every scene")
	check(sound.music_id=="music_town" and sound.music[sound.music_target].playing,"Garden Square starts actual streamed town music")
	check(sound.props[0].playing and sound.props[0].position==Vector2(970,700),"The plaza fountain is an actual positional loop")
	check(sound.surface_at(game.player.position)=="stone","Town footsteps use stone")
	var steps := count_prefix("step_")
	await ticks(30)
	check(count_prefix("step_")==steps,"Standing still cannot make footsteps")
	game.player.intent = Vector2.RIGHT
	await ticks(35)
	game.player.intent = Vector2.ZERO
	check(count_prefix("step_stone_")>0,"Real movement produces stone footsteps")
	steps = count_prefix("step_")
	sound.footsteps(game.player,0)
	check(count_prefix("step_")==steps,"Blocked movement with zero travel cannot make footfalls")
	var changes: int = sound.music_changes
	game._load_zone("bakery","town")
	await ticks(4)
	check(sound.music_changes==changes and sound.music_id=="music_town","Entering the bakery keeps the same music instead of restarting it")
	check(sound.surface_at(game.player.position)=="wood" and sound.props[0].stream==sound.streams.oven,"The bakery has wooden footfalls and a positional oven loop")
	game.interact("shop_vendor")
	var confirms := count_prefix("ui_confirm")
	game.coins = 20
	game.buy(0)
	check(count_prefix("ui_confirm")==confirms+1,"A successful real purchase makes one confirmation sound")
	game.coins = 0
	game.buy(0)
	check(count_prefix("ui_error")>0,"An unaffordable purchase has distinct feedback")
	game.close_shop()
	game._load_zone("trail","town")
	check(sound.music_id=="music_woodland" and sound.surface_at(game.player.position)=="grass","The trail selects the woodland theme and grass footsteps")
	game.clock = 3
	await ticks(20)
	check(sound.music_id=="music_night","The actual shared clock selects the night score")
	await ticks(100)
	check(sound.music.filter(func(player): return player.playing).size()==1,"The outgoing music channel stops after the crossfade")
	check(sound.beds[1].volume_db>sound.beds[0].volume_db,"Night ambience favors crickets over daylight birds")
	game._load_zone("river","trail")
	check(sound.props[0].playing and sound.props[0].stream==sound.streams.river,"Riverbend uses a flowing-water loop")
	game.clock = 1
	game._load_zone("wilds","river")
	for dog in game.dogs:
		dog.set_physics_process(false)
	check(sound.music_id=="music_woodland","A safe forest entrance has exploration music")
	var dog = game.dogs[0]
	game.player.position = dog.position-Vector2(65,0)
	dog.alerted = true
	await ticks(20)
	check(sound.music_id=="music_battle" and sound.battle_hold>0,"A nearby alerted enemy starts battle music")
	dog.alerted = false
	await ticks(30)
	check(sound.music_id=="music_battle","Short gaps between attacks do not flicker the score")
	game.player.cooldown = 0
	game.player.swing = 0
	game.player.facing = Vector2.RIGHT
	var swords := count_prefix("sword_")
	game.player.try_attack()
	await ticks(5)
	check(count_prefix("sword_")==swords,"Drawing the sword does not play the contact whoosh early")
	await ticks(10)
	check(count_prefix("sword_")==swords+1,"The real sword swing plays its sound once at the animated slash")
	check(count_prefix("hit_")>0,"A successful hit makes impact audio")
	await ticks(30)
	game.player.skill_cooldown = 0
	game.player.cooldown = 0
	game.player.try_skill()
	check(count_prefix("wind_charge")==1,"An accepted Q cast plays its charge cue")
	await ticks(19)
	check(count_prefix("wind_release")==1,"The actual projectile launch plays one release sound")
	for i in 30:
		sound.play_event("sword",game.player.position)
	check(sound.voices.size()==12,"A burst of effects cannot allocate additional players")
	check(not sound.play_event("sword",game.player.position+Vector2(2000,0)),"Distant sounds are culled before taking a voice")
	game.set_paused(true)
	var hold: float = sound.battle_hold
	var phase: Array = sound.gains.duplicate()
	await ticks(90)
	check(sound.battle_hold==hold and sound.gains==phase,"Pause freezes battle music hold and crossfade progress")
	check(sound.music.all(func(player): return not player.playing or player.stream_paused) and sound.voices.all(func(player): return not player.playing or player.stream_paused),"Pause suspends actual music and effects streams")
	check(not sound.play_event("sword",game.player.position),"Paused gameplay cannot emit new effects")
	game.set_paused(false)
	check(sound.music.all(func(player): return not player.stream_paused),"Resume continues paused streams")
	game.set_paused(true)
	game.ui.audio_sliders.music.value = .23
	check(is_equal_approx(sound.levels.music,.23) and game.ui.audio_values.music.text=="23%","The real pause-menu music slider controls its bus and percentage")
	check(is_equal_approx(sound.levels.effects,.7),"Music volume does not alter effects volume")
	sound.set_muted(true,false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(sound.BUS_NAMES.master)) and game.ui.audio_mute.button_pressed,"Mute silences the game master bus and updates the checkbox")
	sound.set_muted(false,false)
	game.set_paused(false)
	game._load_zone("town","forest")
	check(sound.voices.all(func(player): return not player.playing),"Travel stops old combat/footstep voices")
	check(sound.battle_hold==0 and sound.music_id=="music_town","Travel cannot leak battle music into town")
	check(not game.player.try_attack() and count_prefix("wind_release")==1,"Safe-area guards cannot trigger combat audio")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = .5
	var master := AudioServer.get_bus_index(sound.BUS_NAMES.master)
	AudioServer.add_bus_effect(master,capture)
	sound.set_volume("music",0,false)
	sound.set_volume("ambience",0,false)
	sound.set_volume("effects",.7,false)
	sound.play_event("ui_confirm",game.player.position)
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<400:
		await process_frame
	var mixed := capture.get_buffer(capture.get_frames_available())
	var energy := 0.0
	for sample in mixed:
		energy += sample.length_squared()
	check(mixed.size()>256 and energy>.001,"The actual positional effects mixer produces non-silent PCM with music and ambience muted")
	capture.clear_buffer()
	sound.set_volume("effects",0,false)
	sound.set_volume("music",.7,false)
	start = Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<400:
		await process_frame
	var musical_pcm := capture.get_buffer(capture.get_frames_available())
	var musical_energy := 0.0
	for sample in musical_pcm:
		musical_energy += sample.length_squared()
	check(musical_pcm.size()>256 and musical_energy>.001,"The actual music channel produces non-silent PCM independently of effects")
	AudioServer.remove_bus_effect(master,AudioServer.get_bus_effect_count(master)-1)
	var report := {"audio_driver":AudioServer.get_driver_name(),"checks":checks,"passed":checks-failures.size(),"failures":failures,"mixed_pcm_frames":mixed.size(),"mix_energy":energy,"scope":"Actual source loading and playback, listener, positional loops, real movement footfalls, no idle/wall steps, purchase cues, zone/clock/battle score selection and crossfade, contact/skill event timing, bounded voices, distance culling, pause/resume, real volume widgets/mute, travel cleanup and actual PCM mixer output."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"audio_test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Audio: ",checks-failures.size(),"/",checks," checks passed; PCM frames ",mixed.size())
	quit(0 if failures.is_empty() else 1)
