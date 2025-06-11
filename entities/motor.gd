extends Node
class_name Motor

# sets velocity per frame
# controls acceleration
# controls rotation
# exposes methods:
# - moveTo(point)
# - move(direction, strength = 1)
@export var dynamics:SecondOrderDynamics

@onready var entity:Entity = get_parent()

var throttle:float = 0.0 # value between [0-1]
var arrival:float = 0.0 # value between [0-1]
var direction := Vector2.ZERO
var time_since_move := INF

func _ready() -> void:
	process_priority = -10
	assert(entity is Entity)
	assert(entity.accel_time > 0, "accel_time must be positive and non-zero for " + utils.full_name(self))
	assert(entity.decel_time > 0, "decel_time must be positive and non-zero for " + utils.full_name(self))

func _physics_process(delta: float) -> void:
	if time_since_move >= 0.5:
		throttle -= delta / entity.accel_time
	time_since_move += delta
	if (!direction):
		direction = entity.velocity.normalized()
	var strength:float = clamp(throttle, 0, 1)
	if entity.accel_curve:
		strength = entity.accel_curve.sample_baked(clamp(throttle, 0, 1))
	if arrival > 0:
		strength *= 1 - clamp(arrival, 0, 1)
	strength = clamp(strength, 0, 1)
	entity.velocity = entity.speed * strength * direction

# call every _physics_process
func move(delta: float, direction: Vector2, strength: float = 1) -> void:
	throttle += delta / entity.accel_time
	time_since_move = 0
	arrival = 0
	self.direction = direction

# call every _physics_process
func move_to(delta: float, point: Vector2) -> void:
	var vector_to_point:Vector2 = point - self.global_position
	throttle += delta / entity.accel_time
	time_since_move = 0
	arrival = clamp(vector_to_point.length() / entity.arrive_distance, 0, 1)
	if entity.arrival_curve:
		arrival = entity.arrival_curve.sample_baked(clamp(arrival, 0, 1))
	self.direction = vector_to_point.normalized()
