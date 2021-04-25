extends Node

static func pipeline(args: Dictionary, parent: Node):

	args['u_offset'] = Vector2(500, 500)

	
	args['queue'] = []
	
	var u_alive = 0.4
	var u_birth = 4
	var u_death = 3
	var u_scale = 1.7
	var passA_iterations = 1
	var size = Vector2(50, 50)
	
	# Prepare the inputs
	if args.has('u_alive'):
		u_alive = args['u_alive']
	if args.has('size'):
		size = args['size']
	if args.has('passA_iterations'):
		passA_iterations = args['passA_iterations']
		
	var imgtodata = preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_RGBA8)	
	args['data'] = ImageData.new(size, Image.FORMAT_RGBA8)
	
	# Create the noise
	args['queue'].append({
		'pipeline': preload("res://gen/CellularRadiusPipe.gd"),
		'pass': ['u_offset', 'data'],
		'args': {
			'command': imgtodata,
			'u_alive': u_alive,
			'iterations': 1,
		}
	})

	args['queue'].append({
		'pipeline': preload("res://gen/CellularPipe.gd"),
		'pass': ['u_offset', 'data'],
		'args': {
			'u_birth': u_birth,
			'u_death': u_death,
			'u_scale': u_scale,
			'iterations': passA_iterations,
			'command': imgtodata,
		}
	})

	
	return Pipeline.new(args, parent)
