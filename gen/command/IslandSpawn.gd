extends Node

var format

func _init(_format: int = -1):
	format = _format
	

func run(args: Dictionary, result, _coordinator) -> Dictionary:
	print('IslandSpawn: start')
	var min_islands: int = 5
	var max_iter: int = 10
	
	var rng = RandomNumberGenerator.new()
	rng.seed = args['seed']
	var area: Rect2 = args['area']
	var radius: float = args['radius']
	if args.has('min_islands'):
		min_islands = args['min_islands']
	
	var c_points_spawn = []
	var iter = 0
	while c_points_spawn.size() < min_islands + 1 and iter < max_iter:
		c_points_spawn = PoissonDiscSampling.new().generate_points(rng, radius, area, 20)
		iter = iter + 1

	var center = Vector2(area.position + area.size * 0.5)
	var d = INF
	var p = null
	for i in c_points_spawn:
		if i.distance_to(center) < d:
			d = i.distance_to(center)
			p = i

	var matched = []
	for i in c_points_spawn:
		if i != p:
			matched.append([ i, null, null, 1, false ])
	var parents = {}
	var indexed = {}

	for cp in c_points_spawn:
		var k = vector2key(cp)
		parents[k] = k
		var r = null
		if cp == p:
			r = 10
		indexed[k] = [[ cp, r, 1, cp == p ]]
	
	var out = {}
	out['matched'] = matched
	out['parents'] = parents
	out['indexed'] = indexed
	print('IslandSpawn: done with ', out['matched'].size(), ' points')
	return out

func vector2key(key_vector: Vector2):
	return str(int(key_vector.x),',',int(key_vector.y))
