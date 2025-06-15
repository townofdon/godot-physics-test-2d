extends Node
class_name utils

static func full_name(node: Node) -> String:
	var out := ""
	var current := node
	while current:
		out = current.name + "." + out
		current = current.get_parent()
	return out

## get the result of projecting a onto b (a'), then returning a' -> a
static func ortho_project(a:Vector2, b:Vector2) -> Vector2:
	if a.is_zero_approx() || b.is_zero_approx():
		return Vector2.ZERO
	var projection := a.project(b)
	var normal := a - projection
	if is_nan(normal.x) || is_nan(normal.y):
		return Vector2.ZERO
	return normal

## Project a onto b. Result is parallel to b.
static func project(a:Vector2, b:Vector2) -> Vector2:
	if a.is_zero_approx() || b.is_zero_approx():
		return Vector2.ZERO
	var projection := a.project(b)
	if is_nan(projection.x) || is_nan(projection.y):
		return Vector2.ZERO
	return projection
