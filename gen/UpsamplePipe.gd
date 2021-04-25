extends Node

static func pipeline(args: Dictionary, parent: Node, _callback = null):
	
	# inputs ['islands', 'basemap/current_size'],
	args['queue'] = []
	# process the islands
	args['queue'].append({
		# Use a generic pipeline
		'pipeline': preload("res://gen/Pipe.gd"),
		# batch process each island
		'batch': 'islands',
		'args': {
			# step 1: 2x the image
			'pre-command': preload("res://gen/command/Image2x.gd").new(),
			# step 2: binary filter
			'shader': preload("res://gen/shader/BinaryFilter.shader"),
			'shader/data': 'image',
			# step 3: integrate results back to shader/data ie 'image'
			'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
		},
		# outputs
		'results-as': 'islands',
	})
	
	args['queue'].append({
		'pipeline': preload("res://gen/Pipe.gd"),
		'batch': 'islands',
		'args-as': {'position':'u_offset', 'size':'u_size'},
		'args': {
			# shader step
			'shader': preload("res://gen/shader/Cellular.shader"),
			'shader/data': 'image',
			'u_luminance': 1.0,
			'u_min': 1.0,
			'u_birth': 3,
			'u_death': 4,
			# u_scale 0.01 = big
			# u_scale 0.05 = big
			# u_scale 0.1 = small
			'u_scale': 0.1,
			'u_deathnoise': true,
			'iterations': 2,
			# integrate results back to shader/data ie 'image'
			'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
		},
		# outputs
		'results-as': 'islands',
	})
	
#	args['queue'].append({
#		'pipeline': preload("res://gen/Pipe.gd"),
#		'batch': 'islands',
#		'args': {
#			# shader step
#			'shader': preload("res://gen/shader/Cellular.shader"),
#			'shader/data': 'image',
#			'u_luminance': 1.0,
#			'u_min': 1.0,
#			'u_birth': 3.5,
#			'u_death': 0,
#			'u_scale': 10,
#			'iterations': 1,
#			# integrate results back to shader/data ie 'image'
#			'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
#		},
#		# outputs
#		'results-as': 'islands',
#	})

#	args['queue'].append({
#		'pipeline': preload("res://gen/Pipe.gd"),
#		'batch': 'islands',
#		'args-as': {'position':'u_offset'},
#		'args': {
#			# shader step
#			'shader': preload("res://gen/shader/Cellular.shader"),
#			'shader/data': 'image',
#			'u_luminance': 1.0,
#			'u_min': 1.0,
#			'u_birth': 6,
#			'u_death': 4,
#			'u_scale': 10,
#			'iterations': 2,
#			# integrate results back to shader/data ie 'image'
#			'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
#		},
#		# outputs
#		'results-as': 'islands',
#	})
	
	# update basemap/current_size
	# todo simplify the usage of simple operations like these
	args['queue'].append({
		# Use a generic pipeline
		'pipeline': preload("res://gen/Pipe.gd"),
		'args': {
			'command': preload("res://gen/command/Basemap2x.gd").new(),
		},
		# inputs
		'pass': ['basemap/current_size'],
		# outputs
		'merge': ['basemap/current_size'],
	})
	
	# outputs ['islands', 'basemap/current_size'],
	return Pipeline.new(args, parent, _callback)
