extends Node
class_name PlayerController

@onready var motor:Motor = %Motor

func _ready() -> void:
	assert(motor is Motor)
	process_priority = -20

func _physics_process(delta: float) -> void:
	pass
