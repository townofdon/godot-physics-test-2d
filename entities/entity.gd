extends CharacterBody2D
class_name Entity

@export_category("movement")
@export var speed: float = 50
@export_range(0.0, 2.0, 0.001) var throttle_up_time: float = 0.3
@export_range(0.0, 2.0, 0.001) var throttle_down_time: float = 0.15

@export_category("arrival")
@export var arrive_distance: float = 50
@export var arrive_curve: Curve

@export_category("physics")
@export var mass: float = 100
@export var bounce: float = 0.9

@onready var marker = %Marker2D

var frame_count := 0
var last_collision_entity: Entity

var forces: Array[ForceOverTime] = []

func _ready() -> void:
	if (!marker): return
	var init_direction: Vector2 = (marker.global_position - global_position).normalized()
	velocity = init_direction * speed

func _physics_process(delta: float) -> void:
	# handle external forces
	var external_velocity := Vector2.ZERO
	var computed_velocity := Vector2.ZERO
	var t := 0.0
	for force in forces:
		if (force.is_completed()): continue
		external_velocity += force.get_value()
		t += force.get_t()
	computed_velocity = lerp(velocity, external_velocity, clamp(t, 0, 1))

	var collision := move_and_collide(computed_velocity * delta)

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
			self.remove_forces_by_type(ForceOverTime.COLLISION)
			self.forces.append(ForceOverTime.new(self.velocity, 1, ForceOverTime.COLLISION))

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
	# TODO: factor collision_magnitude into damage
	#var collision_magnitude := (self.velocity - other.velocity).length()
	var vector_to_other := other.global_position - self.global_position
	var dot_pos := velocity.normalized().dot(vector_to_other.normalized())
	var dot_travel := velocity.normalized().dot(collision.get_travel())
	var is_other_behind:bool = dot_pos < 0 || dot_travel < 0

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
	if (is_other_behind):
		self.velocity = -1 * vector_to_other.normalized() * vb.length()
		other.velocity = vector_to_other.normalized() * vb.length()
	else:
		self.velocity = va * self.bounce
		other.velocity = vb * other.bounce

	self.remove_forces_by_type(ForceOverTime.COLLISION)
	other.remove_forces_by_type(ForceOverTime.COLLISION)
	self.forces.append(ForceOverTime.new(self.velocity, 1, ForceOverTime.COLLISION, other))
	other.forces.append(ForceOverTime.new(other.velocity, 1, ForceOverTime.COLLISION, self))

func remove_forces_by_type(type: int) -> void:
	for i in range(forces.size()-1, -1, -1):
		var force:ForceOverTime = forces[i]
		if (!force || force.is_completed()): continue
		if (force.is_type(type)):
			forces.remove_at(i)
