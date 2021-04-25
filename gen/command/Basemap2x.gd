extends Node

var format

func _init(_format: int = -1):
	format = _format

func run(args: Dictionary, result, _coordinator) -> Dictionary:	

	args['basemap/current_size'] = args['basemap/current_size'] * 2.0
	
	return args
