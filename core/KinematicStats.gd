@tool
extends Resource
class_name KinematicStats

const DEFAULT_F:float = 0.1
const DEFAULT_Z:float = 1.0
const DEFAULT_R:float = 0

signal on_stats_changed

@export_range(0.0001, 2, 0.0001, "exp") var f:float = DEFAULT_F:
	get:
		return f
	set(value):
		f = value
		on_stats_changed.emit()
@export_range(0.001, 5, 0.001, "exp") var z:float = DEFAULT_Z:
	get:
		return z
	set(value):
		z = value
		on_stats_changed.emit()
@export_range(-10, 10, 0.01) var r:float = DEFAULT_R:
	get:
		return r
	set(value):
		r = value
		on_stats_changed.emit()
@export_range(0.5, 20, 0.5) var domain:float = 2.0:
	get:
		return domain
	set(value):
		domain = value
		on_stats_changed.emit()

@export var viz = Viz.Show.Vizualizer
