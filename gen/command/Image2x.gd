extends Node

var format

func _init(_format: int = -1):
	format = _format

func run(args: Dictionary, result, _coordinator) -> Dictionary:	

	# inputs: points, extents, image
	
	# scale ImageData up by 2x
	var imgdata: ImageData = args['image']
	imgdata.resize_2x()
	args['image'] = imgdata

	# update extents
	var extents: Rect2 = args['extents']
	extents.position = extents.position * 2.0
	extents.size = extents.size * 2.0
	args['extents'] = extents
	args['position'] = extents.position
	args['size'] = extents.size
	# todo points
	
	# outputs: points, extents, image
	return args
