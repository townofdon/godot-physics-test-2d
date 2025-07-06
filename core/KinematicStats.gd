@tool
extends Resource
class_name KinematicStats

const DEFAULT_F:float = 0.1
const DEFAULT_Z:float = 1.0
const DEFAULT_R:float = 0

signal on_stats_changed

var accel_constants:KinematicConstants = KinematicConstants.new(DEFAULT_F, DEFAULT_Z, DEFAULT_R)
var rotation_constants:KinematicConstants = KinematicConstants.new(4.0, 1.0, 0.0)

@export_category("movement")
## base speed
@export var speed: float = 400
## max speed the vehicle can reach
@export var top_speed: float = 600
## Determines how fast the vehicle reaches top speed
@export_range(0.0, 80.0, 0.0001, "exp") var top_speed_growth: float = 1.06

@export_category("rotation")
@export var enforce_cardinality := false
## base rotation speed (degrees / sec)
@export_range(0, 1440.0, 0.01) var rotation_speed: float = 360
## rotation acceleration (freq of spring response)
@export_range(0.001, 80.0, 0.0001, "exp") var rotation_accel: float = 4.0:
	set(value):
		rotation_accel = value
		_update_constants()
		on_stats_changed.emit()
@export_range(0, 1, 0.001) var rotation_limit_at_speed: float = 0.3

@export_category("acceleration")
## frequency
@export_range(0.0001, 10, 0.0001, "exp") var f:float = DEFAULT_F:
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
## Set drag t-value. 0 => no drag, 80 => stops immediately
@export_range(0.0, 80.0, 0.001, "exp") var drag: float = 0.1:
	get:
		return drag
	set(value):
		drag = value
		on_stats_changed.emit()

@export_category("handling")
## 0 => slowest throttle up, 1 => fastest throttle up
@export_range(0.001, 80.0, 0.001, "exp") var throttle_up_speed: float = 0.2:
	get:
		return throttle_up_speed
	set(value):
		throttle_up_speed = value
		on_stats_changed.emit()
@export_range(0.0, 2.0, 0.001) var throttle_down_time: float = 0.3
## Vehicle handling — determines responsiveness of changing directions
@export_range(0.0, 1.0, 0.001) var handling: float = 0.5
## How fast the vehicle comes to a stop when opposite thrust is applied
@export_range(0.0, 1.0, 0.001) var brake_power: float = 0.0

@export_category("arrival")
@export var arrive_distance: float = 50
@export var arrive_curve: Curve

func _init() -> void:
	_update_constants()

func _update_constants() -> void:
	accel_constants = KinematicConstants.new(f, z, r, use_pole_matching)
	rotation_constants = KinematicConstants.new(rotation_accel, 1.0, 0, false)
