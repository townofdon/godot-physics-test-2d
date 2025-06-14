@tool
extends EditorProperty

var graph: VizGraph = preload("res://addons/kinematics_viz/viz_graph.gd").new()

var stats: KinematicStats

const EPSILON = 0.00001

func _init() -> void:
	read_only = true
	add_child(graph)
	set_bottom_editor(graph)

func _ready() -> void:
	stats = get_edited_object()
	update_graph()
	if stats:
		if !stats.on_stats_changed.is_connected(update_graph):
			stats.on_stats_changed.connect(update_graph)

func _exit_tree() -> void:
	if stats:
		stats.on_stats_changed.disconnect(update_graph)

func update_graph() -> void:
	if !graph: return
	if !stats: return
	var data := calc_curve_points()
	graph.set_data(data)

func calc_curve_points() -> Dictionary:
	if !stats.domain: stats.domain = 2.0
	var points:Array[Vector2] = []
	var min := 0.0
	var max := 1.0
	var t_min := 0.0
	var t_max := 0.0

	var t:float = 0.0 # current t value of iteration
	var t_end:float = clamp(stats.domain, 0.5, 100)
	var step:float = 1 / 60.0
	var dynamics = SecondOrderDynamics.new(stats.f, stats.z, stats.r, 0.0)

	var x:float = 1.0
	while t < t_end:
		var y:float = dynamics.compute(t, x)
		points.append(Vector2(t, y))
		if y < min:
			min = y
			t_min = t
		elif y > max:
			max = y
			t_max = t
		t += step
	return {"points": points, "min": min, "max": max, "t_min": t_min, "t_max": t_max, "t_end": t_end}
