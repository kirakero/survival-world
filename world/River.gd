extends Node
class_name River

var oceans: = []
var edge

func _init(oceans, edge: Vector2Edge):
	self.oceans = oceans
	self.edge = edge
	print ('RIVER between ', edge.a,' and ',edge.b)

func connects_to(target):
	for ocean in oceans:
		if ocean.center == target.center:
			return true
	return false
