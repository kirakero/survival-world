extends Node

static func pipeline(args: Dictionary, parent: Node, _callback = null):
	return Pipeline.new(args, parent, _callback)
