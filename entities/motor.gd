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

var wait := Constants.DEBUG_WAIT_FRAMES
func _physics_process(delta: float) -> void:
	if wait < Constants.DEBUG_WAIT_FRAMES:
		wait += 1
		return
	wait = 0

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
	var desired_velocity := throttle * desired_speed * input
	var momentum = lerp(entity.velocity, Vector2.ZERO, stats.drag)
	var momentum_alignment:float = utils.dotnorm(momentum, desired_velocity)
	if momentum_alignment < 0: momentum_alignment = momentum_alignment * -0.25
	momentum_alignment = clamp(momentum_alignment, 0.1, 0.85)
	var sluggishness:Vector2 = lerp(momentum, desired_velocity, momentum_alignment)
	desired_velocity = lerp(sluggishness, desired_velocity, stats.handling)
	var v_calc = dynamics.compute(delta, stats.constants, desired_velocity)
	if mode == Mode.Manual:
		## Determine momentum's contribution to velocity.
		## Remove the "v_calc component" — v_calc projected onto v_mom.
		#var v2_mom := v_mom - utils.project(v_calc, v_mom)
		#if v2_mom.dot(v_mom) < 0: v2_mom = Vector2.ZERO
		#if v2_mom.length_squared() > v_mom.length_squared(): v2_mom = v_mom
		#var mom_alignment := utils.dot01(input, v_mom)
		#v2_mom = lerp(v2_mom * 0.9999 * clamp(1 - stats.handling, 0, 1), v2_mom, mom_alignment)
		## we want to blend between velocity when input is received vs. no input
		#entity.velocity = lerp(v_mom, v_calc + v_mom, clamp(input.length() * throttle, 0, 1))

		# Blend the contributions of v_calc and v_mom to the velocity.
		#var v2_kin := utils.project(v_calc, input)
		#if v2_kin.dot(input) < 0: v2_kin = Vector2.ZERO
		#var v2_mom := utils.project(v_mom, input)
		#v2_kin = v2_kin - utils.project(v_mom, v2_kin)
		#if v2_kin.dot(v_calc) < 0: v2_kin = Vector2.ZERO
		#if v2_kin.length_squared() > v_calc.length_squared(): v2_kin = v_calc
		#var v2_mom := v_mom - utils.project(v2_kin, v_mom)
		#if v2_mom.dot(v_mom) < 0: v2_mom = Vector2.ZERO
		#if v2_mom.length_squared() > v_mom.length_squared(): v2_mom = v_mom
		#v2_kin = v2_kin + v2_mom
		#v2_kin = lerp(v2_kin, v_calc, stats.handling)

		#entity.velocity = lerp(v2_kin + v_mom, v_calc, stats.handling)
		entity.velocity = lerp(momentum, v_calc, clamp(input.length() * throttle, 0, 1))
	elif mode == Mode.Arrive:
		entity.velocity = v_calc * arrival
		var has_arrived := arrival <= Constants.EPSILON
		if has_arrived: mode = Mode.Manual

	# set state for next frame
	input = Vector2.ZERO

func _draw() -> void:
	if !DEBUG: return
	var a := entity.velocity
	#var b := sluggishness
	#var c := momentum
	var d := input * 50
	debug_velocity(a, Color.YELLOW, 6)
	#debug_velocity(b, Color.BLUE, 1, Vector2(1, 1) * 10)
	#debug_velocity(c, Color.DARK_MAGENTA, 2, Vector2(-1, -1) * 10)
	debug_velocity(d, Color.LIME_GREEN, 1)

func debug_velocity(vel:Vector2, color:Color, width:float = 2.0, offset = Vector2.ZERO) -> void:
	draw_line(Vector2.ZERO + offset, vel * 2 + offset, color, width, true)
