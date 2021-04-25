extends Node

var format

func _init(_format: int = -1):
	format = _format

func run(args: Dictionary, result, _coordinator) -> Dictionary:		
	var islands = []
	var half = args['basemap/current_size'] * 0.5
	for k in args['islands'].size():
		# place 0,0 at the center of the map instead of at the corner
		var extents = Rect2(args['islands'][k]['extents'].position - half, args['islands'][k]['extents'].size)
		islands.append({
#			'points': 	args['islands'][k]['points'],
			'extents': 	extents,
			'image': 	ImageData.new(
				args['islands'][k]['extents'].size,
				Image.FORMAT_L8,
				0,
				args['islands/rendered'][k]['mask']
			),
		})
#		break
	return {
		'islands': islands,
	}
