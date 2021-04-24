extends Node

static func pipeline(args: Dictionary, parent: Node):

	args['u_offset'] = Vector2(500, 500)

	args['seed'] = 10
	
	args['rng'] = RandomNumberGenerator.new()
	args['rng'].seed = args['seed']

	args['basemap/size'] = 8192
	# how many times we will upsample the poisson basemap (power of 2)
	args['basemap/upsample_steps'] = 16
	
	# this is the size we will generate using poisson
	var psize = args['basemap/size'] / args['basemap/upsample_steps']
	args['poisson/size_v2'] = Vector2(psize, psize)
	# the minimum number of discrete islands that must be present to accept the
	# poisson generate step (not a guarenteed amount)
	args['poisson/min_islands'] = 10
	# c_size
	args['poisson/basic_size_v2'] = args['poisson/size_v2'].x * 0.05
	# c_range_spawn
	args['poisson/range_spawn'] = args['poisson/size_v2'].x * 0.16
	# c_range
	args['poisson/basic_range'] = args['poisson/size_v2'].x * 0.05 * 1.5
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
		'radius':	args['poisson/size_v2'].x * 0.029	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.055 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.06 	,# range
		'variance':	0.2 								,# variance
		'curve':	-1.8								,# noisecurve
		'attempts':	1									,# attempts
	})
	
	args['poisson/growth'].append({
		'area':		args['poisson/large_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.035	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.055 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.06 	,# range
		'variance':	0.2 								,# variance
		'curve':	-1.8								,# noisecurve
		'attempts':	1									,# attempts
	})

	args['poisson/growth'].append({
		'area':		args['poisson/small_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.01	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.07 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.0625 	,# range
		'variance':	0.6 								,# variance
		'curve':	-0.2								,# noisecurve
		'attempts':	3									,# attempts
	})

	args['poisson/growth'].append({
		'area':		args['poisson/small_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.0075	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.07 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.0531 	,# range
		'variance':	0.4 								,# variance
		'curve':	-0.2								,# noisecurve
		'attempts':	3									,# attempts
	})

	args['poisson/growth'].append({
		'area':		args['poisson/small_area']			,# area
		'radius':	args['poisson/size_v2'].x * 0.0075	,# radius
		'pradius':	args['poisson/size_v2'].x * 0.07 	,# poissonradius
		'range':	args['poisson/size_v2'].x * 0.0531 	,# range
		'variance':	0.4 								,# variance
		'curve':	-0.2								,# noisecurve
		'attempts':	3									,# attempts
	})

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



	return Pipeline.new(args, parent)
