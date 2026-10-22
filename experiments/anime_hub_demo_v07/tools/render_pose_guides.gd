extends SceneTree
func _initialize() -> void:
	for direction in ["e","se","s","sw","w","nw","n","ne"]:
		var path: String = "res://experiments/anime_hub_demo_v07/assets/motion/guides/"+direction
		var image := Image.new()
		image.load_svg_from_string(FileAccess.get_file_as_string(path+".svg"))
		image.save_png(ProjectSettings.globalize_path(path+".png"))
	quit()
