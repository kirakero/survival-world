extends Node
class_name Vector2Edge

var a
var b

func _init(a, b):
	if a > b:
		self.b = a
		self.a = b
	else:
		self.a = a
		self.b = b
