extends EditorProperty

# controls
var container_f = HBoxContainer.new()
var container_z = HBoxContainer.new()
var container_r = HBoxContainer.new()
var input_f = SpinBox.new()
var input_z = SpinBox.new()
var input_r = SpinBox.new()
var slider_f = HSlider.new()
var slider_z = HSlider.new()
var slider_r = HSlider.new()
var curve = Curve.new()

# state
var timer = Timer.new()
var dynamics:SecondOrderDynamics

func _init(dynamics:SecondOrderDynamics):
	self.dynamics = dynamics
	init_field(input_f, slider_f, dynamics.f, 0, 50, 0.1)
	init_field(input_z, slider_z, dynamics.z, 0, 5, 0.01)
	init_field(input_r, slider_r, dynamics.r, -2, 2, 0.01)
	# signals
	timer.wait_time = 0.1
	timer.timeout.connect(recalculate_dynamics)
	input_f.value_changed.connect(on_f_changed)
	input_z.value_changed.connect(on_z_changed)
	input_r.value_changed.connect(on_r_changed)
	slider_f.value_changed.connect(on_f_changed)
	slider_z.value_changed.connect(on_z_changed)
	slider_r.value_changed.connect(on_r_changed)
	# controls
	container_f.add_child(input_f)
	container_f.add_child(slider_f)
	container_z.add_child(input_z)
	container_z.add_child(slider_z)
	container_r.add_child(input_r)
	container_r.add_child(slider_r)
	add_child(container_f)
	add_child(container_z)
	add_child(container_r)
	add_focusable(input_f)
	add_focusable(input_z)
	add_focusable(input_r)
	add_child(curve)
	add_child(timer)
	# reset
	recalculate_dynamics()

func invalidate() -> void:
	if !timer.is_stopped(): return
	timer.start()

func recalculate_dynamics() -> void:
	timer.stop()
	dynamics.reset()
	calc_curve_points()
	emit_changed(get_edited_property(), dynamics)

func init_field(input:SpinBox, slider: HSlider, value:float, min:float, max:float, step:float = 0.01) -> void:
	input.value = value
	input.min_value = min
	input.max_value = max
	slider.value = value
	slider.min_value = min
	slider.max_value = max
	if step: slider.step = step

func on_f_changed(value:float) -> void:
	dynamics.f = value
	input_f.set_value_no_signal(value)
	slider_f.set_value_no_signal(value)
	invalidate()

func on_z_changed(value:float) -> void:
	dynamics.z = value
	input_z.set_value_no_signal(value)
	slider_z.set_value_no_signal(value)
	invalidate()

func on_r_changed(value:float) -> void:
	dynamics.r = value
	input_r.set_value_no_signal(dynamics.r)
	slider_r.set_value_no_signal(dynamics.r)
	invalidate()

func calc_curve_points() -> void:
	curve.clear_points()

	var t:float = 0.0
	var t_end:float = 2.0
	var step:float = 1 / 60.0

	if typeof(dynamics.x0) == TYPE_FLOAT:
		var x:float = 1.0
		while t < t_end:
			var y:float = dynamics.compute(t, x)
			curve.add_point(Vector2(t, y))
			t += step
	elif typeof(dynamics.x0) == TYPE_VECTOR2:
		var x:Vector2 = Vector2.ONE
		while t < t_end:
			var out:Vector2 = dynamics.compute(t, x)
			curve.add_point(Vector2(t, out.y))
			t += step
