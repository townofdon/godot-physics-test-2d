extends RefCounted
class_name SecondOrderDynamics

# state
var xp # previous input
var y  # output (position if Vector2)
var yd # delta-output (velocity if Vector2)

func _init(x0) -> void:
	assert(typeof(x0) == TYPE_FLOAT || typeof(x0) == TYPE_VECTOR2)
	# initialize variables
	xp = x0
	y = x0
	yd = x0

func compute(
	delta:float,
	kinematicConstants:KinematicConstants,
	## target value
	x,
) -> Variant:
	if (delta <= 0):
		return y
	assert(typeof(x) == typeof(xp))
	assert(typeof(x) == typeof(y))
	var T:float = delta
	var k1 = kinematicConstants.k1
	var k2 = kinematicConstants.k2
	var k3 = kinematicConstants.k3
	var _w = kinematicConstants._w
	var _z = kinematicConstants._z
	var _d = kinematicConstants._d
	# estimate change of input
	var xd = (x - xp) / T
	xp = x
	# clamp k2 to guarantee stability without jitter
	var k1_stable:float = k1
	var k2_stable:float = max(k2, T*T/2 + T*k1/2, T*k1)
	# use pole matching when the system is very fast
	if (kinematicConstants.use_pole_matching && _w * T >= _z && _z < 0.75):
		var t1:float = exp(-_z * _w * T)
		var alpha:float = 2 * t1 * (cos(T*_d) if _z <= 1 else cosh(T*_d))
		var beta:float = t1 * t1
		var t2:float = T / (1 + beta - alpha)
		k1_stable = (1 - beta) * t2
		k2_stable = T * t2
	y = y + T * yd
	yd = yd + T * (x + k3*xd - y - k1_stable*yd) / k2_stable
	return y
