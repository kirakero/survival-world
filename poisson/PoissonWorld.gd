tool
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
	generate_lake()

func setsize(val):
	size = int(val)
	generate_lake()

func setwater(val):
	water = val
	coordinator = null
	generate_lake()

func setwaterdeep(val):
	waterdeep = val
	generate_lake()
	
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

func generate_lake():
	if not $Sprite:
		return
	var msec = OS.get_ticks_msec()
	call_deferred("genTest")
	print("took: ", OS.get_ticks_msec() - msec)
#	var rng = RandomNumberGenerator.new()
#	rng.seed = 10
#	var extent = Rect2(0, 0, 100, 100)
#	var center = extent.size * 0.5
#
	# render each island and draw them
##	var simplex = OpenSimplexNoise.new()
##	simplex.seed = rng.seed
##	simplex.octaves = 6
##	simplex.period = 3
##
#	var msec = OS.get_ticks_msec()
##	var _lake = generateLake(rng, simplex, extent, center, size)
#	call_deferred("genTest")
#	print("took: ", OS.get_ticks_msec() - msec)
##
##	var data = PoolByteArray()
##	data = resize_and_fill(data, extent.size.x * extent.size.y * 4, 35)
##
##	var lakewidth = size * 2.0
##	for x in range(0, size):
##		for y in range(0, size):
##			var p = (x + center.x - int(size*0.5)) * 4 + (y + center.y - int(size*0.5)) * 4 * extent.size.x
##			var ip = (x) + (y) * size
##			data[p] = lake[ip] * 255
##			data[p+1] = lake[ip] * 255
##			data[p+2] = lake[ip] * 255
##			data[p+3] = 255	
##
##	var img = Image.new()
##	img.create_from_data(extent.size.x, extent.size.y, false, Image.FORMAT_RGBA8, data)
##	var tex = ImageTexture.new()
##	tex.create_from_image(img, 0)
##
##	var renderer = Renderer.new(extent.size)
##	add_child(renderer)
##	renderer.set_brush_shader(preload("res://shader/brush/erode.shader"))
##	renderer.set_image(img, tex)
##	renderer.set_brush_shader_param('u_factor', factor)
##	renderer.set_brush_shader_param('u_low', lowval)
##	for i in range(iter):
##		renderer.iterate()
##		img = yield(renderer, "texture_region_changed")
##		var newtex = ImageTexture.new()
##		tex.create_from_image(img, 0)
#
##	$Sprite.set_texture( tex )
#
#
#func generate():
#
#	var testsize = 400
#	var world_dim = Vector2(testsize, testsize)
#	var c_size = world_dim.x * 0.05
#
##	var min_islands = 10
#
#	var pass1_radius = world_dim.x * 0.029
#	var pass1_poissonradius = world_dim.x * 0.055
#	var pass1_range = world_dim.x * 0.05 * 1.2
#	var pass1_variance = 0.2
#	var pass1_noisecurve = -1.8
#
#	var pass2_radius = world_dim.x * 0.01
#	var pass2_poissonradius = world_dim.x * 0.07
#	var pass2_range = world_dim.x * 0.05 * 1.25
#	var pass2_variance = 0.6
#	var pass2_noisecurve = -0.2
#
#	var c_range = c_size * 1.5
#	var c_range_spawn = world_dim.x * 0.16
#	var c_edge_buffer = Vector2(c_range, c_range) # do not put points here
#
#	var spawn_area_island = Rect2(c_edge_buffer * 2.0, world_dim - c_edge_buffer * 4.0)
#	var spawn_area_large = Rect2(c_edge_buffer, world_dim - c_edge_buffer*2.0)
#	var spawn_area_small = Rect2(c_edge_buffer * 0.5, world_dim - c_edge_buffer)
#
#	# Process
#	var rng = RandomNumberGenerator.new()
#	rng.seed = 44
#
#	# determine the spawn points and setup the variables
#	var matched
#	var parents
#	var indexed
#	var res
#	res = makeIslands(rng, spawn_area_island, c_range_spawn)
#	matched = res[0]
#	parents = res[1]
#	indexed = res[2]
#
#	# make the first pass - this grows the continent using large pieces
#	res = growIslands(rng, spawn_area_large, world_dim.x * 0.035, pass1_poissonradius, pass1_range, pass1_variance, 0.2, matched, parents, indexed, 1)
#	matched = res[0]
#	parents = res[1]
#	indexed = res[2]
#
#	# make the first pass - this grows the continent using large pieces
#	res = growIslands(rng, spawn_area_large, pass1_radius, pass1_poissonradius, pass1_range, pass1_variance, pass1_noisecurve, matched, parents, indexed, 1)
#	matched = res[0]
#	parents = res[1]
#	indexed = res[2]
#
#	# make the second pass - this grows the continent using small pieces
#	res = growIslands(rng, spawn_area_small, pass2_radius, pass2_poissonradius, pass2_range, pass2_variance, pass2_noisecurve, matched, parents, indexed, 3)
#	matched = res[0]
#	parents = res[1]
#	indexed = res[2]
#
#	# make the second pass - this grows the continent using small pieces
#	res = growIslands(rng, spawn_area_small, pass2_radius * 0.75, pass2_poissonradius, pass2_range * 0.85, 0.4, pass2_noisecurve, matched, parents, indexed, 3)
#	matched = res[0]
#	parents = res[1]
#	indexed = res[2]
#
#	# make the second pass - this grows the continent using small pieces
#	res = growIslands(rng, spawn_area_small, pass2_radius * 0.75, pass2_poissonradius, pass2_range * 0.85, 0.4, pass2_noisecurve, matched, parents, indexed, 3)
#	matched = res[0]
#	parents = res[1]
#	indexed = res[2]
#
#	# collect the points into the pre-rendering data
#	var islands
#	var extents
#	res = assembleIslands(rng, indexed, ceil(c_size), world_dim * 0.5, 0)
#	islands = res[0]
#	extents = res[1]
#
#	# render each island and draw them
#	var simplex = OpenSimplexNoise.new()
#	simplex.seed = rng.seed
#	simplex.octaves = 5
#	simplex.period = 6
#
#	var data = PoolByteArray()
#	data = resize_and_fill(data, world_dim.x * world_dim.y * 4, 35)
#
#	var _colors = [Color.orange, Color.red, Color.green, Color.yellow, Color.silver, Color.pink, Color.white, Color.purple, Color.teal, Color.lavender]
#	var colors = []
#	for col in _colors:
#		colors.append(col)
#		colors.append(col * 0.5)
#
#	for k in islands.size():
#		var bytes = renderIsland(islands[k], extents[k], simplex)
#
#		for x in range(0, extents[k].size.x):
#			for y in range(0, extents[k].size.y):
#
#				if x + extents[k].position.x > world_dim.x or x + extents[k].position.x < 0:
#					continue
#				if y + extents[k].position.y > world_dim.y or y + extents[k].position.y < 0:
#					continue	
#				if bytes[x + y * extents[k].size.x] < 200:
#					continue
#				# translate the extents into world coords for the output byte array
#				var p = (x + extents[k].position.x) * 4 + (y + extents[k].position.y) * 4 * world_dim.x
#
#				data[p] = colors[k % colors.size()].r * bytes[x + y * extents[k].size.x]
#				data[p+1] = colors[k % colors.size()].g * bytes[x + y * extents[k].size.x]
#				data[p+2] = colors[k % colors.size()].b * bytes[x + y * extents[k].size.x]
#				data[p+3] = 255
#
#	var img = Image.new()
#	img.create_from_data(testsize, testsize, false, Image.FORMAT_RGBA8, data)
#	var tex = ImageTexture.new()
#	tex.create_from_image(img, 0)
#
#	var sprite: Sprite = $Sprite
#	sprite.set_texture(tex)
#
##func gen():
##	var testsize = 256
##	var dim = Vector2(testsize, testsize)
##	var c_size = dim.x * 0.05
##	var c_range = c_size * 1.25
##	var c_range_spawn = dim.x * 0.3
##	var c_edge_buffer = Vector2(c_range, c_range) # do not put points here
##	var c_pcount = 4 # how many points can join together to one mass
##	var rngseed = 28
##	var max_tries = 3
##	var rng = RandomNumberGenerator.new()
##	rng.seed = rngseed
##	# determine the continents
##	var c_points = PoissonDiscSampling.new().generate_points(rngseed, c_size, Rect2(c_edge_buffer, dim - c_edge_buffer*2.0), 20)
##	var c_points_tiny = PoissonDiscSampling.new().generate_points(rngseed, c_size, Rect2(c_edge_buffer, dim - c_edge_buffer*2.0), 20)
##	var c_points_spawn = PoissonDiscSampling.new().generate_points(rngseed, c_range_spawn, Rect2(c_edge_buffer * 2.0, dim - c_edge_buffer * 4.0), 20)
##
##	var c_points_match = c_points_spawn
##	var c_points_parent = {}
##	var c_points_out = {}
##	var c_points_tries = {}
##	for cp in c_points_spawn:
##		var k = vector2key(cp)
##		c_points_parent[k] = k
##		c_points_out[k] = [cp]
##
##	while c_points.size():
##		var p = c_points.pop_back()
##		var matched_i = null
##		var matched_d = testsize
##		for i in c_points_match:
##			var d = i.distance_to(p)
##			if d < c_range and d < matched_d:
##				matched_d = d
##				matched_i = i
##
##		if matched_i:
##			# set the parent of this point
##			c_points_parent[ vector2key(p) ] = c_points_parent[ vector2key(matched_i) ]
##			# add this point to findable points, growing the mass
##			c_points_match.append(p) 
##			# add this point to the indexed points for the mass
##			c_points_out[ c_points_parent[ vector2key(matched_i) ] ].append(p)
##		else:
##			var k = vector2key(p)
##			if not c_points_tries.has(k):
##				c_points.push_front(p)
##				c_points_tries[k] = 1
##			elif c_points_tries[k] < max_tries:
##				c_points.push_front(p)
##				c_points_tries[k] = c_points_tries[k] + 1
##
##
##	var data = PoolByteArray()
##	data.resize(testsize * testsize * 4)
##	for i in data.size():
##		data[i] = 0
##
##	var colors = [Color.orange, Color.red, Color.green, Color.yellow, Color.silver, Color.pink, Color.white, Color.purple, Color.teal, Color.lavender]
##
##
##	var _color = Color.black
##	for p in range(0, data.size(), 4):
##		data[p] = _color.r * 255
##		data[p+1] = _color.g * 255
##		data[p+2] = _color.b * 255
##		data[p+3] = 255
##
##	var nc = 0
##	var simplex = OpenSimplexNoise.new()
##	simplex.seed = rngseed
##	simplex.octaves = 5
##	simplex.period = 6
##	for group in c_points_out.keys():
##
##
##		var all_points = Vector2.ZERO
##		for point in c_points_out[group]:
##			all_points = all_points + point
##
##		all_points = all_points / c_points_out[group].size()
##
##		# setup initial group and determine extents
##		var points_index = []
##		var extent_low = dim
##		var extent_high = Vector2.ZERO
##		for point in c_points_out[group]:
##			var r = rng.randf_range(1.0, 3.5)
##			point = point.move_toward(all_points, r * 2.5)
##			points_index.append([point, 6 - r])
##			if point.x < extent_low.x:
##				extent_low.x = point.x
##			if point.y < extent_low.y:
##				extent_low.y = point.y
##			if point.x > extent_high.x:
##				extent_high.x = point.x
##			if point.y > extent_high.y:
##				extent_high.y = point.y
##
##		var c_size_plus = c_size + 3.5
##		extent_low = extent_low - Vector2(c_size_plus, c_size_plus)
##		extent_high = extent_high + Vector2(c_size_plus, c_size_plus)
##		_color = colors[nc]
##		nc = (nc + 1) % colors.size()
##
##
##		for x in range(extent_low.x, extent_high.x, 1):
##			for y in range(extent_low.y, extent_high.y, 1):
##				var closest_c = null
##				var closest = dim.x
##				for point in points_index:
##					var d = Vector2(x,y).distance_to(point[0])
##					if d < c_range and d < closest:
##						closest = d
##						closest_c = point
##
##
##				if closest < dim.x:
##					var true_weight = closest_c[1] * c_range * 0.15
##					if true_weight - closest + simplex.get_noise_2d(x, y) * 6.0 < 0:
##						continue
##					_color = colors[nc]
##
##					var p = x * 4 + y * 4 * dim.y
##					data[p] = _color.r * 255
##					data[p+1] = _color.g * 255
##					data[p+2] = _color.b * 255
##					data[p+3] = 255
##
##
##
##
##
##	var img = Image.new()
##	img.create_from_data(testsize, testsize, false, Image.FORMAT_RGBA8, data)
##	var tex = ImageTexture.new()
##	tex.create_from_image(img, 0)
##
##
##	$Sprite.set_texture(tex)
#
#func vector2key(key_vector: Vector2):
#	return str(int(key_vector.x),',',int(key_vector.y))
#
## convert the island into a mask
#func renderIsland(points: Array, extents: Rect2, simplex: OpenSimplexNoise):
#	var mask = PoolByteArray()
#	mask = resize_and_fill(mask, int(extents.size.x) * int(extents.size.y), 0)
#
#	for x in range(0, extents.size.x, 1):
#		for y in range(0, extents.size.y, 1):
#
#			var closest_c = null
#			var closest = INF
#			var w_point = Vector2(x,y) + extents.position
#			for point in points:
#				if not point[1]:
#					continue
#				var d = w_point.distance_to(point[0])
#				# radius is the original radius of the poisson sample
#				# here we can adjust it to be more or less island like
#
#				var radius = point[1] * (1.0 + point[2])
#				if d - radius < 0 and d < closest:
#					closest = d
#					closest_c = point
#
#			if closest_c:
#				if not closest_c[1]:
#					continue
#
#				# 1 is high, 0 is low
#				var noise = (simplex.get_noise_2d(w_point.x, w_point.y) + 1) * 0.45
#				assert (noise >= 0 and noise <= 1)
#				# 1 is on the point, 0 is off point
#				var closeness = 1.0 - closest / (closest_c[1] * (1.0 + closest_c[2])) 
#				var base_height = 1
#				base_height = ease(closeness, float(closest_c[3]))
#
#				assert (closeness >= 0 and closeness <= 1)
#
#				var height = max(noise * (1.0 + closeness), base_height)
#				if height < 0.5:
#					continue
#				var p = x + y * extents.size.x
#				mask[p] = 255
#
##	return denoise( denoise( mask , extents.size.x, 1, 3, 2) , extents.size.x, 2, 4, 2)
#
##func renderLakes(rng: RandomNumberGenerator, island: PoolByteArray, extents: Rect2):
##	island = denoise( island, extents.size.x, 2, 6, 1, 200)
##
##
##	pass
#

