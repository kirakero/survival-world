extends Node

var format

func _init(_format: int = -1):
	format = _format
	
# take the result, which is type Dictionary, extract the Image from data,
# and store it in args['data'], which is type ImageData
func run(args: Dictionary, result, _coordinator) -> Dictionary:
		
	var rng = RandomNumberGenerator.new()
	rng.seed = args['seed']
	
	var area: Rect2 = args['area']
	var radius: float = args['radius']
	var p_radius: float = args['pradius']
	var match_range: float = args['range']
	var variance: float = args['variance']
	var curve: float = args['curve']
	var max_tries: int = args['attempts']
	
	var matched: Array = args['matched']
	var parents: Dictionary = args['parents']
	var indexed: Dictionary = args['indexed']
	
	
	var c_points_tries = {}
	var c_points = PoissonDiscSampling.new().generate_points(rng, p_radius, area, 20)

	while c_points.size():
		var p = c_points.pop_back()
		var matched_i = null
		var matched_d = INF
		for i in matched:
			var d = i[0].distance_to(p)
			if d < match_range and d < matched_d:
				matched_d = d
				matched_i = i

		var k = vector2key(p)
		if matched_i:
			# set the parent of this point
			parents[ k ] = parents[ vector2key(matched_i[0]) ]
			# add this point to findable points, growing the mass
			# we also store the original radius for later
			# as well as the random variance
			var new_point = [ p, radius, rng.randf_range( 0, variance ), curve ]
			matched.append(new_point) 
			# add this point to the indexed points for the mass
			indexed[ parents[ vector2key(matched_i[0]) ] ].append(new_point)
		else:
			if not c_points_tries.has(k):
				c_points.push_front(p)
				c_points_tries[k] = 1
			elif c_points_tries[k] < max_tries:
				c_points.push_front(p)
				c_points_tries[k] = c_points_tries[k] + 1

	var out = {}
	out['matched'] = matched
	out['parents'] = parents
	out['indexed'] = indexed

	return out

func vector2key(key_vector: Vector2):
	return str(int(key_vector.x),',',int(key_vector.y))
