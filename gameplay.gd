extends Node2D
class_name Gameplay

@onready var red = preload("res://entities/RedBall.tscn")
@onready var blue = preload("res://entities/BlueBall.tscn")

func _input(event):
	if event is InputEventMouseButton && event.pressed:		
		var node: Entity
		var direction: Vector2
		if (event.shift_pressed):
			node = blue.instantiate()
			direction = Vector2.LEFT
		else:
			node = red.instantiate()
			direction = Vector2.RIGHT
		self.get_parent().add_child(node)
		node.global_position = event.position
		node.direction = direction
		node.velocity = node.speed * node.direction
