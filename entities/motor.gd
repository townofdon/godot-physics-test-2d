extends Node2D
class_name Motor

@export var stats:KinematicStats

@onready var entity:Entity = get_parent()

enum Mode { Manual, Arrive }

var mode := Mode.Manual
var input := Vector2.ZERO # move input
var destination := Vector2.ZERO # arrival destination
var throttle := 0.0
var top_speed_factor := 0.0
var dynamics:SecondOrderDynamics

## Call this when the entity collides with something.
func reset_forces() -> void:
	dynamics = SecondOrderDynamics.new(entity.velocity)

# call every _physics_process
func move(delta: float, input: Vector2) -> void:
	self.input += input
	if self.input.length() > 1:
		self.input = self.input.normalized()
	mode = Mode.Manual

# call once
func move_to(point: Vector2) -> void:
	destination = point
	mode = Mode.Arrive

func _ready() -> void:
	process_priority = -10
	assert(!!stats, "motor must have Entity as a parent: " + utils.full_name(self))
	assert(!!stats, "KinematicStats unassigned in " + utils.full_name(self))
	assert(stats is KinematicStats)
	assert(entity is Entity)
	dynamics = SecondOrderDynamics.new(entity.velocity)

func _physics_process(delta: float) -> void:
	if !entity: return
	if !stats: return

	# prepare input
	var arrival: float = 0.0
	if mode == Mode.Arrive:
		var vector_to_point:Vector2 = destination - self.global_position
		self.input = vector_to_point.normalized()
		arrival = clamp(vector_to_point.length() / max(stats.arrive_distance, 0.1), 0, 1)
		if stats.arrival_curve:
			arrival = clamp(stats.arrival_curve.sample_baked(arrival), 0, 1)
	var has_input := !input.is_zero_approx()

	# set throttle based on input
	if has_input:
		throttle += lerp(throttle, 1.0, stats.throttle_up_speed)
	else:
		throttle -= delta / max(stats.throttle_down_time, 0.01)
	throttle = clamp(throttle, 0, 1)

	# handle top speed
	if entity.velocity.length_squared() > stats.speed * stats.speed * 0.9:
		top_speed_factor = lerp(top_speed_factor, 1.0, stats.top_speed_growth)
	else:
		top_speed_factor = 0

	# calc new velocity
	var desired_speed:float = lerp(stats.speed, max(stats.speed, stats.top_speed), top_speed_factor)
	var desired_velocity := throttle * desired_speed * input
	var momentum = lerp(entity.velocity, Vector2.ZERO, stats.drag)
	var momentum_alignment:float = utils.dotnorm(momentum, desired_velocity)
	if momentum_alignment < 0: momentum_alignment = momentum_alignment * -0.25
	momentum_alignment = clamp(momentum_alignment, 0.1, 0.85)
	var sluggishness:Vector2 = lerp(momentum, desired_velocity, momentum_alignment)
	desired_velocity = lerp(sluggishness, desired_velocity, stats.handling)
	var v_calc = dynamics.compute(delta, stats.constants, entity.velocity, desired_velocity)
	if mode == Mode.Manual:
		entity.velocity = lerp(momentum, v_calc, clamp(input.length() * throttle, 0, 1))
	elif mode == Mode.Arrive:
		entity.velocity = v_calc * arrival
		var has_arrived := arrival <= Constants.EPSILON
		if has_arrived: mode = Mode.Manual

	# set state for next frame
	input = Vector2.ZERO
