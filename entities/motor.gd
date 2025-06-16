extends Node2D
class_name Motor

# sets velocity per frame
# controls acceleration
# controls rotation
# exposes methods:
# - moveTo(point)
# - move(direction, strength = 1)
@export var stats:KinematicStats

@onready var entity:Entity = get_parent()

enum Mode { Manual, Arrive }

var mode := Mode.Manual
var input := Vector2.ZERO # move input
var destination := Vector2.ZERO # arrival destination
var throttle := 0.0
var dynamics:SecondOrderDynamics

var v_mom := Vector2.ZERO # velocity contribution from faux momentum
var v_kin := Vector2.ZERO # velocity contribution from kinematics calculations

## Call this when the entity collides with something.
func reset_forces() -> void:
	dynamics = SecondOrderDynamics.new(entity.velocity)

func _ready() -> void:
	process_priority = -10
	assert(!!stats, "KinematicStats unassigned in " + utils.full_name(self))
	assert(entity is Entity)
	assert(stats is KinematicStats)
	dynamics = SecondOrderDynamics.new(entity.velocity)

func _process(_delta: float) -> void:
	queue_redraw()

var wait := Constants.DEBUG_WAIT_FRAMES
func _physics_process(delta: float) -> void:
	if !entity: return
	if !stats: return
	if wait < Constants.DEBUG_WAIT_FRAMES:
		wait += 1
		return
	wait = 0

	# prepare input
	var arrival: float = 0.0
	if mode == Mode.Arrive:
		var vector_to_point:Vector2 = destination - self.global_position
		self.input = vector_to_point.normalized()
		arrival = clamp(vector_to_point.length() / max(entity.arrive_distance, 0.1), 0, 1)
		if entity.arrival_curve:
			arrival = clamp(entity.arrival_curve.sample_baked(arrival), 0, 1)
	var has_input := !input.is_zero_approx()

	# set throttle based on input
	if has_input:
		throttle += delta / max(stats.throttle_up_time, 0.01)
	else:
		throttle -= delta / max(stats.throttle_down_time, 0.01)
	throttle = clamp(throttle, 0, 1)

	# calc new velocity
	var desired_velocity := input * throttle * entity.speed
	v_kin = dynamics.compute(delta, stats.constants, desired_velocity)
	v_mom = lerp(entity.velocity, Vector2.ZERO, stats.drag)
	if mode == Mode.Manual:
		# we want to blend between velocity when input is received vs. no input
		#var velocity_input := Vector2.ZERO
		#var velocity_no_input := Vector2.ZERO
		## We already have the main new velocity.
		## Now, compute how much additional velocity is contributed by momentum.
		## Basically, determine how much force to apply orthogonal to the input vector.
		## d_velocity (drag velocity) can be manipulated to simulate better vehicle handling.
		#var delta_towards_old_v := entity.velocity - k_velocity
		## FIXME: THERE'S A BUG WHERE FLYING IN A FIGURE-8 RESULTS IN SUDDEN STOPS.
		#d_velocity = utils.project(delta_towards_old_v, input.orthogonal())
		#d_velocity = lerp(d_velocity, Vector2.ZERO, stats.drag)

		## Any contribution of k_vel towards momentum needs to be subtracted from d_vel.
		## If the resulting difference is negative (backwards), ignore it.
		## let v = velocity
		## let v2 = k_vel projected onto vel
		## let v3 = v - v2
		## if |v3| < 0, set v3 to zero
		#d_velocity = entity.velocity - utils.project(k_velocity, entity.velocity)
		#if d_velocity.dot(entity.velocity) < 0: d_velocity = Vector2.ZERO
		#d_velocity = lerp(d_velocity, Vector2.ZERO, stats.drag)

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
		entity.velocity = lerp(velocity_no_input, velocity_input, clamp(input.length(), 0, 1))
	elif mode == Mode.Arrive:
		entity.velocity = v_kin * arrival
		var has_arrived := arrival <= Constants.EPSILON
		if has_arrived: mode = Mode.Manual

	#print(entity.velocity, v_kin, v_mom)

	# set state for next frame
	input = Vector2.ZERO

func _draw() -> void:
	#debug_velocity(velocity, Color.RED)
	#debug_velocity(velocity * drag_factor, Color.YELLOW)
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
