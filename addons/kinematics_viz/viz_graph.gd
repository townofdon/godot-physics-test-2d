@tool
extends Control
class_name VizGraph

const PADDING := 60
const CIRCLE_SIZE := 3

var COLOR_BG = Color.html("#1D2229")
var COLOR_DIM = Color.html("#253030")
var default_font : Font = ThemeDB.fallback_font;

var points:Array[Vector2] = []
var value_min:float = 0.0
var value_max:float = 1.0
var t_min:float = 0.0
var t_max:float = 0.0
var domain:float = 1.0

var mouse_pos:Vector2 = Vector2.ZERO
var is_mouse_in_graph:bool = false

func _init() -> void:
	custom_minimum_size = Vector2(10, 400)
	queue_redraw()

func _process(delta: float) -> void:
	# check mouse position
	if Engine.is_editor_hint():
		var rect := get_rect()
		var pos := get_local_mouse_position()
		var prev_mouse_pos := mouse_pos
		mouse_pos.x = inverse_lerp(PADDING, rect.size.x - PADDING, pos.x)
		mouse_pos.y = 1 - inverse_lerp(PADDING, rect.size.y - PADDING, pos.y)
		is_mouse_in_graph = true
		if mouse_pos.x <= 0 || mouse_pos.y <= 0 || mouse_pos.x >= 1 || mouse_pos.y >= 1:
			mouse_pos = Vector2.ZERO
			is_mouse_in_graph = false
		var did_change:bool = !prev_mouse_pos.is_equal_approx(mouse_pos)
		if did_change:
			queue_redraw()

func set_data(data: Dictionary) -> void:
	var points:Array[Vector2] = data["points"]
	var value_min:float = data["min"]
	var value_max:float = data["max"]
	var t_min:float = data["t_min"]
	var t_max:float = data["t_max"]
	var domain:float = data["t_end"]
	assert(points is Array[Vector2])
	assert(value_min is float)
	assert(value_max is float)
	assert(t_min is float)
	assert(t_max is float)
	assert(domain is float)
	self.points = points
	self.value_min = value_min
	self.value_max = value_max
	self.t_min = t_min
	self.t_max = t_max
	self.domain = max(domain, 0.5)
	queue_redraw()

func _draw() -> void:
	var rect := get_rect()
	var resolution:String = "%1.1f"
	if domain <= 0.5 + Constants.EPSILON:
		resolution = "%1.2f"
	if is_mouse_in_graph:
		var mouse_x := mouse_pos.x * domain
		var mouse_y := lerp(value_min, value_max, mouse_pos.y)
		plot_horizontal_line(mouse_y, "%1.2f" % mouse_y, Color.DIM_GRAY, Color.LIGHT_SLATE_GRAY)
		plot_vertical_line(mouse_x, 0, "%1.2f" % mouse_x, Color.DIM_GRAY, Color.LIGHT_SLATE_GRAY, PADDING - 20)
	plot_horizontal_line(value_min, "%1.1f" % value_min, Color.TRANSPARENT, Color.AQUAMARINE)
	plot_horizontal_line(value_max, "%1.1f" % value_max, Color.TRANSPARENT, Color.AQUAMARINE)
	plot_horizontal_line(0.25, "", COLOR_DIM)
	plot_horizontal_line(0.5, "", COLOR_DIM)
	plot_horizontal_line(0.75, "", COLOR_DIM)
	if t_min > 0 && (resolution % t_min != "0.0"):
		plot_vertical_line(t_min, 0, resolution % t_min, Color.DARK_MAGENTA, Color.DARK_ORCHID, PADDING - 20)
	if t_max > 0:
		plot_vertical_line(t_max, 0, resolution % t_max, Color.DARK_CYAN, Color.DARK_CYAN, PADDING - 20)
	plot_horizontal_line(0, "0", Color.DARK_MAGENTA)
	plot_horizontal_line(1, "1", Color.DARK_CYAN)
	plot_vertical_lines()
	plot_points()

func plot_horizontal_line(y_value:float, y_display: String, color: Color, text_color: Color = Color.WHITE) -> void:
	var rect := get_rect()
	var t = 1 - clamp(inverse_lerp(value_min, value_max, y_value), 0, 1)
	const x0 = PADDING
	var x1 = rect.size.x - PADDING
	var y = t * (rect.size.y - PADDING * 2) + PADDING
	draw_line(Vector2(x0,y), Vector2(x1,y), color, 1, true)
	if !len(y_display): return
	var offset:float = min(len(y_display), 4) - 1
	var text_x:float = 0.0
	draw_rect(Rect2(Vector2(x0 - 50, y - 20), Vector2(48, 32)), COLOR_BG)
	draw_string(default_font, Vector2(x0 - 24 - 10 * offset,y + 6), y_display, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, text_color)

func plot_vertical_lines() -> void:
	var t = 0.0
	var min_x_next_label = 0.0
	while t <= domain:
		var is_major: bool = floor(t) == t
		var color := Color.DIM_GRAY
		if !is_major:
			color = Color.DARK_SLATE_GRAY
		var label := "%1.1f" % t
		if is_major:
			label = "%1.0f" % t
		min_x_next_label = plot_vertical_line(t, min_x_next_label, label, color)
		t += 0.5

func plot_vertical_line(time: float, min_x_next_label: float, label: String, color: Color, color_text: Color = Color.WHITE, override_text_y: float = 0) -> float:
	var rect := get_rect()
	var is_major: bool = floor(time) == time
	const y0 = PADDING
	var y1 := rect.size.y - PADDING
	var t:float = time / domain
	var x:float = t * (rect.size.x - PADDING * 2) + PADDING
	draw_line(Vector2(x,y0), Vector2(x,y1), color, 1, true)
	var offset := len(label) - 1
	if len(label) && x > min_x_next_label:
		var text_y := y1 + 32
		if override_text_y: text_y = override_text_y
		draw_string(default_font, Vector2(x - 7 - 5 * offset, text_y), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, color_text)
		return x + 60
	return min_x_next_label

func plot_points() -> void:
	if (!points || len(points) == 0): return
	var point:Vector2
	var prev:Vector2 = Vector2.ZERO
	for i in len(points):
		prev = point
		point = points[i]
		if i==0: continue
		var a := vec_to_canvas_pos(prev)
		var b := vec_to_canvas_pos(point)
		draw_line(a, b, Color.AQUAMARINE, 2, true)

func vec_to_canvas_pos(vec: Vector2) -> Vector2:
	var rect := get_rect()
	var out := Vector2.ZERO
	var tx = vec.x / domain
	var ty = 1 - inverse_lerp(value_min, value_max, vec.y)
	out.x = tx * (rect.size.x - PADDING * 2) + PADDING
	out.y = ty * (rect.size.y - PADDING * 2) + PADDING
	return out
