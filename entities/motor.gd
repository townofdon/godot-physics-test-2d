extends Node2D
class_name Motor

@export var stats:KinematicStats

@onready var entity:Entity = get_parent()

enum Mode { Manual, Arrive }
const DEBUG := false

var mode := Mode.Manual
var input := Vector2.ZERO # move input
var destination := Vector2.ZERO # arrival destination
var throttle := 0.0
var top_speed_factor := 0.0
var dynamics:SecondOrderDynamics

var v_mom := Vector2.ZERO # velocity contribution from faux momentum
var v_kin := Vector2.ZERO # velocity contribution from kinematics calculations

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

func _process(_delta: float) -> void:
	if !DEBUG: return
	queue_redraw()

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
	var desired_speed:float = lerp(stats.speed, stats.top_speed, top_speed_factor)
	var desired_velocity := input * throttle * desired_speed
	v_kin = dynamics.compute(delta, stats.constants, desired_velocity)
	v_mom = lerp(entity.velocity, Vector2.ZERO, stats.drag)
	if mode == Mode.Manual:
		# Determine momentum's contribution to velocity.
		# Remove the "v_kin component" — v_kin projected onto v_mom.
		var v2_mom := v_mom - utils.project(v_kin, v_mom)
		if v2_mom.dot(v_mom) < 0: v2_mom = Vector2.ZERO
		if v2_mom.length_squared() > v_mom.length_squared(): v2_mom = v_mom
		var mom_alignment := utils.dot01(input, v_mom)
		v2_mom = lerp(v2_mom * 0.95 * clamp(1 - stats.handling, 0, 1), v2_mom, mom_alignment)
		# we want to blend between velocity when input is received vs. no input
		var velocity_input := v_kin + v2_mom
		var velocity_no_input := v_mom
		entity.velocity = lerp(velocity_no_input, velocity_input, clamp(input.length() * throttle, 0, 1))
	elif mode == Mode.Arrive:
		entity.velocity = v_kin * arrival
		var has_arrived := arrival <= Constants.EPSILON
		if has_arrived: mode = Mode.Manual

	# set state for next frame
	input = Vector2.ZERO

func _draw() -> void:
	if !DEBUG: return
	var a := entity.velocity
	var b := v_kin
	var c := v_mom
	var d := input * 50
	debug_velocity(a, Color.YELLOW, 6)
	debug_velocity(b, Color.RED, 1, Vector2(1, 1) * 10)
	debug_velocity(c, Color.DARK_MAGENTA, 2, Vector2(-1, -1) * 10)
	debug_velocity(d, Color.LIME_GREEN, 1)

func debug_velocity(vel:Vector2, color:Color, width:float = 2.0, offset = Vector2.ZERO) -> void:
	draw_line(Vector2.ZERO + offset, vel * 2 + offset, color, width, true)
