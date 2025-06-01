extends RefCounted
class_name ForceOverTime

var _force := Vector2.ZERO
var _duration := 0.0
var _timeLeft := 0.0

func _init(force: Vector2, duration: float) -> void:
	_force = force
	_duration = duration
	_timeLeft = duration

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
