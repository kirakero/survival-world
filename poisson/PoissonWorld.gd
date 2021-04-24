#tool
extends Node

export(float, 0, 100) var size = 50 setget setsize
export(int, 0, 100) var lowval = 50 setget setlow
export(int, 0, 100) var water = 66 setget setwater
export(int, 50, 155) var waterdeep = 80 setget setwaterdeep
export(int, 100, 200) var highval = 200 setget sethigh
export(float, 0, 0.5) var spread = 0.25 setget setspread
export(int, 0, 20) var iter = 1 setget setiter
export(float, 0, 5) var factor = 1 setget setfactor
export(float, 0, 20) var dfactor = 1 setget setdfactor
export(float, -4, 4) var gease = 1 setget setgease

export(float, 0, 1000) var worldpos_x = 500 setget setworld_x
export(float, 0, 1000) var worldpos_y = 500 setget setworld_y

#var run = false
export var busy = false
var coordinator = null

func _ready():
	generate()

func setsize(val):
	size = int(val)
	generate_lake()

func setwater(val):
	water = val
	coordinator = null
	generate_lake()

func setwaterdeep(val):
	waterdeep = val
	genWorld()
	
func setlow(val):
	lowval = val
	generate_lake()
	
func setiter(val):
	iter = val
	generate_lake()
	
func sethigh(val):
	highval = val
	generate_lake()

func setspread(val):
	spread = val
	generate_lake()

func setfactor(val):
	factor = val
	generate_lake()
	
func setdfactor(val):
	dfactor = val
	generate_lake()

func setgease(val):
	gease = val
	generate_lake()
	
func setworld_x(val):
	worldpos_x = int(val)
	generate_lake()

func setworld_y(val):
	worldpos_y = int(val)
	generate_lake()

func genTest():
	return
	if coordinator != null:
		return
	if busy:
		return false
	busy = true
	print('gen')
	coordinator = Coordinator.new(2)
	var pipe = preload("res://gen/LakePipe.gd").pipeline({
		"size": Vector2(size, size),
		"passA_iterations": iter
	}, self)
	assert(pipe.args != null)

	print (pipe.args)
	pipe.run(coordinator)
	var res = yield(pipe, "done")
	var im  = res['data']
	var img = Image.new()
	img.create_from_data( im.size.x, im.size.y, false, Image.FORMAT_RGBA8, im.pa)
		
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	var sprite: Sprite = $Sprite
	sprite.set_texture( tex )
	busy = false
	coordinator.terminate()
	coordinator.queue_free()
	coordinator = null


func genWorld():
	if coordinator != null:
		return
	if busy:
		return false
	busy = true
	print('gen')
	coordinator = Coordinator.new(4)
	var pipe = preload("res://gen/WorldPipe.gd").pipeline({}, self)
	assert(pipe.args != null)

	print (pipe.args)
	pipe.run(coordinator)
	var res = yield(pipe, "done")
	
	print(' result len ', res['islands'].size())
	
	#####
	
	var data = PoolByteArray()
	var world_dim = res['poisson/size_v2']
	data = resize_and_fill(data, world_dim.x * world_dim.y * 4, 35)

	var _colors = [Color.orange, Color.red, Color.green, Color.yellow, Color.silver, Color.pink, Color.white, Color.purple, Color.teal, Color.lavender]
	var colors = []
	for col in _colors:
		colors.append(col)
		colors.append(col * 0.5)

	for k in res['islands'].size():
		var bytes = res['islands/rendered'][k]['mask']
		var island_extents = res['islands'][k]['extents']
		print (['island ', k, bytes.size(), island_extents.size.x * island_extents.size.y])

	for k in res['islands'].size():
		var bytes = res['islands/rendered'][k]['mask']
		var island_extents = res['islands'][k]['extents']
		print (['island ', k, bytes.size(), island_extents.size.x * island_extents.size.y])
		assert(bytes.size() == island_extents.size.x * island_extents.size.y)
		for x in range(0, island_extents.size.x):
			for y in range(0, island_extents.size.y):

				if x + island_extents.position.x > world_dim.x or x + island_extents.position.x < 0:
					continue
				if y + island_extents.position.y > world_dim.y or y + island_extents.position.y < 0:
					continue	
				if bytes[x + y * island_extents.size.x] < 200:
					continue
				# translate the extents into world coords for the output byte array
				var p = (x + island_extents.position.x) * 4 + (y + island_extents.position.y) * 4 * world_dim.x

				data[p] = colors[k % colors.size()].r * bytes[x + y * island_extents.size.x]
				data[p+1] = colors[k % colors.size()].g * bytes[x + y * island_extents.size.x]
				data[p+2] = colors[k % colors.size()].b * bytes[x + y * island_extents.size.x]
				data[p+3] = 255

	var img = Image.new()
	img.create_from_data(world_dim.x, world_dim.y, false, Image.FORMAT_RGBA8, data)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)

	var sprite: Sprite = $Sprite
	sprite.set_texture(tex)
	
	
	#####
	
	busy = false
	coordinator.terminate()
	coordinator.queue_free()
	coordinator = null

