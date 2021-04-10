extends Node
class_name MapSettings

var chunk_size = 128
var chunk_dim
var dim
var randomseed
var width
var height

var _SHALLOWS = 16
var _DEEPENING = 1.2

var H_WATER = 127
var H_DEEP = H_WATER - _SHALLOWS
var H_OCEAN = H_WATER - 50

var MAX_RIVER_DISTANCE = 1000
var SPACING = 10
var MAX_OCEAN_SIZE = 256
var detection_rate = 64

func _init(randomseed, chunk_dim: Vector2):
	self.randomseed = randomseed
	self.chunk_dim = chunk_dim
	self.width = chunk_dim.x * chunk_size
	self.height = chunk_dim.y * chunk_size
	pass



func _spacing_snap(x, y):
	return Vector2(int(x/SPACING)*SPACING, int(y/SPACING)*SPACING)

func _debug():
	print('::MapSettings ',[width, height])
