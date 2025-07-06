extends Node2D
class_name Motor

@export var stats:KinematicStats

@onready var entity:Entity = get_parent()

enum Mode { Manual, Arrive }

const ROTATION_CARDINALITY := 45;

var mode := Mode.Manual
var input := Vector2.ZERO # move input
var destination := Vector2.ZERO # arrival destination
var velocity := Vector2.ZERO
var throttle := 0.0
var top_speed_factor := 0.0
var accel:SecondOrderDynamics

var spin_velocity := 0.0 # rotation speed
var spin_input := 0.0 # rotation input [-1, 1]
var spin_target := INF # rotation target (degrees) - INF => no target
var spin_accel:SecondOrderDynamics

## Call this when the entity collides with something.
func reset_forces() -> void:
	if entity: velocity = entity.velocity
	accel = SecondOrderDynamics.new(velocity)
	spin_accel = SecondOrderDynamics.new(spin_velocity)

# call every _physics_process
func move(input: Vector2) -> void:
	self.input += input
	if self.input.length() > 1:
		self.input = self.input.normalized()
	mode = Mode.Manual

# call once
func move_to(point: Vector2) -> void:
	destination = point
	mode = Mode.Arrive

# call every _physics_process
func spin(direction: float) -> void:
	spin_input = clamp(direction, -1.0, 1.0)
	spin_target = INF

# call once
func spin_to(desired_angle: float) -> void:
	spin_target = desired_angle

func _ready() -> void:
	process_priority = -10
	if entity:
		assert(entity is Entity)
		velocity = entity.velocity
	assert(!!stats, "motor must have Entity as a parent: " + utils.full_name(self))
	assert(!!stats, "KinematicStats unassigned in " + utils.full_name(self))
	assert(stats is KinematicStats)
	accel = SecondOrderDynamics.new(velocity)
	spin_accel = SecondOrderDynamics.new(spin_velocity)

func _physics_process(delta: float) -> void:
	if !stats: return

	if entity: velocity = entity.velocity

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
		throttle += utils.lerpd(throttle, 1.0, stats.throttle_up_speed, delta)
	else:
		throttle -= delta / max(stats.throttle_down_time, 0.01)
	throttle = clamp(throttle, 0, 1)

	# handle top speed
	if velocity.length_squared() > stats.speed * stats.speed * 0.75:
		top_speed_factor = utils.lerpd(top_speed_factor, 1.0, stats.top_speed_growth, delta)
	else:
		top_speed_factor = 0

	# calc new velocity
	var desired_speed:float = lerpf(stats.speed, max(stats.speed, stats.top_speed), top_speed_factor)
	var desired_velocity := throttle * desired_speed * input
	var momentum = utils.lerpdv2(velocity, Vector2.ZERO, stats.drag, delta)
	var momentum_alignment:float = utils.dotnorm(momentum, desired_velocity)
	if momentum_alignment < 0: momentum_alignment = momentum_alignment * -0.25
	momentum_alignment = clamp(momentum_alignment, 0.1, 0.85)
	var sluggishness:Vector2 = momentum.lerp(desired_velocity, momentum_alignment)
	desired_velocity = sluggishness.lerp(desired_velocity, stats.handling)
	var v_calc = accel.compute(delta, stats.accel_constants, desired_velocity, velocity)
	if mode == Mode.Manual:
		velocity = momentum.lerp(v_calc, clamp(input.length() * throttle, 0, 1))
	elif mode == Mode.Arrive:
		velocity = v_calc * arrival
		var has_arrived := arrival <= Constants.EPSILON
		if has_arrived: mode = Mode.Manual

	# calc rotation
	if is_zero_approx(spin_input) && stats.enforce_cardinality:
		spin_target = get_cardinal_angle(entity.rotation_degrees)
	if spin_target != INF:
		var desired_angle := spin_target
		var current_angle := entity.rotation_degrees
		var angle_error := calc_angle_difference(desired_angle, current_angle)
		spin_input = inverse_lerp(0, stats.rotation_speed, abs(angle_error))
		spin_input = clamp(spin_input, 0.0, 1.0)
		spin_input = Easing.Cubic.EaseOut(spin_input, 0, 1, 1)
		spin_input = sign(angle_error) * spin_input
		if is_zero_approx(angle_error): spin_target = INF
	var mag_velocity = clamp(velocity.length() / stats.top_speed, 0, 1)
	var target_spin_speed: float = spin_input * stats.rotation_speed * lerpf(stats.rotation_limit_at_speed, 1.0, 1.0 - mag_velocity)
	spin_velocity = spin_accel.compute(delta, stats.rotation_constants, target_spin_speed, spin_velocity)

	# update entity
	if entity:
		entity.rotate(deg_to_rad(spin_velocity * delta))
		entity.velocity = velocity

	# set state for next frame
	input = Vector2.ZERO
	spin_input = 0.0

## calculate modular difference, and remap to [-180, 180]
func calc_angle_difference(a: float, b: float) -> float:
	return fmod(a - b + 540.0, 360.0) - 180.0

## get angle with cardinality applied
func get_cardinal_angle(angle: float) -> float:
	if !stats.enforce_cardinality:
		return angle
	return roundf(angle / ROTATION_CARDINALITY) * ROTATION_CARDINALITY