func generate_lake():
	if not $Sprite:
		return
	var msec = OS.get_ticks_msec()
	call_deferred("genTest")
	print("took: ", OS.get_ticks_msec() - msec)



func generate():
	return
	var testsize = 400
	var world_dim = Vector2(testsize, testsize)
	var c_size = world_dim.x * 0.05

#	var min_islands = 10

	var pass1_radius = world_dim.x * 0.029
	var pass1_poissonradius = world_dim.x * 0.055
	var pass1_range = world_dim.x * 0.05 * 1.2
	var pass1_variance = 0.2
	var pass1_noisecurve = -1.8

	var pass2_radius = world_dim.x * 0.01
	var pass2_poissonradius = world_dim.x * 0.07
	var pass2_range = world_dim.x * 0.05 * 1.25
	var pass2_variance = 0.6
	var pass2_noisecurve = -0.2

	var c_range = c_size * 1.5
	var c_range_spawn = world_dim.x * 0.16
	var c_edge_buffer = Vector2(c_range, c_range) # do not put points here

	var spawn_area_island = Rect2(c_edge_buffer * 2.0, world_dim - c_edge_buffer * 4.0)
	var spawn_area_large = Rect2(c_edge_buffer, world_dim - c_edge_buffer*2.0)
	var spawn_area_small = Rect2(c_edge_buffer * 0.5, world_dim - c_edge_buffer)

	# Process
	var rng = RandomNumberGenerator.new()
	rng.seed = 44

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
	res = growIslands(rng, spawn_area_large, world_dim.x * 0.035, pass1_poissonradius, pass1_range, pass1_variance, 0.2, matched, parents, indexed, 1)
	matched = res[0]
	parents = res[1]
	indexed = res[2]

	# make the first pass - this grows the continent using large pieces
	res = growIslands(rng, spawn_area_large, pass1_radius, pass1_poissonradius, pass1_range, pass1_variance, pass1_noisecurve, matched, parents, indexed, 1)
	matched = res[0]
	parents = res[1]
	indexed = res[2]

	# make the second pass - this grows the continent using small pieces
	res = growIslands(rng, spawn_area_small, pass2_radius, pass2_poissonradius, pass2_range, pass2_variance, pass2_noisecurve, matched, parents, indexed, 3)
	matched = res[0]
	parents = res[1]
	indexed = res[2]

	# make the second pass - this grows the continent using small pieces
	res = growIslands(rng, spawn_area_small, pass2_radius * 0.75, pass2_poissonradius, pass2_range * 0.85, 0.4, pass2_noisecurve, matched, parents, indexed, 3)
	matched = res[0]
	parents = res[1]
	indexed = res[2]

	# make the second pass - this grows the continent using small pieces
	res = growIslands(rng, spawn_area_small, pass2_radius * 0.75, pass2_poissonradius, pass2_range * 0.85, 0.4, pass2_noisecurve, matched, parents, indexed, 3)
	matched = res[0]
	parents = res[1]
	indexed = res[2]

	# collect the points into the pre-rendering data
	var islands
	var extents
	res = assembleIslands(rng, indexed, ceil(c_size), world_dim * 0.5, 0)
	islands = res[0]
	extents = res[1]

	# render each island and draw them
	var simplex = OpenSimplexNoise.new()
	simplex.seed = rng.seed
	simplex.octaves = 5
	simplex.period = 6

	var data = PoolByteArray()
	data = resize_and_fill(data, world_dim.x * world_dim.y * 4, 35)

	var _colors = [Color.orange, Color.red, Color.green, Color.yellow, Color.silver, Color.pink, Color.white, Color.purple, Color.teal, Color.lavender]
	var colors = []
	for col in _colors:
		colors.append(col)
		colors.append(col * 0.5)

	for k in islands.size():
		var bytes = renderIsland(islands[k], extents[k], simplex)

		for x in range(0, extents[k].size.x):
			for y in range(0, extents[k].size.y):

				if x + extents[k].position.x > world_dim.x or x + extents[k].position.x < 0:
					continue
				if y + extents[k].position.y > world_dim.y or y + extents[k].position.y < 0:
					continue	
				if bytes[x + y * extents[k].size.x] < 200:
					continue
				# translate the extents into world coords for the output byte array
				var p = (x + extents[k].position.x) * 4 + (y + extents[k].position.y) * 4 * world_dim.x

				data[p] = colors[k % colors.size()].r * bytes[x + y * extents[k].size.x]
				data[p+1] = colors[k % colors.size()].g * bytes[x + y * extents[k].size.x]
				data[p+2] = colors[k % colors.size()].b * bytes[x + y * extents[k].size.x]
				data[p+3] = 255

	var img = Image.new()
	img.create_from_data(testsize, testsize, false, Image.FORMAT_RGBA8, data)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)

	var sprite: Sprite = $Sprite
	sprite.set_texture(tex)


