class_name KingdomHealth
extends Node

signal changed(current: int, maximum: int)
signal died

@export var maximum: int = 3
var current: int = 3
var invulnerability: float = 0.0


func _physics_process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)


func reset() -> void:
	current = maximum
	invulnerability = 0.0
	changed.emit(current, maximum)


func is_dead() -> bool:
	return current <= 0


func take_damage(amount: int, grace_period: float = 0.2) -> bool:
	if amount <= 0 or is_dead() or invulnerability > 0.0:
		return false
	current = maxi(0, current - amount)
	invulnerability = grace_period
	changed.emit(current, maximum)
	if is_dead():
		died.emit()
	return true
