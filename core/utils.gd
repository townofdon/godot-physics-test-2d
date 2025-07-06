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

## Get the normalized dot product between two vectors, mapped to [-1,1].
## -1 => vectors are pointing in opposite directions.
## 0  => vectors are orthogonal.
## 1  => vectors are pointing in exactly the same direction.
static func dotnorm(a:Vector2, b:Vector2) -> float:
	if a.is_zero_approx() || b.is_zero_approx():
		return 0.0
	return a.normalized().dot(b.normalized())

## Get the normalized dot product between two vectors, mapped to [0,1].
## 0 => vectors are pointing in opposite directions.
## 1 => vectors are pointing in exactly the same direction.
static func dot01(a:Vector2, b:Vector2) -> float:
	if a.is_zero_approx() || b.is_zero_approx():
		return 0.0
	return (a.normalized().dot(b.normalized()) + 1) * 0.5

## lerp a float (type-safe!). Use Vector2.lerp for lerping a vec
static func lerpf(a: float, b: float, t: float) -> float:
	return lerp(a, b, t)

## Lerp float with framerate independence using exponential decay
static func lerpd(a: float, b: float, t: float, delta: float) -> float:
	return lerp(a, b, 1 - exp(-t * delta))

## Lerp Vec2 with framerate independence using exponential decay
static func lerpdv2(a: Vector2, b: Vector2, t: float, delta: float) -> Vector2:
	return lerp(a, b, 1 - exp(-t * delta))