func vector2key(key_vector: Vector2):
	return str(int(key_vector.x),',',int(key_vector.y))

## convert the island into a mask
func renderIsland(points: Array, extents: Rect2, simplex: OpenSimplexNoise):
	var mask = PoolByteArray()
	mask = resize_and_fill(mask, int(extents.size.x) * int(extents.size.y), 0)

	for x in range(0, extents.size.x, 1):
		for y in range(0, extents.size.y, 1):

			var closest_c = null
			var closest = INF
			var w_point = Vector2(x,y) + extents.position
			for point in points:
				if not point[1]:
					continue
				var d = w_point.distance_to(point[0])
				# radius is the original radius of the poisson sample
				# here we can adjust it to be more or less island like

				var radius = point[1] * (1.0 + point[2])
				if d - radius < 0 and d < closest:
					closest = d
					closest_c = point

			if closest_c:
				if not closest_c[1]:
					continue

				# 1 is high, 0 is low
				var noise = (simplex.get_noise_2d(w_point.x, w_point.y) + 1) * 0.45
				assert (noise >= 0 and noise <= 1)
				# 1 is on the point, 0 is off point
				var closeness = 1.0 - closest / (closest_c[1] * (1.0 + closest_c[2])) 
				var base_height = 1
				base_height = ease(closeness, float(closest_c[3]))

				assert (closeness >= 0 and closeness <= 1)

				var height = max(noise * (1.0 + closeness), base_height)
				if height < 0.5:
					continue
				var p = x + y * extents.size.x
				mask[p] = 255

	return mask


func assembleIslands(rng: RandomNumberGenerator, matched: Dictionary, margin: float, center: Vector2, spread: float = 0):
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
#			point[1] = 6 - r #todo change me
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

#		# island spacing
#		var dir = (extent.position + extent.size * 0.5) - center
#		var mag = abs(dir.distance_to(Vector2.ZERO) / center.distance_to(Vector2.ZERO) * spread)
#		dir = dir.normalized()
#		extent.position = extent.position + dir * mag
#		print(['modify', extent.position + extent.size * 0.5, dir, mag])
#		extent.position = Vector2(int(extent.position.x), int(extent.position.y))

		extents.append(extent)
		out.append(points_index)


	return [ out, extents ]

func makeIslands(rng: RandomNumberGenerator, area: Rect2, radius: float, min_islands: int = 5):
	var c_points_spawn = []
	var iter = 0
	while c_points_spawn.size() < min_islands + 1 and iter < 10:
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

	return [ matched, parents, indexed ]

# matched - points that are recognized as found and can be grown from
### matched[] have a special format
# parents - tracks the parents for all points
# indexed - keeps track of all the points in a given island
func growIslands(rng: RandomNumberGenerator, area: Rect2, radius: float, p_radius: float, match_range: float, variance: float, curve: float, matched: Array, parents: Dictionary, indexed: Dictionary, max_tries = 3):
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

	return [ matched, parents, indexed ]


func resize_and_fill(pool, size:int, value=0):
	if size < 1:
		return null
	pool.resize(1)
	pool[0]=value
	while pool.size() << 1 <= size:
		pool.append_array(pool)
	if pool.size() < size:
		pool.append_array(pool.subarray(0,size-pool.size()-1))
	return pool





