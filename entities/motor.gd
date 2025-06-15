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

var k_velocity := Vector2.ZERO # velocity calculated via kinematics
var d_velocity := Vector2.ZERO # drag velocity, or more accurate, momentum velocity that drag acts upon

func _ready() -> void:
	process_priority = -10
	assert(!!stats, "KinematicStats unassigned in " + utils.full_name(self))
	assert(entity is Entity)
	assert(stats is KinematicStats)
	dynamics = SecondOrderDynamics.new(Vector2.ZERO)

func _process(_delta: float) -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
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
		throttle += delta / max(entity.throttle_up_time, 0.01)
	else:
		throttle -= delta / max(entity.throttle_down_time, 0.01)
	throttle = clamp(throttle, 0, 1)

	# calc new velocity
	var desired_velocity := input * throttle * entity.speed
	k_velocity = dynamics.compute(delta, stats.constants, desired_velocity)
	if mode == Mode.Manual:
		# we want to blend between velocity when input is received vs. no input
		var velocity_input := Vector2.ZERO
		var velocity_no_input := Vector2.ZERO
		if has_input:
			# We already have the main new velocity.
			# Now, compute how much additional velocity is contributed by momentum.
			# Basically, determine how much force to apply orthogonal to the input vector.
			# d_velocity (drag velocity) can be manipulated to simulate better vehicle handling.
			var delta_towards_old_v := entity.velocity - k_velocity
			d_velocity = utils.project(delta_towards_old_v, input.orthogonal())
			d_velocity = lerp(d_velocity, Vector2.ZERO, stats.drag)
			k_velocity = k_velocity * throttle
			velocity_input = k_velocity + d_velocity
		else:
			# This is the simple case. Just apply drag to slowly bring the vehicle to a stop.
			k_velocity = Vector2.ZERO
			d_velocity = lerp(entity.velocity, Vector2.ZERO, stats.drag)
			velocity_no_input = d_velocity
		entity.velocity = lerp(velocity_no_input, velocity_input, clamp(input.length(), 0, 1))
	if mode == Mode.Arrive:
		entity.velocity = k_velocity * arrival
		var has_arrived := arrival <= Constants.EPSILON
		if has_arrived:
			mode = Mode.Manual

	# set state for next frame
	input = Vector2.ZERO

func _draw() -> void:
	#debug_velocity(velocity, Color.RED)
	#debug_velocity(velocity * drag_factor, Color.YELLOW)
	var a := entity.velocity
	var b := k_velocity
	var c := d_velocity
	var d := input * 50
	debug_velocity(a, Color.YELLOW, 6)
	#debug_velocity(b, Color.RED, 8)
	debug_velocity(c, Color.DARK_MAGENTA, 2)
	debug_velocity(d, Color.LIME_GREEN, 1)

func debug_velocity(vel:Vector2, color:Color, width:float = 2.0) -> void:
	draw_line(Vector2.ZERO, vel * 2, color, width, true)

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
