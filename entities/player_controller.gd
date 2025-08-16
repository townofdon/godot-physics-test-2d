extends Node
class_name PlayerController

func on_physics_process(motor:Motor, delta: float) -> void:
	assert(motor, "motor required in node: " + utils.full_name(self))

	# TODO: ADD GAMEPAD SUPPORT
	# TODO: ADD MULTIPLAYER SUPPORT
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
