extends Node
class_name OceanFeature

var ocean: Ocean
var type
var coords: Vector2
var forward: Vector2
var score: float

func _init(ocean: Ocean, type, coords, forward, score):
	self.ocean = ocean
	self.type = type
	self.coords = coords
	self.forward = forward
	self.score = score
	pass
