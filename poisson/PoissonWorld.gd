extends Node


var run = false

func _ready():
	generate()

func generate():
	
	var testsize = 256
	var world_dim = Vector2(testsize, testsize)
	var c_size = world_dim.x * 0.05
	var c_range = c_size * 1.25
	var c_range_spawn = world_dim.x * 0.3
	var c_edge_buffer = Vector2(c_range, c_range) # do not put points here
	
	var spawn_area_island = Rect2(c_edge_buffer * 2.0, world_dim - c_edge_buffer * 4.0)
	var spawn_area_large = Rect2(c_edge_buffer, world_dim - c_edge_buffer*2.0)
	
	# Process
	var rng = RandomNumberGenerator.new()
	rng.seed = 28
	
	# determine the spawn points and setup the variables
	var matched
	var parents
	var indexed
	var res
	res = makeIslands(rng, spawn_area_island, c_range_spawn)
	matched = res[0]
	parents = res[1]
	indexed = res[2]
	
	# make the first pass - this grows the continent using large pieces
	res = growIslands(rng, spawn_area_large, c_size, matched, parents, indexed, 4)
	matched = res[0]
	parents = res[1]
	indexed = res[2]
	
	# collect the points into the pre-rendering data
	var islands
	var extents
	res = assembleIslands(rng, indexed, 10)
	islands = res[0]
	extents = res[1]
	
	# render each island and draw them
	var simplex = OpenSimplexNoise.new()
	simplex.seed = rng.seed
	simplex.octaves = 5
	simplex.period = 6
	
	var data = PoolByteArray()
	data.resize(world_dim.x * world_dim.y * 4)
	for i in data.size():
		data[i] = 35
	var colors = [Color.orange, Color.red, Color.green, Color.yellow, Color.silver, Color.pink, Color.white, Color.purple, Color.teal, Color.lavender]

	for k in islands.size():
		var bytes = renderIsland(islands[k], extents[k], c_range, simplex)
		
		for x in range(0, extents[k].size.x):
			for y in range(0, extents[k].size.y):
				
				if x + extents[k].position.x > world_dim.x or x + extents[k].position.x < 0:
					continue
				if y + extents[k].position.y > world_dim.y or y + extents[k].position.y < 0:
					continue	
				if bytes[x + y * extents[k].size.x] != 255:
					continue
				# translate the extents into world coords for the output byte array
				var p = (x + extents[k].position.x) * 4 + (y + extents[k].position.y) * 4 * world_dim.x
			
				data[p] = colors[k].r * 255
				data[p+1] = colors[k].g * 255
				data[p+2] = colors[k].b * 255
				data[p+3] = 255
		
	var img = Image.new()
	img.create_from_data(testsize, testsize, false, Image.FORMAT_RGBA8, data)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)


	$Sprite.set_texture(tex)

