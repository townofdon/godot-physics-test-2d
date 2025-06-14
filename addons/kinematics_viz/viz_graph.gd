@tool
extends Control
class_name VizGraph

const PADDING := 50
const CIRCLE_SIZE := 3
const EPSILON = 0.00001

var COLOR_BG = Color.html("#1D2229")
var COLOR_DIM = Color.html("#253030")
var default_font : Font = ThemeDB.fallback_font;

var points:Array[Vector2] = []
var value_min:float = 0.0
var value_max:float = 1.0
var domain_max:float = 1.0

var c_dots: Color = Color.RED:
	set(value):
		c_dots = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(10, 500)
	queue_redraw()

func set_data(data: Dictionary) -> void:
	var points:Array[Vector2] = data["points"]
	var value_min:float = data["min"]
	var value_max:float = data["max"]
	var domain_max:float = data["t_end"]
	assert(points is Array[Vector2])
	assert(value_min is float)
	assert(value_max is float)
	assert(domain_max is float)
	self.points = points
	self.value_min = value_min
	self.value_max = value_max
	self.domain_max = domain_max
	queue_redraw()

func _draw() -> void:
	var rect := get_rect()
	# draw dot grid
	# 0 to 10
	for i in 11:
		for j in 11:
			var tx := (i / 10.0)
			var ty := (j / 10.0)
			var x = tx * (rect.size.x - CIRCLE_SIZE * 1.5 - PADDING * 2) + PADDING
			var y = ty * (rect.size.y - CIRCLE_SIZE * 2 - PADDING * 2) + PADDING
			draw_circle(Vector2(x + CIRCLE_SIZE, y + CIRCLE_SIZE), CIRCLE_SIZE, c_dots, true, -1, true)
	plot_horizontal_line(value_min, "%1.1f" % value_min, Color.TRANSPARENT)
	plot_horizontal_line(value_max, "%1.1f" % value_max, Color.TRANSPARENT)
	plot_horizontal_line(0.25, "", COLOR_DIM)
	plot_horizontal_line(0.5, "", COLOR_DIM)
	plot_horizontal_line(0.75, "", COLOR_DIM)
	plot_horizontal_line(0, "0", Color.DARK_MAGENTA)
	plot_horizontal_line(1, "1", Color.DARK_CYAN)
	plot_vertical_lines()
	plot_points()

func plot_horizontal_line(y_value:float, y_display: String, color: Color) -> void:
	var rect := get_rect()
	var t = 1 - clamp(inverse_lerp(value_min, value_max, y_value), 0, 1)
	const x0 = PADDING
	var x1 = rect.size.x - PADDING
	var y = t * (rect.size.y - PADDING * 2) + PADDING
	draw_line(Vector2(x0,y), Vector2(x1,y), color, 1, true)
	if !len(y_display): return
	var offset := len(y_display) - 1
	draw_rect(Rect2(Vector2(x0 - 50, y - 20), Vector2(48, 32)), COLOR_BG)
	draw_string(default_font, Vector2(x0 - 24 - 10 * offset,y + 6), y_display, HORIZONTAL_ALIGNMENT_RIGHT, -1, 24, Color.WHITE)

func plot_vertical_lines() -> void:
	var t = 0.0
	var min_x_next_label = 0.0
	while t <= max(domain_max, 0.5):
		min_x_next_label = plot_vertical_line(t, min_x_next_label)
		t += 0.5

func plot_vertical_line(time: float, min_x_next_label: float) -> float:
	var rect := get_rect()
	var is_major: bool = floor(time) == time
	const y0 = PADDING
	var y1 = rect.size.y - PADDING
	var t = time / max(domain_max, 0.5)
	var x = t * (rect.size.x - PADDING * 2) + PADDING
	var color := Color.DIM_GRAY
	if !is_major:
		color = Color.DARK_SLATE_GRAY
	draw_line(Vector2(x,y0), Vector2(x,y1), color, 1, true)

	# calc space needed to show the next label

	if x > min_x_next_label:
		draw_string(default_font, Vector2(x - 16,y1 + 32), "{0}".format([time]), HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)
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
		draw_line(a, b, Color.LIME, 2, true)

func vec_to_canvas_pos(vec: Vector2) -> Vector2:
	var rect := get_rect()
	var out := Vector2.ZERO
	var tx = vec.x / max(domain_max, 0.5)
	var ty = 1 - inverse_lerp(value_min, value_max, vec.y)
	out.x = tx * (rect.size.x - PADDING * 2) + PADDING
	out.y = ty * (rect.size.y - PADDING * 2) + PADDING
	return out
