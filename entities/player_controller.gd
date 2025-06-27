extends Node
class_name PlayerController

@onready var motor:Motor = %Motor

func _ready() -> void:
	assert(motor is Motor)
	process_priority = -20

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_action_pressed("up"):
		input += Vector2.UP
	if Input.is_action_pressed("down"):
		input += Vector2.DOWN
	if Input.is_action_pressed("left"):
		input += Vector2.LEFT
	if Input.is_action_pressed("right"):
		input += Vector2.RIGHT
	motor.move(input)
	if Input.is_action_pressed("spin_right"):
		motor.spin(1)
	elif Input.is_action_pressed("spin_left"):
		motor.spin(-1)
