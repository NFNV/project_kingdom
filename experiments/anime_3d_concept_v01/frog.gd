@tool
extends Node3D

const M := preload("res://experiments/anime_3d_concept_v01/modeling.gd")


func _ready() -> void:
	var leaf := M.paint("88a857")
	var lime := M.paint("a7bd69")
	var moss := M.paint("607e46")
	var throat := M.paint("e7d38b")
	var ink := M.paint("33432d")
	var hide := M.paint("8c6042")
	var blanket := M.paint("3b8582")
	var stitch := M.paint("dfbc74")

	M.ball(self,"Rounded back",Vector3(0,.504,-.151),Vector3(.63,.49,.81),leaf)
	M.ball(self,"Throat",Vector3(0,.399,.31),Vector3(.558,.274,.55),throat)
	M.ball(self,"Broad snout",Vector3(0,.581,.299),Vector3(.61,.322,.583),lime)
	var smile := PackedVector3Array()
	for index in 21:
		var x := lerpf(-.51,.51,index/20.0)
		var y := .435 + .05 * pow(absf(x)/.51,2.5)
		# Lay the seam on whichever ellipsoid is visible at this point.
		var jaw_z := .31 + .55 * sqrt(maxf(0.0,1.0 - pow(x/.558,2) - pow((y-.399)/.274,2)))
		var snout_z := .299 + .583 * sqrt(maxf(0.0,1.0 - pow(x/.61,2) - pow((y-.581)/.322,2)))
		smile.append(Vector3(x,y,maxf(jaw_z,snout_z)+.006))
	M.curve(self,"Mouth line",smile,.012,ink,1.0)

	for side: float in [-1.0,1.0]:
		M.ball(self,"Nostril",Vector3(side*.151,.647,.861),Vector3(.035,.017,.016),moss)
		var eye := Node3D.new()
		eye.name = "Raised eye"
		eye.position = Vector3(side*.381,.823,.396)
		eye.rotation.y = side * .29
		add_child(eye)
		M.ball(eye,"Eye hood",Vector3.ZERO,Vector3(.225,.263,.222),leaf)
		M.ball(eye,"Dark eye rim",Vector3(0,.027,.145),Vector3(.157,.184,.107),moss)
		M.ball(eye,"Gold iris",Vector3(0,.025,.217),Vector3(.124,.146,.048),M.paint("dfb75b"))
		M.ball(eye,"Pupil",Vector3(0,.029,.255),Vector3(.057,.116,.025),ink)
		M.ball(eye,"Eye highlight",Vector3(-.039,.096,.267),Vector3(.028,.032,.011),M.paint("fff2c4"))

		M.ball(self,"Folded hind thigh",Vector3(side*.539,.301,-.365),Vector3(.351,.287,.414),moss)
		M.limb(self,"Bent shank",Vector3(side*.69,.25,-.65),Vector3(side*.735,.109,-.287),.115,.116,leaf)
		webbed_foot(Vector3(side*.762,.064,-.217),side,leaf)
		M.limb(self,"Foreleg",Vector3(side*.449,.473,.36),Vector3(side*.516,.115,.489),.099,.104,moss)
		webbed_foot(Vector3(side*.543,.055,.52),side,lime)
		for index in 3:
			M.ball(self,"Dapple",Vector3(side*(.43+index*.068),.84-index*.046,-.38-index*.046),Vector3(.059,.023,.075),moss)

	M.ball(self,"Saddle blanket",Vector3(0,.917,-.316),Vector3(.445,.114,.411),blanket)
	M.ball(self,"Leather seat",Vector3(0,1.001,-.36),Vector3(.318,.095,.31),hide)
	for side: float in [-1.0,1.0]:
		var strap := M.ball(self,"Saddle girth",Vector3(side*.404,.835,-.347),Vector3(.05,.219,.076),hide)
		strap.rotation.z = side * .48
		M.box(self,"Girth buckle",Vector3(side*.49,.723,-.318),Vector3(.048,.087,.097),stitch)


func webbed_foot(at: Vector3, side: float, pigment: Material) -> void:
	var foot := Node3D.new()
	foot.name = "Webbed foot"
	foot.position = at
	foot.rotation.y = side*.22
	add_child(foot)
	M.ball(foot,"Webbing",Vector3(0,0,.036),Vector3(.139,.049,.138),pigment)
	for toe: float in [-1.0,0.0,1.0]:
		var extension := .195 - absf(toe)*.037
		M.limb(foot,"Toe",Vector3(toe*.065,.003,.05),Vector3(toe*.126,.004,extension),.045,.046,pigment)
