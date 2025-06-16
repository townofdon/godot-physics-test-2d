@tool
extends EditorProperty

var Graph = preload("res://addons/kinematics_viz/viz_graph.gd")
var graph_kine: VizGraph = Graph.new()
var graph_drag: VizGraph = Graph.new()
var graph_throttle: VizGraph = Graph.new()
var label_kine: Label = Label.new()
var label_drag: Label = Label.new()
var label_throttle: Label = Label.new()
var container:Container = VBoxContainer.new()

var stats: KinematicStats

func _init() -> void:
	read_only = true
	if (!container): container = VBoxContainer.new()
	if (!label_kine): label_kine = Label.new()
	if (!label_drag): label_drag = Label.new()
	if (!label_throttle): label_throttle = Label.new()
	setup_label(label_kine, "Kinematic Curve")
	setup_label(label_drag, "Drag Response")
	setup_label(label_throttle, "Throttle Up Response")
	add_child(container)
	container.add_child(label_kine)
	container.add_child(graph_kine)
	container.add_child(label_drag)
	container.add_child(graph_drag)
	container.add_child(label_throttle)
	container.add_child(graph_throttle)
	set_bottom_editor(container)

func setup_label(label: Label, text: String) -> void:
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
	if !graph_kine: return
	if !stats: return
	graph_kine.set_data(calc_kinematic_curve_data())
	graph_drag.set_data(calc_drag_curve_data())
	graph_throttle.set_data(calc_throttle_up_curve_data())

func calc_kinematic_curve_data() -> Dictionary:
	if !stats.domain: stats.domain = 2.0
	var points:Array[Vector2] = []
	var min := 0.0
	var max := 1.0
	var t_min := 0.0
	var t_max := 0.0
	var t:float = 0.0 # current t value of iteration
	var t_end:float = clamp(stats.domain, 0.5, 100)
	var step:float = 1 / 60.0
	var dynamics = SecondOrderDynamics.new(0.0)
	# add first point
	points.append(Vector2(t, 0))
	t += step
	# iterate dynamics and add remaining points
	var x:float = 1.0
	while t < t_end:
		var y:float = dynamics.compute(t, stats.constants, x)
		points.append(Vector2(t, y))
		if y < min:
			min = y
			t_min = t
		elif y > max:
			max = y
			t_max = t
		t += step
	return {"points": points, "min": min, "max": max, "t_min": t_min, "t_max": t_max, "t_end": t_end}

func calc_drag_curve_data() -> Dictionary:
	var points:Array[Vector2] = []
	var min := 0.0
	var max := 1.0
	var t_min := 0.0
	var t_max := 0.0
	var t_end:float = clamp(stats.domain, 0.5, 100)
	var t:float = 0.0 # current t value of iteration
	var step:float = 1 / 60.0
	# add first point
	var y:float = 1.0
	points.append(Vector2(t, y))
	t += step
	# iterate remaining points
	while t < t_end:
		y = lerp(y, 0.0, stats.drag)
		points.append(Vector2(t, y))
		if y < min:
			min = y
			t_min = t
		elif y > max:
			max = y
			t_max = t
		t += step
	return {"points": points, "min": min, "max": max, "t_min": t_min, "t_max": t_max, "t_end": t_end}

func calc_throttle_up_curve_data() -> Dictionary:
	var points:Array[Vector2] = []
	var min := 0.0
	var max := 1.0
	var t_min := 0.0
	var t_max := 0.0
	var t_end:float = clamp(stats.domain, 0.5, 100)
	var t:float = 0.0 # current t value of iteration
	var step:float = 1 / 60.0
	# add first point
	var y:float = 0.0
	points.append(Vector2(t, y))
	t += step
	# iterate remaining points
	while t < t_end:
		y = lerp(y, 1.0, stats.throttle_up_speed)
		points.append(Vector2(t, y))
		if y < min:
			min = y
			t_min = t
		elif y > max:
			max = y
			t_max = t
		t += step
	return {"points": points, "min": min, "max": max, "t_min": t_min, "t_max": t_max, "t_end": t_end}