func gen():
	var testsize = 256
	var dim = Vector2(testsize, testsize)
	var c_size = dim.x * 0.05
	var c_range = c_size * 1.25
	var c_range_spawn = dim.x * 0.3
	var c_edge_buffer = Vector2(c_range, c_range) # do not put points here
	var c_pcount = 4 # how many points can join together to one mass
	var rngseed = 28
	var max_tries = 3
	var rng = RandomNumberGenerator.new()
	rng.seed = rngseed
	# determine the continents
	var c_points = PoissonDiscSampling.new().generate_points(rngseed, c_size, Rect2(c_edge_buffer, dim - c_edge_buffer*2.0), 20)
	var c_points_tiny = PoissonDiscSampling.new().generate_points(rngseed, c_size, Rect2(c_edge_buffer, dim - c_edge_buffer*2.0), 20)
	var c_points_spawn = PoissonDiscSampling.new().generate_points(rngseed, c_range_spawn, Rect2(c_edge_buffer * 2.0, dim - c_edge_buffer * 4.0), 20)
	
	var c_points_match = c_points_spawn
	var c_points_parent = {}
	var c_points_out = {}
	var c_points_tries = {}
	for cp in c_points_spawn:
		var k = vector2key(cp)
		c_points_parent[k] = k
		c_points_out[k] = [cp]

	while c_points.size():
		var p = c_points.pop_back()
		var matched_i = null
		var matched_d = testsize
		for i in c_points_match:
			var d = i.distance_to(p)
			if d < c_range and d < matched_d:
				matched_d = d
				matched_i = i

		if matched_i:
			# set the parent of this point
			c_points_parent[ vector2key(p) ] = c_points_parent[ vector2key(matched_i) ]
			# add this point to findable points, growing the mass
			c_points_match.append(p) 
			# add this point to the indexed points for the mass
			c_points_out[ c_points_parent[ vector2key(matched_i) ] ].append(p)
		else:
			var k = vector2key(p)
			if not c_points_tries.has(k):
				c_points.push_front(p)
				c_points_tries[k] = 1
			elif c_points_tries[k] < max_tries:
				c_points.push_front(p)
				c_points_tries[k] = c_points_tries[k] + 1
		

	var data = PoolByteArray()
	data.resize(testsize * testsize * 4)
	for i in data.size():
		data[i] = 0
	
	var colors = [Color.orange, Color.red, Color.green, Color.yellow, Color.silver, Color.pink, Color.white, Color.purple, Color.teal, Color.lavender]

	
	var _color = Color.black
	for p in range(0, data.size(), 4):
		data[p] = _color.r * 255
		data[p+1] = _color.g * 255
		data[p+2] = _color.b * 255
		data[p+3] = 255

	var nc = 0
	var simplex = OpenSimplexNoise.new()
	simplex.seed = rngseed
	simplex.octaves = 5
	simplex.period = 6
	for group in c_points_out.keys():

		
		var all_points = Vector2.ZERO
		for point in c_points_out[group]:
			all_points = all_points + point
		
		all_points = all_points / c_points_out[group].size()
		
		# setup initial group and determine extents
		var points_index = []
		var extent_low = dim
		var extent_high = Vector2.ZERO
		for point in c_points_out[group]:
			var r = rng.randf_range(1.0, 3.5)
			point = point.move_toward(all_points, r * 2.5)
			points_index.append([point, 6 - r])
			if point.x < extent_low.x:
				extent_low.x = point.x
			if point.y < extent_low.y:
				extent_low.y = point.y
			if point.x > extent_high.x:
				extent_high.x = point.x
			if point.y > extent_high.y:
				extent_high.y = point.y
		
		var c_size_plus = c_size + 3.5
		extent_low = extent_low - Vector2(c_size_plus, c_size_plus)
		extent_high = extent_high + Vector2(c_size_plus, c_size_plus)
		_color = colors[nc]
		nc = (nc + 1) % colors.size()
		
		
		for x in range(extent_low.x, extent_high.x, 1):
			for y in range(extent_low.y, extent_high.y, 1):
				var closest_c = null
				var closest = dim.x
				for point in points_index:
					var d = Vector2(x,y).distance_to(point[0])
					if d < c_range and d < closest:
						closest = d
						closest_c = point
		
				
				if closest < dim.x:
					var true_weight = closest_c[1] * c_range * 0.15
					if true_weight - closest + simplex.get_noise_2d(x, y) * 6.0 < 0:
						continue
					_color = colors[nc]

					var p = x * 4 + y * 4 * dim.y
					data[p] = _color.r * 255
					data[p+1] = _color.g * 255
					data[p+2] = _color.b * 255
					data[p+3] = 255
	




	var img = Image.new()
	img.create_from_data(testsize, testsize, false, Image.FORMAT_RGBA8, data)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)


	$Sprite.set_texture(tex)
		
func vector2key(key_vector: Vector2):
	return str(int(key_vector.x),',',int(key_vector.y))

