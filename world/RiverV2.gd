extends Node
class_name RiverV2

var ocean: Ocean
var start: Vector2
var forward: Vector2

func _init(ocean, start):
	self.ocean = ocean
	self.start = start
	forward = (start - ocean.center).normalized()
#	print('::RIVERV2 ',[ start, forward ])

