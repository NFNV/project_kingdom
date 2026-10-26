extends RefCounted

# Art selection and gameplay events use the same clock. "transition" poses are
# drawn in-betweens, not blended silhouettes or a separately rotating weapon.
const LIGHT_DURATION := .60
const LIGHT_CONTACT := .22
const LIGHT_END_CONTACT := .34
const WIND_DURATION := .72
const WIND_RELEASE := .28
const LIGHT_POSES := [
	[.08,"transition",0,"draw"],[.17,"attack",0,"anticipation"],
	[.22,"transition",1,"early_slash"],[.28,"attack",1,"contact"],
	[.34,"transition",2,"follow_through"],[.40,"attack",2,"follow_through"],
	[.48,"attack",3,"recover"],[.60,"transition",3,"sheathe"]
]
const WIND_POSES := [
	[.08,"transition",0,"draw"],[.24,"attack",0,"charge"],
	[.28,"transition",1,"release"],[.36,"attack",1,"release"],
	[.42,"transition",2,"follow_through"],[.49,"attack",2,"follow_through"],
	[.58,"attack",3,"recover"],[.72,"transition",3,"sheathe"]
]

static func selection(elapsed: float, power: bool) -> Array:
	var sequence: Array = WIND_POSES if power else LIGHT_POSES
	for entry in sequence:
		if elapsed<float(entry[0]):
			return entry
	return sequence[-1]
