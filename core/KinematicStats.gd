@tool
extends Resource
class_name KinematicStats

const DEFAULT_F:float = 0.1
const DEFAULT_Z:float = 1.0
const DEFAULT_R:float = 0

signal on_stats_changed

var constants:KinematicConstants = KinematicConstants.new(DEFAULT_F, DEFAULT_Z, DEFAULT_R)

## frequency
@export_range(0.0001, 10, 0.0001, "exp") var f:float = DEFAULT_F:
	get:
		return f
	set(value):
		f = value
		_update_constants()
		on_stats_changed.emit()

## damping
@export_range(0.001, 5, 0.001, "exp") var z:float = DEFAULT_Z:
	get:
		return z
	set(value):
		z = value
		_update_constants()
		on_stats_changed.emit()

## system response
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

@export_category("Visualization")
@export_range(0.5, 20, 0.5, "exp") var domain:float = 2.0:
	get:
		return domain
	set(value):
		domain = value
		on_stats_changed.emit()

@export var viz = Viz.Show.Vizualizer

@export_category("Drag")
## Set drag t-value. 0 => no drag, 1 => stops immediately
@export_range(0.0, 1.0, 0.001) var drag: float = 0.1:
	get:
		return drag
	set(value):
		drag = value
		on_stats_changed.emit()

@export_category("handling")
## 0 => slowest throttle up, 1 => infinitely fast throttle up
@export_range(0.1, 1.0, 0.001) var throttle_up_speed: float = 0.2:
	get:
		return throttle_up_speed
	set(value):
		throttle_up_speed = value
		on_stats_changed.emit()
# TODO: REMOVE THIS
@export_range(0.0, 2.0, 0.001) var throttle_up_time: float = 0.15
@export_range(0.0, 2.0, 0.001) var throttle_down_time: float = 0.3
## Vehicle handling — determines responsiveness of changing directions
@export_range(0.0, 1.0, 0.001) var handling: float = 0.5

func _init() -> void:
	_update_constants()

func _update_constants() -> void:
	constants = KinematicConstants.new(f, z, r, use_pole_matching)
