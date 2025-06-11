extends RefCounted
class_name SecondOrderDynamics

# previous input
var xp

# state
var y # output (position if Vector2)
var yd # delta-output (velocity if Vector2)

# constants
var _w := 0.0
var _z := 0.0
var _d := 0.0
var k1 := 0.0
var k2 := 0.0
var k3 := 0.0

func _init(f:float, z:float, r:float, x0) -> void:
	assert(typeof(x0) == TYPE_FLOAT || typeof(x0) == TYPE_VECTOR2)
	# compute constants
	_w = 2 * PI * f
	_z = z
	_d = _w * sqrt(abs(z * z - 1))
	k1 = z / (PI * f)
	k2 = 1 / (_w * _w)
	k3 = r * z / _w
	# initialize variables
	xp = x0
	y = x0
	yd = x0

func compute(delta:float, x) -> Variant:
	if (delta <= 0):
		return y

	assert(typeof(x) == typeof(xp))
	var T:float = delta

	# estimate change of input
	var xd = (x - xp) / T
	xp = x

	## clamp k2 to guarantee stability without jitter
	var k1_stable:float = k1
	var k2_stable:float = max(k2, T*T/2 + T*k1/2, T*k1)

	if (_w * T >= _z && _z < 0.75):
		# use pole matching when the system is very fast
		var t1:float = exp(-_z * _w * T)
		var alpha:float = 2 * t1 * (cos(T*_d) if _z <= 1 else cosh(T*_d))
		var beta:float = t1 * t1
		var t2:float = T / (1 + beta - alpha)
		k1_stable = (1 - beta) * t2
		k2_stable = T * t2
#
	y = y + T * yd
	yd = yd + T * (x + k3*xd - y - k1_stable*yd) / k2_stable

	#y = y + T * yd
	#yd = (k2*yd + (x + k3*xd - y) * T) / max(k2_stable + k1_stable * T, 0.001)

	return y
