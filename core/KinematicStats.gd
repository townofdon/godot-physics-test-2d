@tool
extends Resource
class_name KinematicStats

const DEFAULT_F:float = 0.1
const DEFAULT_Z:float = 1.0
const DEFAULT_R:float = 0

@export_range(0.0001, 2, 0.0001, "exp") var f:float = DEFAULT_F:
	get:
		return f
	set(value):
		f = value
		calc_curve_points()
@export_range(0.001, 5, 0.001, "exp") var z:float = DEFAULT_Z:
	get:
		return z
	set(value):
		z = value
		calc_curve_points()
@export_range(-10, 10, 0.01) var r:float = DEFAULT_R:
	get:
		return r
	set(value):
		r = value
		calc_curve_points()
@export_range(0.5, 20, 0.5) var t_graph:float = 2.0:
	get:
		if !curve: return 2
		return curve.max_domain
	set(value):
		t_graph = value
		if curve:
			curve.clear_points()
			curve.max_domain = value
		calc_curve_points()
@export var curve:Curve = Curve.new():
	set(value):
		curve = value
		calc_curve_points()

func calc_curve_points() -> void:
	if (!curve): return
	curve.clear_points()
	curve.min_value = 0.0
	curve.max_value = 1.0

	var t:float = 0.0
	var t_end:float = clamp(curve.max_domain, 0, 20)
	var step:float = 1 / 60.0
	var dynamics = SecondOrderDynamics.new(f, z, r, 0.0)

	var x:float = 1.0
	while t < t_end:
		var y:float = dynamics.compute(t, x)
		curve.add_point(Vector2(t, y))
		if y < curve.min_value:
			curve.min_value = y
		elif y > curve.max_value:
			curve.max_value = y
		t += step