#
##func genLake(rng: RandomNumberGenerator, simplex: OpenSimplexNoise, extent: Rect2, center: Vector2, size: float):
##	if busy:
##		return false
##	busy = true
##	var lake = Cellular.new(rng, size, Vector2.ZERO)
##	add_child(lake)
##	lake.numberOfSteps = iter
##	lake.growth_ease = gease
##	lake.simplex_scale = dfactor
##	lake.world_pos = Vector2(worldpos_x, worldpos_y)
##	lake.generate_new()
##
###	yield(lake,"generate_done")
##
##	var img = Image.new()
##	print('set size to ', lake.map.size)
##	img.create_from_data( lake.map.size.x, lake.map.size.y, false, Image.FORMAT_L8, lake.map.pa)
##	var tex = ImageTexture.new()
##	tex.create_from_image(img, 0)
##	$Sprite.set_texture( tex )
##
##	busy = false
#
##func generateLake(rng: RandomNumberGenerator, simplex: OpenSimplexNoise, extent: Rect2, center: Vector2, size: float):
##	print('generateLake')
##	return call_deferred("genTest")
##
##	return genLake(rng, simplex, extent, center, size)
##	var lake = Cellular.new(rng, size, Vector2.ZERO)
##	add_child(lake)
##	lake.numberOfSteps = iter
##	lake.growth_ease = gease
##	lake.simplex_scale = dfactor
##	lake.world_pos = Vector2(worldpos_x, worldpos_y)
##	lake.generate()
##
##	yield(lake,"generate_done")
##
###	lake.denoise()
##	var img = Image.new()
##	img.create_from_data(size, size, false, Image.FORMAT_L8, lake.map.pa)
##	var tex = ImageTexture.new()
##	tex.create_from_image(img, 0)
##	$Sprite.set_texture( tex )
#
##	var pointsize = size * 0.25
##	var psizedraw = pointsize * 0.25
##	var overdraw = pointsize * 0.5
##
##	simplex.octaves = 6
##	simplex.period = dfactor
##
##	var simplex2 = OpenSimplexNoise.new()
##	simplex2.seed = simplex.seed
##	simplex2.octaves = 2
##	simplex2.period = 2
##
##	var randomwidth = rng.randf_range(pointsize, size)
##	var randomheight = rng.randf_range(pointsize, size)
##	var points = PoissonDiscSampling.new().generate_points(rng, pointsize, Rect2(0, 0, randomwidth, randomheight), 10)
##
##	points = Geometry.convex_hull_2d(points)
##
##	var points_inner = points
##	for point in points_inner:
##		point = point.move_toward(Vector2(size*0.5, size*0.5), point.distance_to(Vector2(size*0.25, size*0.25)) * spread)
###	for point in PoissonDiscSampling.new().generate_points(rng, pointsize, Rect2(0, 0, randomwidth, randomheight).grow(-overdraw*2), 10):
###		points.append(point)
##
##	var mask = resize_and_fill( PoolByteArray(), size * size, lowval )
##
##
##
##	for x in range(size):
##		for y in range(size):
##			var point = Vector2(x, y)
##			if not Geometry.is_point_in_polygon(point, points):
##				continue
##
##			var pba = x + y * size
##			var val = (simplex.get_noise_2d(x / pointsize, y / pointsize) + 1.0) * highval + 1
##
##			mask[pba] = clamp(val, lowval, highval)
##
#
##	var psizewithover = overdraw + psizedraw
#	# squish points and height mask
##	for point in points:
##		point = point.move_toward(Vector2(size*0.5, size*0.5), point.distance_to(Vector2(size*0.25, size*0.25)) * spread)
##		# draw
##		for x in range(-floor(psizewithover), ceil(psizewithover), 1):
##			for y in range(-floor(psizewithover), ceil(psizewithover), 1):
##				# check distance so we draw circles
##
##				var a = Vector2(x, y).angle_to(Vector2(size*0.5, size*0.5))
##				if a > PI:
##					a = a - PI * 2
##				var d = int(Vector2(x, y).length()) - (simplex2.get_noise_2d(a, (point.y + point.x) * 100) - 1.0) * psizedraw * dfactor
##				if d >= psizedraw + overdraw:
##					continue
##				# this will draw in the range of point to the mask coords
##				var p = int(point.x) + x + (int(point.y) + y) * size
##				if p > 0 and p < mask.size():
##					var newval = 0
##					if d >= psizedraw:
##						newval = (simplex.get_noise_2d(point.x + x , point.y + y) + 1.0) * lerp(highval, lowval, (d - psizedraw) / overdraw) + 1
##
##					else:
##						newval = (simplex.get_noise_2d(point.x + x , point.y + y) + 1.0) * highval + 1
##					mask[p] = clamp(max(newval, mask[p]), 0, 255)
###	return mask	
#
##	mask = erodelow(mask, size, Vector2(rng.randf_range(0.05, 0.15), rng.randf_range(0.15, 0.25))* size / lowval, lowval)
##	mask = erodehigh(mask, size, Vector2(rng.randf_range(0.05, 0.25), rng.randf_range(0.05, 0.25))* size / lowval, lowval)
#
##	return mask	
#
#func erodehigh(mask, size, shape, low):
#	var nm = resize_and_fill( PoolByteArray(), size * size, 0 )
#	print (mask.size())
#	for x in range(0, size, 1):
#		for y in range(0, size, 1):
#			if mask[x + y * size] > low:
#				nm[x + y * size] = clamp(erodemax(mask, Vector2(size, size), Vector2(x, y), shape, 1.0, 60), low, 255)
#
#	return nm
#
#func erodelow(mask, size, shape, low):
#	var nm = resize_and_fill( PoolByteArray(), size * size, 0 )
#	print (mask.size())
#	for x in range(0, size, 1):
#		for y in range(0, size, 1):
#			if mask[x + y * size] > low:
#				nm[x + y * size] = clamp(erode(mask, Vector2(size, size), Vector2(x, y), shape, 1.0), low, 255)
#
#	return nm
#
## based on https://github.com/Zylann/godot_heightmap_plugin/blob/master/addons/zylann.hterrain/tools/brush/shaders/erode.shader
#func erode(mask: PoolByteArray, mask_dim: Vector2, uv: Vector2, pixel_size: Vector2, weight: float):
#	var r: float = 3.0
#
#	# Divide so the shader stays neighbor dependent 1 pixel across.
#	var eps: Vector2 = pixel_size / (0.99 * r)
#	var h: float = mask[uv.x + uv.y * mask_dim.x]
#	var eh: float = h
#
#	# Morphology with circular structuring element
#	for y in range(-r, r, 1):
#		for x in range(-r, r, 1):
#			var p = Vector2(x, y)
#			var mpv = uv + p * eps
#			mpv.x = int(mpv.x)
#			mpv.y = int(mpv.y)
#			if mpv.x < 0 or mpv.y < 0 or mpv.x >= mask_dim.x or mpv.y >= mask_dim.y:
#				continue
#			var mp = int(mpv.x + mpv.y * mask_dim.x)
#			var nh: float = mask[mp]
#
#			var s: float = max(p.length() - r, 0)
#			eh = min(eh, nh + s)
#
#	return lerp(h, eh, weight);
#
#func erodemax(mask: PoolByteArray, mask_dim: Vector2, uv: Vector2, pixel_size: Vector2, weight: float, ignore = 50):
#	var r: float = 3.0
#
#	# Divide so the shader stays neighbor dependent 1 pixel across.
#	var eps: Vector2 = pixel_size / (0.99 * r)
#	var h: float = mask[uv.x + uv.y * mask_dim.x]
#	var eh: float = h
#
#	# Morphology with circular structuring element
#	for y in range(-r, r, 1):
#		for x in range(-r, r, 1):
#			var p = Vector2(x, y)
#			var mpv = uv + p * eps
#			mpv.x = int(mpv.x)
#			mpv.y = int(mpv.y)
#			if mpv.x < 0 or mpv.y < 0 or mpv.x >= mask_dim.x or mpv.y >= mask_dim.y:
#				continue
#			var mp = int(mpv.x + mpv.y * mask_dim.x)
#			var nh: float = mask[mp]
#			if nh <= ignore:
#				continue
#			var s: float = max(p.length() - r, 0)
#			eh = max(eh, nh + s)
#
#	return lerp(h, eh, weight);
#
#
#
#
#func denoise(points: PoolByteArray, width: int, size: int = 1, sensitivity: int = 2, iter: int = 1, fill: int = 255) -> PoolByteArray:
#	var rg = pow(size * 2 + 1, 2) - sensitivity
#	var already = []
#	for i in points.size():
#		var total = 0
#		var hits = 0
#		if points[i] == 0:
#			for x in range(-int(size), int(size)+1):
#				for y in range(-int(size), int(size)+1):
#					var p = i + x + (y * width)
#					if p >= 0 and p < points.size():
#						if points[p] == 200:
#							continue
#						total = total + points[p]
#						hits = hits + 1
#
#			if total >= 255 * rg && not already.has(i):
#				points[i] = fill
#				already.append(i)
##				print ([total, hits])
#	iter = iter - 1
#	if iter == 0:
#		return points
#
#	return denoise(points, width, size, sensitivity, iter)
#
#func outline(points: PoolByteArray, width: int, size: int = 1) -> PoolByteArray:
#	for i in points.size():
#		var total = 0
#		var hits = 0
#		if points[i] == 0:
#			for x in range(-int(size), int(size)+1):
#				for y in range(-int(size), int(size)+1):
#					var p = i + x + (y * width)
#					if p >= 0 and p < points.size():
#						if points[p] == 200:
#							continue
#						total = total + points[p]
#						hits = hits + 1
#
#						if total > 0:
#							print ([p, x, total, hits, points[p]])
#			if total / hits > 255/8:
#				points[i] = 200
##				print ([total, hits])
#
#	return points
#
#func assembleIslands(rng: RandomNumberGenerator, matched: Dictionary, margin: float, center: Vector2, spread: float = 0):
#	var out = []
#	var extents = []
#	for group in matched.keys():
#		var points_index = []
#		# Determine center of the island
#		var all_points = Vector2.ZERO
#		for point in matched[group]:
#			all_points = all_points + point[0]
#
#		all_points = all_points / matched[group].size()
#
#		# Determine extents and assemble the preprocessing point data
#		var extent_low = Vector2(INF, INF)
#		var extent_high = Vector2.ZERO
#		for point in matched[group]:
#			var r = rng.randf_range(1.0, 3.5)
#			point[0] = point[0].move_toward(all_points, r * 2.5)
##			point[1] = 6 - r #todo change me
#			points_index.append(point)
#			if point[0].x < extent_low.x:
#				extent_low.x = point[0].x
#			if point[0].y < extent_low.y:
#				extent_low.y = point[0].y
#
#			if point[0].x > extent_high.x:
#				extent_high.x = point[0].x
#			if point[0].y > extent_high.y:
#				extent_high.y = point[0].y
#
#		var extent = Rect2(int(extent_low.x), int(extent_low.y), 0, 0)
#		extent.end = Vector2(int(extent_high.x), int(extent_high.y))
#		extent = extent.grow(margin)
#
##		# island spacing
##		var dir = (extent.position + extent.size * 0.5) - center
##		var mag = abs(dir.distance_to(Vector2.ZERO) / center.distance_to(Vector2.ZERO) * spread)
##		dir = dir.normalized()
##		extent.position = extent.position + dir * mag
##		print(['modify', extent.position + extent.size * 0.5, dir, mag])
##		extent.position = Vector2(int(extent.position.x), int(extent.position.y))
#
#		extents.append(extent)
#		out.append(points_index)
#
#
#	return [ out, extents ]
#
#func makeIslands(rng: RandomNumberGenerator, area: Rect2, radius: float, min_islands: int = 5):
#	var c_points_spawn = []
#	var iter = 0
#	while c_points_spawn.size() < min_islands + 1 and iter < 10:
#		c_points_spawn = PoissonDiscSampling.new().generate_points(rng, radius, area, 20)
#		iter = iter + 1
#
#	var center = Vector2(area.position + area.size * 0.5)
#	var d = INF
#	var p = null
#	for i in c_points_spawn:
#		if i.distance_to(center) < d:
#			d = i.distance_to(center)
#			p = i
#
#	var matched = []
#	for i in c_points_spawn:
#		if i != p:
#			matched.append([ i, null, null, 1, false ])
#	var parents = {}
#	var indexed = {}
#
#	for cp in c_points_spawn:
#		var k = vector2key(cp)
#		parents[k] = k
#		var r = null
#		if cp == p:
#			r = 10
#		indexed[k] = [[ cp, r, 1, cp == p ]]
#
#	return [ matched, parents, indexed ]
#
## matched - points that are recognized as found and can be grown from
#### matched[] have a special format
## parents - tracks the parents for all points
## indexed - keeps track of all the points in a given island
#func growIslands(rng: RandomNumberGenerator, area: Rect2, radius: float, p_radius: float, match_range: float, variance: float, curve: float, matched: Array, parents: Dictionary, indexed: Dictionary, max_tries = 3):
#	var c_points_tries = {}
#	var c_points = PoissonDiscSampling.new().generate_points(rng, p_radius, area, 20)
#
#	while c_points.size():
#		var p = c_points.pop_back()
#		var matched_i = null
#		var matched_d = INF
#		for i in matched:
#			var d = i[0].distance_to(p)
#			if d < match_range and d < matched_d:
#				matched_d = d
#				matched_i = i
#
#		var k = vector2key(p)
#		if matched_i:
#			# set the parent of this point
#			parents[ k ] = parents[ vector2key(matched_i[0]) ]
#			# add this point to findable points, growing the mass
#			# we also store the original radius for later
#			# as well as the random variance
#			var new_point = [ p, radius, rng.randf_range( 0, variance ), curve ]
#			matched.append(new_point) 
#			# add this point to the indexed points for the mass
#			indexed[ parents[ vector2key(matched_i[0]) ] ].append(new_point)
#		else:
#			if not c_points_tries.has(k):
#				c_points.push_front(p)
#				c_points_tries[k] = 1
#			elif c_points_tries[k] < max_tries:
#				c_points.push_front(p)
#				c_points_tries[k] = c_points_tries[k] + 1
#
#	return [ matched, parents, indexed ]
#
#
#func resize_and_fill(pool, size:int, value=0):
#	if size < 1:
#		return null
#	pool.resize(1)
#	pool[0]=value
#	while pool.size() << 1 <= size:
#		pool.append_array(pool)
#	if pool.size() < size:
#		pool.append_array(pool.subarray(0,size-pool.size()-1))
#	return pool
#




