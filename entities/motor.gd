extends Node
class_name Motor

# sets velocity per frame
# controls acceleration
# controls rotation
# exposes methods:
# - moveTo(point)
# - move(direction, strength = 1)
@export var kinematic_stats:KinematicStats

@onready var entity:Entity = get_parent()

#var throttle:float = 0.0 # value between [0-1]
#var arrival:float = 0.0 # value between [0-1]
#var direction := Vector2.ZERO

var dynamics:SecondOrderDynamics
var drag:SecondOrderDynamics
var throttle := Vector2.ZERO # move input

func _ready() -> void:
	process_priority = -10
	assert(entity is Entity)
	assert(entity.accel_time > 0, "accel_time must be positive and non-zero for " + utils.full_name(self))
	assert(entity.decel_time > 0, "decel_time must be positive and non-zero for " + utils.full_name(self))
	var f := KinematicStats.DEFAULT_F
	var z := KinematicStats.DEFAULT_Z
	var r := KinematicStats.DEFAULT_R
	if (kinematic_stats):
		f = kinematic_stats.f
		z = kinematic_stats.z
		r = kinematic_stats.r
	dynamics = SecondOrderDynamics.new(f, z, r, Vector2.ZERO)

func _physics_process(delta: float) -> void:
	if self.throttle.length() > 1:
		self.throttle = self.throttle.normalized()
	if throttle.is_zero_approx():
		if drag == null:
			drag = SecondOrderDynamics.new(0.6, 1, 0, entity.velocity)
		entity.velocity = drag.compute(delta, Vector2.ZERO)
		# compute dynamics to continue the system
		dynamics.compute(delta, Vector2.ZERO)
	else:
		var desired_velocity := throttle * entity.speed
		entity.velocity = dynamics.compute(delta, desired_velocity)
		drag = null
	throttle = Vector2.ZERO


	#if time_since_move >= 0.5:
		#throttle -= delta / entity.accel_time
	#time_since_move += delta
	#if (!direction):
		#direction = entity.velocity.normalized()
	#var strength:float = clamp(throttle, 0, 1)
	#if entity.accel_curve:
		#strength = entity.accel_curve.sample_baked(clamp(throttle, 0, 1))
	#if arrival > 0:
		#strength *= 1 - clamp(arrival, 0, 1)
	#strength = clamp(strength, 0, 1)
	#entity.velocity = entity.speed * strength * direction

# call every _physics_process
func move(delta: float, throttle: Vector2) -> void:
	self.throttle += throttle

	#time_since_move = 0
	#throttle += delta / entity.accel_time
	#arrival = 0
	#self.direction = direction

# call every _physics_process
func move_to(delta: float, point: Vector2) -> void:
	pass
	#time_since_move = 0
	#var vector_to_point:Vector2 = point - self.global_position
	#throttle += delta / entity.accel_time
	#arrival = clamp(vector_to_point.length() / entity.arrive_distance, 0, 1)
	#if entity.arrival_curve:
		#arrival = entity.arrival_curve.sample_baked(clamp(arrival, 0, 1))
	#self.direction = vector_to_point.normalized()
