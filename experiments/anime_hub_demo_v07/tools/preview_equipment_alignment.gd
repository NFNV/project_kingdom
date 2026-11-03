extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var checks := 0
var failures: Array[String] = []
var actors: Array[CharacterBody2D] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)
func capture(id: String) -> void:
 if DisplayServer.get_name()=="headless": return
 DisplayServer.window_move_to_foreground()
 for i in 3: await physics_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/gear_alignment_"+id+".png")
func run() -> void:
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = "/tmp/kingdom-gear-alignment-preview.json"
 root.add_child(game)
 game.auto_clock = false
 game.autosave_enabled = false
 game._load_zone("wilds","river")
 game.paused = true
 game.hide()
 game.ui.hide()
 var canvas := CanvasLayer.new()
 canvas.layer = 90
 root.add_child(canvas)
 var paper := ColorRect.new()
 paper.color = Color("e8e3d5")
 paper.size = Vector2(2560,1440)
 canvas.add_child(paper)
 var directions: Array = game.player.sprite.DIRECTIONS
 for row in 3:
  for column in 8:
   var actor = game.Actor.new()
   actor.controlled = true
   actor.hub = game
   actor.position = Vector2(160+column*320,380+row*440)
   actor.scale = Vector2.ONE*3.4
   canvas.add_child(actor)
   actor.set_physics_process(false)
   actor.combat_left = 10
   actor.sprite.set_pose(["idle","walk","run"][row],directions[column],0)
   actor.facing = Vector2.from_angle(column*PI/4)
   actor.weapon.sync_pose()
   actor.shield.sync_pose()
   actors.append(actor)
   var label := Label.new()
   label.text = directions[column].to_upper()+" / "+["IDLE","WALK","RUN"][row]
   label.position = Vector2(column*320+50,row*440+20)
   label.add_theme_font_size_override("font_size",22)
   label.add_theme_color_override("font_color",Color("32443d"))
   canvas.add_child(label)
 await capture("phase_0")
 for phase in [2,4,6]:
  for index in actors.size():
   var row := index/8
   var actor = actors[index]
   actor.sprite.set_pose(["idle","walk","run"][row],directions[index%8],0 if row==0 else phase)
   actor.weapon.sync_pose()
   actor.shield.sync_pose()
  await capture("phase_"+str(phase))
 # Exercise every registered pose, including a logical heading that differs
 # from the visible sprite while a smoothed turn is still in progress.
 var actor = actors[0]
 for direction in directions:
  for state in ["idle","walk","run"]:
   var count: int = actor.sprite.sprite_frames.get_frame_count(state+"_"+direction)
   for frame in count:
    actor.sprite.set_pose(state,direction,frame)
    actor.facing = -Vector2.from_angle(directions.find(direction)*PI/4)
    for guarding in [false,true]:
     actor.guarding = guarding
     actor.weapon.sync_pose()
     actor.shield.sync_pose()
     var bottom: float = actor.shield.Pose.face_bottom(actor)
     var top: float = actor.shield.position.y-128*actor.shield.image.scale.y
     check(top>=bottom+1.8,"Shield stays below the face: "+direction+"/"+state+"/"+str(frame)+"/"+str(guarding))
     check((actor.weapon.get_index()>actor.sprite.get_index())==(direction in ["e","se","s","ne"] and actor.weapon.Pose.measured(actor,"weapon")),"Sword uses correct near/far arm occlusion: "+direction+"/"+state+"/"+str(frame))
     check((actor.shield.get_index()<actor.sprite.get_index())==(direction in ["n","ne"] or not actor.shield.Pose.measured(actor,"shield")),"Shield layering follows the drawn direction during turns: "+direction+"/"+state+"/"+str(frame))
     var point: Vector2 = actor.weapon.hand_anchor
     var grip: Vector2 = actor.weapon.transform*Vector2(0,-2)
     check(grip.distance_to(point)<.01,"Sword handle remains attached to the measured paw through pose scaling: "+direction+"/"+state+"/"+str(frame))
 for candidate in actors:
  candidate.guarding = false
  candidate.combat_left = 0
  candidate.weapon.sync_pose()
  candidate.shield.sync_pose()
 check(actors.all(func(a): return not a.weapon.visible and not a.shield.visible),"All eight directions retain the combat-only visibility rule")
 var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"160 registered poses, raised/lowered guard, face clearance, per-direction body occlusion despite mismatched logical heading, mapped paw/handle attachment, combat expiry; native 1440p contact sheets."}
 FileAccess.open(ROOT+"gear_alignment_results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print("GEAR ALIGNMENT ",checks-failures.size(),"/",checks)
 canvas.queue_free()
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
