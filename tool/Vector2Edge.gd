extends Node
class_name Vector2Edge

var a
var b
var distance
var midpoint

func _init(a, b):
	if a > b:
		self.b = a
		self.a = b
	else:
		self.a = a
		self.b = b
	
	distance = a.distance_to(b)
	midpoint = (a + b) * 0.5
	midpoint.x = floor(midpoint.x)
	midpoint.y = floor(midpoint.y)

func _debug():
	print ('::EDGE ', [a, b, distance, midpoint])
