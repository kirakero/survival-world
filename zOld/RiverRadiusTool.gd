extends Node
class_name RiverRadiusTool

var start_p_size
var end_p_size
var rlen
var rlenshort
var curve
var start_p
var end_p
var dist_coef

func _init(curve, start_p, end_p):
	self.curve = curve
	self.start_p = start_p
	self.end_p = end_p
	start_p_size = rand_range(1.0, 30.0)
	end_p_size = rand_range(1.0, 30.0)
	rlen = sqrt(curve.get_baked_length())
	rlenshort = sqrt(start_p.distance_to(end_p))
	dist_coef =  1.0 #rlen / rlenshort
	
func radius(coord):
	
	var d = min( sqrt(start_p.distance_to(coord)) * dist_coef,  sqrt(end_p.distance_to(coord)) * dist_coef )
	
	
	return clamp(rlen - d, 3, 60)
