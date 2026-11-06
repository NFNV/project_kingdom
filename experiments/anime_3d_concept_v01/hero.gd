@tool
extends Node3D

const M := preload("res://experiments/anime_3d_concept_v01/modeling.gd")
const Face := preload("res://experiments/anime_3d_concept_v01/tabby_face.svg")

var legs: Array[Node3D] = []
var arms: Array[Node3D] = []


func _ready() -> void:
	var line := Color("573325")
	var fur := M.paint("eea45e")
	var head_fur := M.paint("eea45e",true)
	head_fur.set_shader_parameter("face_art",Face)
	head_fur.set_shader_parameter("stripe_color",Color("c98049"))
	head_fur.set_shader_parameter("cream_color",Color("efd9b7"))
	M.ink(head_fur,line,.006)
	M.ink(fur,line,.006)

	var pale := M.paint("e9d4ae")
	var vest := M.paint("8d5f43")
	var seam := M.paint("c39968")
	var scarf := M.paint("a33d39")
	var silk := M.paint("c85648")
	var cloth := M.paint("717455")
	var leather := M.paint("64483b")
	var brass := M.paint("dfae5f")
	M.ink(vest,line,.004)
	M.ink(scarf,line,.004)
	M.ink(cloth,Color("454332"),.005)
	M.ink(leather,line,.004)

	M.loft(self,"Leather jerkin",[
		[Vector3(0,.634,.005),.09,.07],
		[Vector3(0,.669,.006),.321,.235],
		[Vector3(0,.83,.009),.346,.234],
		[Vector3(0,1.045,.012),.306,.215],
		[Vector3(0,1.214,.003),.234,.177],
		[Vector3(0,1.245,.003),.067,.071],
	],vest)
	M.ball(self,"Linen chest",Vector3(0,1.093,.187),Vector3(.183,.184,.054),pale)
	M.ball(self,"Breeches",Vector3(0,.604,0),Vector3(.32,.193,.229),cloth)
	M.ball(self,"Waist belt",Vector3(0,.717,.016),Vector3(.346,.059,.237),leather)
	M.box(self,"Brass buckle",Vector3(.006,.719,.254),Vector3(.115,.087,.029),brass)
	M.box(self,"Buckle inset",Vector3(.006,.719,.272),Vector3(.067,.049,.013),leather)

	for side: float in [-1.0,1.0]:
		var leg := Node3D.new()
		leg.name = "Leg pivot"
		add_child(leg)
		legs.append(leg)
		var stance := Vector3(side*.19,.045,side*.046)
		M.limb(leg,"Trouser leg",Vector3(side*.156,.588,0),stance+Vector3(0,.251,0),.151,.164,cloth)
		M.ball(leg,"Boot cuff",stance+Vector3(0,.192,.017),Vector3(.146,.078,.146),vest)
		var boot := M.ball(leg,"Boot",stance+Vector3(0,.087,.087),Vector3(.151,.132,.217),leather)
		boot.rotation.y = side * .16
		M.ball(leg,"Stitched sole",stance+Vector3(0,.004,.103),Vector3(.15,.049,.203),M.paint("47392e"))

		move_pivot(leg,Vector3(side*.156,.59,0))

		var arm := Node3D.new()
		arm.name = "Arm pivot"
		add_child(arm)
		arms.append(arm)
		var shoulder := Vector3(side*.256,1.159,-.018)
		var elbow := Vector3(side*.389,.951,.019)
		var wrist := Vector3(side*.412,.824,.103)
		M.limb(arm,"Rolled sleeve",shoulder,elbow,.129,.139,pale)
		M.limb(arm,"Bracer",elbow.lerp(wrist,.36),wrist,.092,.100,leather)
		M.ball(arm,"Paw",wrist+Vector3(side*.01,-.041,.022),Vector3(.083,.098,.09),fur)
		M.ball(arm,"Thumb",wrist+Vector3(side*-.054,-.027,.065),Vector3(.046,.059,.044),fur)
		move_pivot(arm,shoulder)
		M.curve(self,"Satchel harness",PackedVector3Array([
			Vector3(side*.204,1.211,.146), Vector3(side*.201,1.116,.213),
			Vector3(side*.176,1.017,.244), Vector3(side*.155,.936,.241), Vector3(side*.14,.889,.234),
		]),.026,leather,.9)
		for y: float in [.797,.868]:
			M.ball(self,"Jerkin rivet",Vector3(side*.088,y,.242),Vector3.ONE*.019,brass)
		M.curve(self,"Stitching",PackedVector3Array([
			Vector3(side*.138,.755,.235),Vector3(side*.155,.814,.227),
			Vector3(side*.154,.869,.227),Vector3(side*.167,.914,.229),
		]),.006,seam,1.0)

	M.ball(self,"Leather satchel",Vector3(0,.996,-.267),Vector3(.281,.286,.177),vest)
	M.ball(self,"Satchel flap",Vector3(0,1.126,-.388),Vector3(.264,.147,.088),M.paint("a6734e"))
	for side: float in [-1.0,1.0]:
		M.ball(self,"Satchel strap",Vector3(side*.105,1.024,-.448),Vector3(.029,.163,.027),leather)
		M.box(self,"Satchel buckle",Vector3(side*.105,.992,-.477),Vector3(.064,.068,.022),brass)

	var tail_paint := M.paint("eaa15d")
	tail_paint.set_shader_parameter("tail",true)
	tail_paint.set_shader_parameter("stripe_color",Color("cb874a"))
	tail_paint.set_shader_parameter("cream_color",Color("f4d7a9"))
	M.ink(tail_paint,line,.005)
	M.curve(self,"Ringed tail",PackedVector3Array([
		Vector3(.065,.655,-.213), Vector3(.18,.56,-.306), Vector3(.32,.479,-.363),
		Vector3(.48,.44,-.378), Vector3(.64,.445,-.354), Vector3(.768,.49,-.308),
		Vector3(.86,.583,-.252), Vector3(.911,.684,-.186), Vector3(.929,.769,-.137),
		Vector3(.932,.833,-.114), Vector3(.926,.87,-.109),
	]),.132,tail_paint,.08)

	var head := Node3D.new()
	head.name = "Sculpted head"
	head.position = Vector3(0,1.705,.029)
	head.scale = Vector3(1.18,.98,.90)
	add_child(head)
	M.loft(head,"Tabby face",[
		[Vector3(0,-.482,.06),.05,.05],
		[Vector3(0,-.414,.065),.235,.252],
		[Vector3(0,-.306,.068),.375,.360],
		[Vector3(0,-.183,.060),.469,.429],
		[Vector3(0,-.062,.036),.50,.445],
		[Vector3(0,.091,.004),.459,.462],
		[Vector3(0,.254,-.025),.374,.398],
		[Vector3(0,.395,-.041),.268,.278],
		[Vector3(0,.477,-.048),.123,.127],
		[Vector3(0,.50,-.048),.004,.004],
	],head_fur)
	var pink := M.paint("d29584")
	for side: float in [-1.0,1.0]:
		M.loft(head,"Outer ear",[
			[Vector3(side*.27,.21,-.06),.10,.115],
			[Vector3(side*.329,.29,-.062),.147,.125],
			[Vector3(side*.372,.425,-.056),.141,.098],
			[Vector3(side*.421,.563,-.045),.089,.066],
			[Vector3(side*.471,.711,-.043),.028,.021],
			[Vector3(side*.48,.752,-.038),.005,.004],
		],fur)
		M.loft(head,"Inner ear",[
			[Vector3(side*.322,.34,.045),.084,.02],
			[Vector3(side*.366,.421,.036),.103,.019],
			[Vector3(side*.408,.526,.024),.073,.020],
			[Vector3(side*.45,.642,.004),.034,.015],
			[Vector3(side*.473,.707,-.017),.006,.006],
		],pink)

	M.ball(self,"Scarf collar",Vector3(0,1.301,.008),Vector3(.328,.094,.239),scarf)
	M.curve(self,"Scarf upper fold",PackedVector3Array([
		Vector3(-.274,1.302,.128),Vector3(-.138,1.268,.234),
		Vector3(.009,1.249,.246),Vector3(.147,1.274,.219),Vector3(.273,1.315,.123),
	]),.033,silk,.82)
	M.loft(self,"Scarf drape",[
		[Vector3(.014,1.097,.251),.019,.013],
		[Vector3(.007,1.155,.257),.085,.024],
		[Vector3(0,1.225,.228),.197,.051],
		[Vector3(-.009,1.284,.169),.256,.063],
		[Vector3(-.012,1.313,.137),.174,.036],
	],scarf)
	M.ball(self,"Scarf knot",Vector3(-.229,1.305,-.159),Vector3(.098,.073,.106),scarf)
	M.curve(self,"Scarf tail",PackedVector3Array([
		Vector3(-.235,1.309,-.186), Vector3(-.347,1.298,-.229),
		Vector3(-.48,1.276,-.238), Vector3(-.61,1.291,-.259),
		Vector3(-.728,1.337,-.306), Vector3(-.815,1.326,-.345),
	]),.084,scarf,.10)


func move_pivot(joint: Node3D, at: Vector3) -> void:
	joint.position = at
	for part: Node3D in joint.get_children():
		part.position -= at


func pose_walk(cycle: float, weight: float) -> void:
	var swing := sin(cycle) * weight
	for index in legs.size():
		var side := 1.0 if index == 0 else -1.0
		legs[index].rotation.x = swing * side * .62
		arms[index].rotation.x = -swing * side * .51
	position.y = absf(swing) * .045
