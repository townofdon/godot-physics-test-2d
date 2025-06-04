extends Node2D
class_name Gameplay

@export var camera_move_speed := 100
@export var camera_zoom_speed := Vector2(1, 1)
@onready var red = preload("res://entities/RedBall.tscn")
@onready var blue = preload("res://entities/BlueBall.tscn")
@onready var camera = $Camera2D
@onready var marker_center = $marker_center
@onready var marker_pos = $marker_pos

func _ready() -> void:
	camera.position = get_viewport_rect().get_center()

func _process(delta: float) -> void:
	var pos:Vector2 = (get_viewport().get_mouse_position() - get_viewport_rect().get_center()) / camera.zoom.x + camera.global_position
	var center:Vector2 = camera.global_position

	marker_center.global_position = center
	marker_pos.global_position = pos

	var mouse_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var shift_pressed := Input.is_action_pressed("shift")
	if mouse_down:
		var node: Entity
		if (shift_pressed):
			node = blue.instantiate()
		else:
			node = red.instantiate()
		self.add_child(node)
		var direction:Vector2 = (center - pos).normalized()
		node.global_position = pos
		node.direction = direction
		node.velocity = node.speed * node.direction

	# move camera
	var camera_direction := Vector2.ZERO
	if Input.is_action_pressed("up"):
		camera_direction += Vector2.UP
	if Input.is_action_pressed("down"):
		camera_direction += Vector2.DOWN
	if Input.is_action_pressed("left"):
		camera_direction += Vector2.LEFT
	if Input.is_action_pressed("right"):
		camera_direction += Vector2.RIGHT
	if Input.is_action_pressed("zoom_in"):
		camera.zoom = camera.zoom + camera_zoom_speed * delta
	elif Input.is_action_pressed("zoom_out"):
		camera.zoom = camera.zoom - camera_zoom_speed * delta
		camera.zoom.x = max(camera.zoom.x, 0.1)
		camera.zoom.y = max(camera.zoom.y, 0.1)
	camera.position = camera.position + camera_direction * camera_move_speed * delta / camera.zoom
