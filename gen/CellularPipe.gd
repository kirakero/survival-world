extends Node

static func pipeline(args: Dictionary, parent: Node):
	args['shader'] = preload("res://gen/shader/Cellular.shader")
	return Pipeline.new(args, parent)
