@tool
extends Node3D

const M := preload("res://experiments/anime_3d_concept_v01/modeling.gd")


func _ready() -> void:
	var oak := M.paint("855c3c")
	var heartwood := M.paint("ac7a4b")
	var blue := M.paint("406c77")
	var ivory := M.paint("f0d99d")
	var base := M.cylinder(self,"Footing",Vector3(0,.09,0),.265,.31,.18,M.paint("a49a75"),7)
	base.scale.z = .82
	var upright := M.box(self,"Oak post",Vector3(0,.733,0),Vector3(.15,1.36,.15),oak)
	upright.rotation.z = -.032
	M.ball(self,"Turned finial",Vector3(.02,1.427,0),Vector3(.102,.102,.098),heartwood)
	M.box(self,"Sign rail",Vector3(.081,1.108,.067),Vector3(.85,.343,.12),heartwood).rotation.z = -.045
	M.box(self,"Painted face",Vector3(.081,1.109,.138),Vector3(.767,.27,.042),blue).rotation.z = -.045
	for x: float in [-.242,.406]:
		M.ball(self,"Copper stud",Vector3(x,1.107,.168),Vector3(.025,.025,.014),ivory)
	M.curve(self,"Arrow shaft",PackedVector3Array([Vector3(-.107,1.111,.171),Vector3(.096,1.111,.171),Vector3(.266,1.111,.171)]),.023,ivory,1.0)
	M.curve(self,"Arrowhead",PackedVector3Array([Vector3(.169,1.181,.17),Vector3(.271,1.111,.171),Vector3(.169,1.044,.17)]),.023,ivory,1.0)