# convert the island into a mask
func renderIsland(points: Array, extents: Rect2, max_range: float, simplex: OpenSimplexNoise):
	var mask = PoolByteArray()
	mask.resize((extents.size.x) * (extents.size.y))
	for i in mask.size():
		mask[i] = 0
	for x in range(0, extents.size.x, 1):
		for y in range(0, extents.size.y, 1):
			
			var closest_c = null
			var closest = INF
			var w_point = Vector2(x,y) + extents.position
			for point in points:
				var d = w_point.distance_to(point[0])
				if d < max_range and d < closest:
					closest = d
					closest_c = point

			if closest_c:
				var true_weight = closest_c[1] * max_range * 0.15
				# final check using noise to determine if this part will be cut
				if true_weight - closest + simplex.get_noise_2d(w_point.x, w_point.y) * 6.0 < 0: #< this 20 should be 0
					continue
				var p = x + y * extents.size.x
				mask[p] = 255

	return mask


func assembleIslands(rng: RandomNumberGenerator, matched: Dictionary, margin: float):
	var out = []
	var extents = []
	for group in matched.keys():
		var points_index = []
		# Determine center of the island
		var all_points = Vector2.ZERO
		for point in matched[group]:
			all_points = all_points + point[0]
		
		all_points = all_points / matched[group].size()
		
		# Determine extents and assemble the preprocessing point data
		var extent_low = Vector2(INF, INF)
		var extent_high = Vector2.ZERO
		for point in matched[group]:
			var r = rng.randf_range(1.0, 3.5)
			point[0] = point[0].move_toward(all_points, r * 2.5)
			point[1] = 6 - r #todo change me
			points_index.append(point)
			if point[0].x < extent_low.x:
				extent_low.x = point[0].x
			if point[0].y < extent_low.y:
				extent_low.y = point[0].y
				
			if point[0].x > extent_high.x:
				extent_high.x = point[0].x
			if point[0].y > extent_high.y:
				extent_high.y = point[0].y
	
		var extent = Rect2(int(extent_low.x), int(extent_low.y), 0, 0)
		extent.end = Vector2(int(extent_high.x), int(extent_high.y))
		extent = extent.grow(margin)
		extents.append(extent)
		out.append(points_index)
		
	return [ out, extents ]

func makeIslands(rng: RandomNumberGenerator, area: Rect2, radius: float):
	var c_points_spawn = PoissonDiscSampling.new().generate_points(rng, radius, area, 20)
	
	var matched = []
	for i in c_points_spawn:
		matched.append([ i, null, null ])
	var parents = {}
	var indexed = {}
	
	for cp in c_points_spawn:
		var k = vector2key(cp)
		parents[k] = k
		indexed[k] = [[ cp, null, null ]]
		
	return [ matched, parents, indexed ]

# matched - points that are recognized as found and can be grown from
### matched[] have a special format
# parents - tracks the parents for all points
# indexed - keeps track of all the points in a given island
func growIslands(rng: RandomNumberGenerator, area: Rect2, radius: float, matched: Array, parents: Dictionary, indexed: Dictionary, max_tries = 3):
	var c_points_tries = {}
	var c_points = PoissonDiscSampling.new().generate_points(rng, radius, area, 20)
	var c_range = radius * 1.25
	
	while c_points.size():
		var p = c_points.pop_back()
		var matched_i = null
		var matched_d = INF
		for i in matched:
			var d = i[0].distance_to(p)
			if d < c_range and d < matched_d:
				matched_d = d
				matched_i = i

		var k = vector2key(p)
		if matched_i:
			# set the parent of this point
			parents[ k ] = parents[ vector2key(matched_i[0]) ]
			# add this point to findable points, growing the mass
			# we also store the original radius for later
			matched.append([p, radius]) 
			# add this point to the indexed points for the mass
			indexed[ parents[ vector2key(matched_i[0]) ] ].append([p, radius])
		else:
			if not c_points_tries.has(k):
				c_points.push_front(p)
				c_points_tries[k] = 1
			elif c_points_tries[k] < max_tries:
				c_points.push_front(p)
				c_points_tries[k] = c_points_tries[k] + 1
	
	return [ matched, parents, indexed ]








