@tool
extends Resource
class_name KinematicStats

const DEFAULT_F:float = 0.1
const DEFAULT_Z:float = 1.0
const DEFAULT_R:float = 0

signal on_stats_changed

var constants:KinematicConstants = KinematicConstants.new(DEFAULT_F, DEFAULT_Z, DEFAULT_R)

@export_range(0.0001, 2, 0.0001, "exp") var f:float = DEFAULT_F:
	get:
		return f
	set(value):
		f = value
		_update_constants()
		on_stats_changed.emit()
@export_range(0.001, 5, 0.001, "exp") var z:float = DEFAULT_Z:
	get:
		return z
	set(value):
		z = value
		_update_constants()
		on_stats_changed.emit()
@export_range(-10, 10, 0.01) var r:float = DEFAULT_R:
	get:
		return r
	set(value):
		r = value
		_update_constants()
		on_stats_changed.emit()
@export var use_pole_matching:bool = false:
	get:
		return use_pole_matching
	set(value):
		use_pole_matching = value
		_update_constants()
		on_stats_changed.emit()
@export_range(0.5, 20, 0.5) var domain:float = 2.0:
	get:
		return domain
	set(value):
		domain = value
		on_stats_changed.emit()

@export var viz = Viz.Show.Vizualizer

func _init() -> void:
	_update_constants()

func _update_constants() -> void:
	constants = KinematicConstants.new(f, z, r, use_pole_matching)
