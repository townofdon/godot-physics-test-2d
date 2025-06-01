extends CharacterBody2D
class_name Entity

@export var speed: float = 50
@export var mass: float = 100
@export var bounce: float = 0.9

@onready var marker = %Marker2D

var frame_count := 0
var last_collision_entity: Entity

var direction := Vector2.ZERO
var forces: Array[ForceOverTime] = []

func _ready() -> void:
	var init_direction: Vector2 = (marker.global_position - global_position).normalized()
	direction = init_direction
	velocity = direction * speed

func _physics_process(delta: float) -> void:
	# handle external forces
	var external_velocity := Vector2.ZERO
	var t := 0.0
	for force in forces:
		external_velocity += force.get_value()
		t += force.get_t()
	velocity = lerp(direction * speed, external_velocity, clamp(t, 0, 1))

	var collision := move_and_collide(velocity * delta)

	if (last_collision_entity && (!collision || collision.get_collider() != last_collision_entity)):
		remove_collision_exception_with(last_collision_entity)
		last_collision_entity = null

	if (collision):
		var otherCollider := collision.get_collider()
		if (otherCollider is Entity):
			_collide_with_entity(collision.get_collider(), collision)
		else:
			# assume other collider is a static object
			var rebound := velocity.bounce(collision.get_normal())
			velocity = rebound * bounce

	frame_count += 1
	for force in forces:
		force.tick(delta)

	for i in range(forces.size()-1, -1, -1):
		var force:ForceOverTime = forces[i]
		if (!force): continue
		if (force.is_completed()): forces.remove_at(i)

# calculate zero momentum frame
# see: https://isaacphysics.org/concepts/cp_collisions
func _calc_zmf(a: Entity, b: Entity) -> Vector2:
	return (a.mass * a.velocity + b.mass * b.velocity) / (a.mass + b.mass)

func _collide_with_entity(other: Entity, collision: KinematicCollision2D) -> void:
	var collision_magnitude := (self.velocity - other.velocity).length()
	print(collision_magnitude)
	# ignore the collider for one frame
	last_collision_entity = other
	add_collision_exception_with(last_collision_entity)
	# see: https://isaacphysics.org/concepts/cp_collisions
	# 1. convert to zero-momentum-frame (zmf)
	var ua := self.velocity
	var ub := other.velocity
	var zmf := _calc_zmf(self, other)
	# 2. subtract zmf from velocities
	var ua_zmf := ua - zmf
	var ub_zmf := ub - zmf
	# 3. rotate velocities based on collision normal
	var va_zmf := collision.get_normal() * ua_zmf.length()
	var vb_zmf := -1 * collision.get_normal() * ub_zmf.length()
	# 4. convert velocities back to LAB frame
	var va := va_zmf + zmf
	var vb := vb_zmf + zmf
	self.velocity = va * self.bounce
	other.velocity = vb * other.bounce

	self.forces.append(ForceOverTime.new(self.velocity, 1))
	other.forces.append(ForceOverTime.new(other.velocity, 1))
