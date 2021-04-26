extends Node

static func pipeline(args: Dictionary, parent: Node):

	args['u_offset'] = Vector2(500, 500)

	args['seed'] = 12
	
	args['rng'] = RandomNumberGenerator.new()
	args['rng'].seed = args['seed']

	args['basemap/size'] = 8192
	# how many times we will upsample the poisson basemap (power of 2)
	args['basemap/upsample_steps'] = 16
	
	# this is the size we will generate using poisson
	var psize = args['basemap/size'] / args['basemap/upsample_steps']
	args['poisson/size_v2'] = Vector2(psize, psize)
	args['basemap/current_size'] = Vector2(psize, psize)
	# the minimum number of discrete islands that must be present to accept the
	# poisson generate step (not a guarenteed amount)
	args['poisson/min_islands'] = 10
	# c_size
	args['poisson/basic_size_v2'] = args['poisson/size_v2'].x * 0.05
	# c_range_spawn
	args['poisson/range_spawn'] = args['poisson/size_v2'].x * 0.18
	# c_range
	args['poisson/basic_range'] = args['poisson/size_v2'].x * 0.05 * 1.0
	# c_edge_buffer - used to determine where not to allow points
	args['poisson/edge_margin'] = Vector2(args['poisson/basic_range'], args['poisson/basic_range'])
	# spawn_area_island
	args['poisson/spawn_area'] = Rect2(args['poisson/edge_margin'] * 2.0, args['poisson/size_v2'] - args['poisson/edge_margin'] * 4.0)
	# spawn_area_large
	args['poisson/large_area'] = Rect2(args['poisson/edge_margin'] * 1.0, args['poisson/size_v2'] - args['poisson/edge_margin'] * 2.0)
	# spawn_area_large
	args['poisson/small_area'] = Rect2(args['poisson/edge_margin'] * 0.5, args['poisson/size_v2'] - args['poisson/edge_margin'] * 1.0)

	args['poisson/growth'] = []
	args['poisson/growth'].append({
		'area':		args['poisson/large_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.036	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.098 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.11 	,# range
		'variance':	0.1 								,# variance
		'curve':	0.2								,# noisecurve
		'attempts':	1									,# attempts
	})
	
#	args['poisson/growth'].append({
#		'area':		args['poisson/large_area']			,# area
#		'radius':	args['poisson/size_v2'].x * 0.035	,# radius
#		'pradius':	args['poisson/size_v2'].x * 0.055 	,# poissonradius
#		'range':	args['poisson/size_v2'].x * 0.06 	,# range
#		'variance':	0.2 								,# variance
#		'curve':	-1.8								,# noisecurve
#		'attempts':	1									,# attempts
#	})

	args['poisson/growth'].append({
		'area':		args['poisson/small_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.018	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.0425 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.045 	,# range
		'variance':	0.4 								,# variance
		'curve':	-0.4								,# noisecurve
		'attempts':	4									,# attempts
	})

	args['poisson/growth'].append({
		'area':		args['poisson/small_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.01	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.0225 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.025 	,# range
		'variance':	0.4 								,# variance
		'curve':	-0.4								,# noisecurve
		'attempts':	4									,# attempts
	})

	args['poisson/growth'].append({
		'area':		args['poisson/small_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.0035	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.020 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.022 	,# range
		'variance':	1.2 								,# variance
		'curve':	-0.4								,# noisecurve
		'attempts':	2									,# attempts
	})

#	args['poisson/growth'].append({
#		'area':		args['poisson/small_area']			,# area
#		'radius':	args['poisson/size_v2'].x * 0.0075	,# radius
#		'pradius':	args['poisson/size_v2'].x * 0.07 	,# poissonradius
#		'range':	args['poisson/size_v2'].x * 0.0531 	,# range
#		'variance':	0.4 								,# variance
#		'curve':	-0.2								,# noisecurve
#		'attempts':	3									,# attempts
#	})

	args['queue'] = []
	args['queue'].append({
		# Use a generic pipeline
		'pipeline': preload("res://gen/Pipe.gd"),
		'args': {
			# Assign the Spawn command
			'command': preload("res://gen/command/IslandSpawn.gd").new(),
		},
		# inputs
		'pass': ['seed'],
		'pass-as': {
			'poisson/spawn_area': 'area',
			'poisson/range_spawn': 'radius',
			'poisson/min_islands': 'min_islands',
		},
		# outputs
		'merge': ['matched', 'parents', 'indexed'],
	})

		
	for growth in args['poisson/growth']:
		var _args = growth
		_args['command'] = preload("res://gen/command/IslandGrow.gd").new()

		args['queue'].append({
			# Use a generic pipeline
			'pipeline': preload("res://gen/Pipe.gd"),
			# inputs
			'pass': ['seed', 'matched', 'parents', 'indexed'],
			'args': _args,
			# outputs
			'merge': ['matched', 'parents', 'indexed'],
		})

	args['queue'].append({
		# Use a generic pipeline
		'pipeline': preload("res://gen/Pipe.gd"),
		'args': {
			# Assign the Spawn command
			'command': preload("res://gen/command/IslandAssemble.gd").new(),
		},
		# inputs
		'pass': ['poisson/size_v2', 'poisson/basic_size_v2', 'indexed', 'seed'],
		# outputs
		'merge': ['islands'],
	})
	
	args['queue'].append({
		# Use a generic pipeline
		'pipeline': preload("res://gen/Pipe.gd"),
		# batch process using islands
		# 1 input = 1 output, ordered to match
		'batch': 'islands',
		# inputs
		'args': {
			# Assign the Spawn command
			'command': preload("res://gen/command/IslandRender.gd").new(),
		},
		'pass': ['seed'],
		# outputs
		'results-as': 'islands/rendered',
	})

	args['queue'].append({
		# Use a generic pipeline
		'pipeline': preload("res://gen/Pipe.gd"),
		'args': {
			'command': preload("res://gen/command/IslandClean.gd").new(),
		},
		# inputs
		'pass': ['islands/rendered', 'islands', 'basemap/current_size'],
		# outputs
		'merge': ['islands'],
		'unset': ['matched', 'parents', 'indexed', 'islands/rendered']
	})
	
	args['queue'].append({
		'pipeline': preload("res://gen/Pipe.gd"),
		'batch': 'islands',
		'args-as': {'position':'u_offset'},
		'args': {
			# shader step
			'shader': preload("res://gen/shader/Cellular.shader"),
			'shader/data': 'image',
			'u_luminance': 1.0,
			'u_min': 1.0,
			'u_birth': 4.5,
			'u_death': 0,
			'u_scale': 20,
			'iterations': 4,
			# integrate results back to shader/data ie 'image'
			'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
		},
		# outputs
		'results-as': 'islands',
	})

	args['queue'].append({
		'pipeline': preload("res://gen/Pipe.gd"),
		'batch': 'islands',
		'args-as': {'position':'u_offset'},
		'args': {
			# shader step
			'shader': preload("res://gen/shader/CellularFill.shader"),
			'shader/data': 'image',
			'u_luminance': 1.0,
			'u_min': 1.0,
			'u_birth': 4.5,
			'u_death': 0,
			'u_scale': 20,
			'iterations': 100,
			# integrate results back to shader/data ie 'image'
			'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
		},
		# outputs
		'results-as': 'islands',
	})

	var regrade = true
	var upscale = true

	if regrade:
		args['queue'].append({
			'pipeline': preload("res://gen/Pipe.gd"),
			'batch': 'islands',
			'args-as': {'position':'u_offset'},
			'args': {
				# shader step
				'shader': preload("res://gen/shader/Regrade.shader"),
				'shader/data': 'image',
				'u_low': 0.0,
				'u_high': 0.0,
				'u_delta': 1.0,
				'iterations': 1,
				# integrate results back to shader/data ie 'image'
				'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
			},
			# outputs
			'results-as': 'islands',
		})

		args['queue'].append({
			'pipeline': preload("res://gen/Pipe.gd"),
			'batch': 'islands',
			'args-as': {'position':'u_offset'},
			'args': {
				# shader step
				'shader': preload("res://gen/shader/Regrade.shader"),
				'shader/data': 'image',
				'u_low': 0.0,
				'u_high': 0.5,
				'u_delta': -0.5,
				'iterations': 1,
				# integrate results back to shader/data ie 'image'
				'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
			},
			# outputs
			'results-as': 'islands',
		})

	if upscale:

		# 1k
		args['queue'].append({
			'pipeline': preload("res://gen/UpsamplePipe.gd"),
			'args': {},
			# inputs
			'pass': ['islands', 'basemap/current_size'],
			# outputs
			'merge': ['islands', 'basemap/current_size'],
		})

	#	# 2k
		args['queue'].append({
			'pipeline': preload("res://gen/UpsamplePipe.gd"),
			'args': {},
			# inputs
			'pass': ['islands', 'basemap/current_size'],
			# outputs
			'merge': ['islands', 'basemap/current_size'],
		})
	#
	#	# 4k
		args['queue'].append({
			'pipeline': preload("res://gen/UpsamplePipe.gd"),
			'args': {},
			# inputs
			'pass': ['islands', 'basemap/current_size'],
			# outputs
			'merge': ['islands', 'basemap/current_size'],
		})
		
		args['queue'].append({
			'pipeline': preload("res://gen/Pipe.gd"),
			'batch': 'islands',
			'args': {
				# shader step
				'shader': preload("res://gen/shader/Cellular.shader"),
				'shader/data': 'image',
				'u_luminance': 1.0,
				'u_min': 1.0,
				'u_birth': 4,
				'u_death': 3,
				'u_scale': 0,
				'iterations': 4,
				# integrate results back to shader/data ie 'image'
				'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
			},
			# outputs
			'results-as': 'islands',
		})
	#
		# 8k
		args['queue'].append({
			'pipeline': preload("res://gen/UpsamplePipe.gd"),
			'args': {},
			# inputs
			'pass': ['islands', 'basemap/current_size'],
			# outputs
			'merge': ['islands', 'basemap/current_size'],
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
				'u_birth': 4.5,
				'u_death': 3,
				# u_scale 0.01 = big
				# u_scale 0.05 = big
				# u_scale 0.1 = small
				'u_scale': 0.001,
				'iterations': 6,
				# integrate results back to shader/data ie 'image'
				'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8),
			},
			# outputs
			'results-as': 'islands',
		})

	args['queue'].append({
		# Use a generic pipeline
		'pipeline': preload("res://gen/Pipe.gd"),
#		'args': {},
		# batch process each island
		'batch': 'islands',
		'args-as': {'color':'u_color'},
		'args': {
			'shader': preload("res://gen/shader/AlphaFilter.shader"),
			'shader/data': 'image',
			# integrate results back to shader/data ie 'image'
			'command': preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_RGBA8),
		},
		# outputs
		'results-as': 'islands',
	})

	return Pipeline.new(args, parent)
