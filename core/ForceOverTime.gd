extends RefCounted
class_name ForceOverTime

enum {
	COLLISION,
	AFFECTOR,
	TRACTOR_BEAM,
	# etc.
}

var _force := Vector2.ZERO
var _duration := 0.0
var _timeLeft := 0.0
var _type := 0
var _entity_collided_with: Node

func _init(force: Vector2, duration: float, type: int, entity_collided_with = null) -> void:
	_force = force
	_duration = duration
	_timeLeft = duration
	_entity_collided_with = entity_collided_with

func debug() -> void:
	print("f=", _force, ",t=", _timeLeft)

func tick(delta: float) -> void:
	_timeLeft = max(_timeLeft - delta, 0)

func get_value() -> Vector2:
	return _force

func get_t() -> float:
	if (_duration <= 0):
		return 0
	return clamp(_timeLeft / _duration, 0, 1)

func is_completed() -> bool:
	return _timeLeft <= 0

func did_collide_with(node: Node) -> bool:
	return _entity_collided_with && node == _entity_collided_with

func is_type(type: int) -> bool:
	return _type == type
