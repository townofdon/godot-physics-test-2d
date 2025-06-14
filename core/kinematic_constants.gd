extends Node
class_name KinematicConstants

# constants
var _w := 0.0
var _z := 0.0
var _d := 0.0
var k1 := 0.0
var k2 := 0.0
var k3 := 0.0

var use_pole_matching:bool = false

func _init(f:float, z:float, r:float, use_pole_matching:bool = false) -> void:
	# compute constants
	_w = 2 * PI * f
	_z = z
	_d = _w * sqrt(abs(z * z - 1))
	k1 = z / (PI * f)
	k2 = 1 / (_w * _w)
	k3 = r * z / _w
	self.use_pole_matching = use_pole_matching

func lerp(other:KinematicConstants, t: float) -> KinematicConstants:
	var f:float = lerp(self.f, other.f, clamp(t, 0, 1))
	var z:float = lerp(self.z, other.z, clamp(t, 0, 1))
	var r:float = lerp(self.r, other.r, clamp(t, 0, 1))
	var out:KinematicConstants = KinematicConstants.new(f, z, r)
	return out
