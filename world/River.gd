extends Node
class_name River

var oceans: = []

func _init(oceans, edge: Vector2Edge):
	self.oceans = oceans
	self.edge = edge

func connects_to(target):
	for ocean in oceans:
		if ocean.center == target.center:
			return true
