extends Node
class_name PlayerController

@onready var motor:Motor = %Motor

func _ready() -> void:
	assert(motor is Motor)
	process_priority = -20

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("up"):
		motor.move(delta, Vector2.UP)
	if Input.is_action_pressed("down"):
		motor.move(delta, Vector2.DOWN)
	if Input.is_action_pressed("left"):
		motor.move(delta, Vector2.LEFT)
	if Input.is_action_pressed("right"):
		motor.move(delta, Vector2.RIGHT)
