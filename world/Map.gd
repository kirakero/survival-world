extends Node
class_name Map

# this is the main PBA that stores the master height map
var pba_alpha: PoolByteArray
# this is used for blending additional shapes
var pba_beta: PoolByteArray

var pba_debug: PoolByteArray



var oceans: = []
var rivers: = []
var rivers2: = []

var ffTool = preload("res://tool/FloodFill.gd").new()

var config: MapSettings

func _init(config: MapSettings):
	self.config = config
	pba_debug = PoolByteArray()
	pba_debug.resize(config.width * config.height * 4)
	pass

func generate():
	pba_alpha = _get_heightmap(config.randomseed, config.width, config.height, 3)
#	print(' size ',pba_alpha.size())
#	pba_beta = _get_heightmap(config.randomseed+1, config.width, config.height, 2)

	# add the super deep areas to the map
#	pba_alpha = _get_blended_pba_range(pba_alpha, pba_beta, 0, config.H_WATER)
	print(' a size ',pba_alpha.size())
	#print (pba_alpha[0])
	create_oceans()
	for i in range(1):
		create_river(rivers2[i])
	
	var base_pba = PoolByteArray()
	base_pba.resize(pba_alpha.size() * 4)
	var iter = 0
	for i in pba_alpha.size():
		var byte = pba_alpha[i]
		var i_out = i * 4
		if pba_debug[i_out+3] > 0:
			base_pba[i_out] = pba_debug[i_out]
			base_pba[i_out+1] = pba_debug[i_out+1]
			base_pba[i_out+2] = pba_debug[i_out+2]
			base_pba[i_out+3] = pba_debug[i_out+3]
		elif byte <= config.H_WATER:
			base_pba[i_out] = int(byte * 0.5)
			base_pba[i_out+1] = int(byte)
			base_pba[i_out+2] = int(255 - byte * 0.5)
			base_pba[i_out+3] = 255
		elif byte <= config.H_WATER + 16:
			base_pba[i_out] = int(byte * 0.5)
			base_pba[i_out+1] = int(255 - byte * 0.5)
			base_pba[i_out+2] = int(byte)
			base_pba[i_out+3] = 255
		elif byte <= config.H_WATER + 32:
			base_pba[i_out] = int(byte * 0.75)
			base_pba[i_out+1] = int(255 - byte * 0.25)
			base_pba[i_out+2] = int(byte)
			base_pba[i_out+3] = 255
		else:
			base_pba[i_out] = int(byte)
			base_pba[i_out+1] = int(byte)
			base_pba[i_out+2] = int(byte)
			base_pba[i_out+3] = 255
			
	# river debug
#	base_pba = debug_river(base_pba)
	
	var img = Image.new()
	img.create_from_data(config.width, config.height, false, Image.FORMAT_RGBA8, base_pba)
	
	img.save_png("res://savegame/test.png")

	pass

func debug_river(pba4):
	for river in rivers:
		var line = Curve2D.new()
		line.add_point(river.edge.a)
		line.add_point(river.edge.b)
		line.bake_interval = 2
		river.edge._debug()
		config._debug()
		for point in line.get_baked_points():
			var p = floor(point.x) * 4 + floor(point.y) * config.width * 4
			pba4[p] = 255
			pba4[p+1] = 255
			pba4[p+2] = 255
	
	return pba4

func create_oceans():
	var deeps = []
	var masks = []
	var rivers_index = []
	var centers = []
	
	for x in range(config.detection_rate, config.width, config.detection_rate):
		for y in range(config.detection_rate, config.height, config.detection_rate):
			var p = x + y * config.width
			if pba_alpha[p] <= config.H_DEEP:
				deeps.append(config._spacing_snap(x, y))
	
	var ocean_factory = preload("res://world/Ocean.gd")
	var river_factory = preload("res://world/RiverV2.gd")
	var mask_pba = PoolByteArray()
	mask_pba.resize(pba_alpha.size())
	for d in deeps:
		var mask_r = _flood_fill_array(pba_alpha, mask_pba, d, 0, config.H_DEEP, config.width, config.height, config.SPACING, config.MAX_OCEAN_SIZE)
		var mask = mask_r[0]
		mask_pba = mask_r[1]
		var mask_edge = mask_r[2]
			
		if mask.size() < 10:
			continue

		var ocean = ocean_factory.new(self.config, mask, mask_edge)
		oceans.append(ocean)
		
		var allscores = []
		
		for i in range(0, mask_edge.size()):
			var byte = int(mask_edge[i].x * 4) + int(mask_edge[i].y) * config.width * 4
			pba_debug[byte] = 255
			pba_debug[byte+1] = 255
			pba_debug[byte+2] = 255
			pba_debug[byte+3] = 255
			
			
			var offmap = 20
			if mask_edge[i].x - offmap < 0 or mask_edge[i].y - offmap < 0  or mask_edge[i].x + offmap > config.width or mask_edge[i].y + offmap > config.height:
				continue
			
			# if the direction is towards water, ignore
			var relative = mask_edge[i] - ocean.center
			var score = 0
			var testrange = 9
			var highest = 0
			for t in range(1, testrange):
				var normal = relative.normalized() * 30 * t 
				var relative2 = mask_edge[i] + normal
				
				if relative2.x < 0 or relative2.x > config.width - 1 or relative2.y < 0 or relative2.y > config.height - 1:
					continue
				var tp = int(relative2.x) + int(relative2.y) * config.width
			
				if pba_alpha[tp] > config.H_WATER:
					# prefer low terrain over high terrain
					score = score + t * 0.25 * (float(config.H_WATER) / float(pba_alpha[tp]))
					if t > 2 and pba_alpha[tp] < highest: # we are over a hill, scenic point
						score = score + 1 - pba_alpha[tp] / highest
				elif pba_alpha[tp] <= config.H_WATER:
					score = score - (testrange - t * 1)
				
				if (highest < pba_alpha[tp]):
					highest = pba_alpha[tp]
#				tp = int(relative2.x * 4) + int(relative2.y) * config.width* 4
#				pba_debug[tp] = 255
#				pba_debug[tp+3] = 255
				
			if score < 3:
				continue
			
			if allscores.size() == 0:
				allscores.append([score, i, false])
			else:
				var index = 1
				while (index <= allscores.size() && score < allscores[index-1][0]):
					index = index + 1
				allscores.insert(index - 1, [score, i, false])

				
#			var line = Curve2D.new()
#			line.add_point(mask_edge[i])
#			line.add_point(ocean.center)
#			line.bake_interval = 2
#			for point in line.get_baked_points():
#				var p = int(point.x) * 4 + int(point.y) * config.width * 4
#				pba_debug[p] = 255
#				pba_debug[p+1] = 255
#				pba_debug[p+2] = 10
#				pba_debug[p+3] = 255


#		print('scores')
		for ai in range(allscores.size()):
			if allscores[ai][2]:
				debug_square_score(mask_edge[allscores[ai][1]], allscores[ai][0], Color.orange)
				continue # this one should be skipped
			# use the strongest
			debug_geodir_score(mask_edge[allscores[ai][1]], (mask_edge[allscores[ai][1]] - ocean.center).normalized(), allscores[ai][0])
			allscores[ai][2] = true # use this one
			# add the river
			rivers2.append(river_factory.new(ocean, mask_edge[allscores[ai][1]]))
			
			for ai2 in range(allscores.size()):
				if not allscores[ai2][2]:
					# calculate distance from used one
					var n1 = (mask_edge[allscores[ai][1]] - ocean.center).normalized()
					var n2 = (mask_edge[allscores[ai2][1]] - ocean.center).normalized()
#					print ([n1, n2, n1.distance_to(n2)])
					if n1.distance_to(n2) < 0.75:
						allscores[ai2][2] = true # used by proximity
		
#			
#	for byte in range(mask_pba.size()):
#		if mask_pba[byte] > 0:
#			pba_alpha[byte] = 255

func debug_square_score(position, size, color = Color.yellow):
#	print ('debug ', [position, size])
	for x in range(size):
		for y in range(size):
			var p = int(position.x + x - size * 0.5) * 4 + int(position.y + y - size * 0.5) * config.width * 4
			pba_debug[p] = color.r * 255
			pba_debug[p+1] = color.g * 255
			pba_debug[p+2] = color.b * 255
			pba_debug[p+3] = 255

func dfLine(O: Vector2, dir: Vector2, P: Vector2):
	var D = dir.normalized()
	var X = O + D * (P-O).dot(D)
	return P.distance_to(X)


func debug_geodir_score(position, direction: Vector2, size, color = Color.yellow, inner = 0.6, outer = 2.0):
#	print ('debug ', [position, size])
	for x in range(-size*outer, size*outer):
		for y in range(-size*outer, size*outer):
			var d = Vector2(x,y).distance_to(Vector2.ZERO)
			if d < inner * size or d > size:
				if direction.dot(Vector2(x,y)) < 0 or dfLine(Vector2.ZERO, direction,  Vector2(x,y)) > inner * size * 0.25:
					continue
			var p = int(position.x + x) * 4 + int(position.y + y) * config.width * 4
			pba_debug[p] = color.r * 255
			pba_debug[p+1] = color.g * 255
			pba_debug[p+2] = color.b * 255
			pba_debug[p+3] = 255

func create_river(river: RiverV2):
	var turtle_pos = river.start
	var turtle_dir = river.forward
	var turtle_speed = 20
	var turtle_climb = 12.0
	print ('river ',[turtle_pos, turtle_dir])
	
	# force the turtle to the lands!
	turtle_pos = turtle_pos + turtle_dir * turtle_speed
	debug_geodir_score(turtle_pos + turtle_dir * turtle_speed, turtle_dir, 4, Color.magenta)
	for i in [Color.purple, Color.black, Color.red, Color.blue, Color.yellow, Color.cyan, Color.blue, Color.yellow, Color.cyan]:
		print ('turtle ',[turtle_pos, turtle_dir])
		turtle_dir = ball(turtle_pos, turtle_dir, turtle_climb)
		turtle_pos = turtle_pos + turtle_dir * turtle_speed
		debug_geodir_score(turtle_pos + turtle_dir * turtle_speed, turtle_dir, 4, i)
	pass

func ball(pos: Vector2, forward: Vector2, climb: float):
	var avg = 0
	var line = []
	# define directions
	var directions = [
		Vector2(-1, -1),
		Vector2(0, -1),
		Vector2(+1, -1),
		Vector2(+1, 0),
		Vector2(-1, +1),
		Vector2(0, +1),
		Vector2(-1, +1),
		Vector2(-1, 0),
	]
	var ball = 0
	var last_height = 0
	var first_height = 0
	for direction in directions:
		var p = pos.x + direction.x + (pos.y + direction.y) * config.width
		var h = pba_alpha[p]
		avg = avg + h
	avg = avg / 8
	for direction in directions:
		var p = pos.x + direction.x + (pos.y + direction.y) * config.width
		var h = pba_alpha[p]
		var diff_from_avg
		if h > avg:
			diff_from_avg = clamp(h - climb - avg, -1, h)
			print ('climb ', diff_from_avg)
		else:
			diff_from_avg = abs(h - avg)
	
		var dotp = direction.dot(forward)
		if dotp < 0.25:
			# make the difference stronger
			diff_from_avg = diff_from_avg + 2.0 * 2.0 - dotp
		if dotp > 0.66:
			ball = line.size()
			first_height = diff_from_avg
			last_height = first_height
		line.append(diff_from_avg)
	
	print ('facing ', directions[ball])
	var moves = 3
	while (moves):
		moves = moves - 1
		# if we go left, is it better than last_height?
		if line[(ball + 7) % 8] < last_height:
			last_height = line[(ball + 7) % 8]
			ball = (ball + 7) % 8
		elif line[(ball + 1) % 8] < last_height:
			last_height = line[(ball + 1) % 8]
			ball = (ball + 1) % 8
			
		elif line[(ball + 6) % 8] < last_height:
			last_height = line[(ball + 6) % 8]
			ball = (ball + 10) % 8
		elif line[(ball + 2) % 8] < last_height:
			last_height = line[(ball + 2) % 8]
			ball = (ball + 2) % 8
	# blend the ball position with forward
	var new_dir = forward
	var sample = pow((line[(ball + 7) % 8]), 1.5) + 2
	var sample2 = pow((line[(ball + 1) % 8]), 1.5) + 2
	if sample < sample2:
		print ('blend', [new_dir,directions[(ball + 7) % 8], (last_height+1.0)/sample])
		new_dir = new_dir.linear_interpolate(directions[(ball + 7) % 8], (last_height+1.0)/sample)
	else:
		print ('blend', [new_dir,directions[(ball + 1) % 8], (last_height+1.0)/sample2])
		new_dir = new_dir.linear_interpolate(directions[(ball + 1) % 8], (last_height+1.0)/sample2)
	print (line, [ball], new_dir)
	return new_dir

func create_rivers():
	var river_factory = preload("res://world/River.gd")
	
	var iter = 0
	for s in range(oceans.size()):
		var ocean_s: Ocean = oceans[s]
#		print ('ocean s ', ocean_s.center)
		while ocean_s.can_link_river() and iter < 100:
			# make sure we arent infinite looping where there are no oceans
			iter = iter + 1
			var discovered = []
			for e in range(oceans.size()):
				var ocean_e: Ocean = oceans[e]
#				print ('ocean e ', ocean_e.center)
				if ocean_e.center == ocean_s.center:
					continue
				if ocean_e.can_link_river(ocean_s):
					# find the closest points
					var closest = _closest_points_in_arrays(ocean_s.detect_map, ocean_e.detect_map)
					
					if closest.distance < config.detection_rate * 2.0:
						# they are touching
#						print('touching')
						continue
					if pba_alpha[closest.midpoint.x + closest.midpoint.y * config.width] <= config.H_DEEP:
						# they are separated by water - not really a river
#						print('water sep')
						continue
					
					if not closest:
						continue
#					print ('found closest', closest)
					# we can link the rivers
					var river: River = river_factory.new([ocean_s, ocean_e], closest)
					if discovered.size() < 2:
						discovered.append(river)
					elif discovered[0].edge.distance > closest.distance:
						discovered[0] = river
					elif discovered[1].edge.distance > closest.distance:
						discovered[1] = river
						
			for river in discovered:
				rivers.append(river)
				river.oceans[0].add_river(river)
				river.oceans[1].add_river(river)
			

func _closest_points_in_arrays(arr1, arr2):
	var distance = INF
	var edge = null
	
	for i1 in range(arr1.size()):
		for i2 in range(arr2.size()):
			var p1:Vector2 = arr1[i1]
			var p2:Vector2 = arr2[i2]
			var _d = p1.distance_to(p2)
			if (_d < distance && _d < config.MAX_RIVER_DISTANCE):
				distance = _d
				edge = preload("res://tool/Vector2Edge.gd").new(p1,p2)

	return edge
				
# todo update the scary blend code
func _get_blended_pba_range(base, mod, range_low, range_high):
	for d in range(base.size()):
		if mod[d] <= range_high and mod[d] >= range_low:
			print('set the base', int(clamp(base[d] - (clamp(config.H_WATER - mod[d],0,config._SHALLOWS)) - clamp(pow(clamp((config.H_DEEP - mod[d]),0.0, config.H_DEEP),config._DEEPENING), 0, config.H_DEEP), 1, 255)))
			base[d] = int(clamp(base[d] - (clamp(config.H_WATER - mod[d],0,config._SHALLOWS)) - clamp(pow(clamp((config.H_DEEP - mod[d]),0.0, config.H_DEEP),config._DEEPENING), 0, config.H_DEEP), 1, 255))
			
			
	return base

func _get_heightmap(_seed, _width, _height, _octaves = 6, _period = 240) -> PoolByteArray:
	var noise = OpenSimplexNoise.new()
	var pba_out = PoolByteArray()
	noise.seed = _seed
	noise.octaves = _octaves
	noise.period = _period
	noise.lacunarity = 2.0
	noise.persistence = 0.5
	var adjust = 0
	var height = 0
	for x in range(_height):
		for y in range(_width):
			height = (noise.get_noise_2d(y, x) + 1.0) * 128
#			print (height)
			pba_out.append(int(height))
	return pba_out
		
func _flood_fill_array(bytearray, mask, origin, low, high, width, height, spacing = 1, max_distance = 128) -> Array:	
	var array = []
	var array_edge = []
	
	var stack := [origin]
	var DIRECTIONS = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT
	]
	
	var op = 0
	while not stack.empty():

		var current = stack.pop_back()
		
		var pc = int((current.x) + (current.y) * width)
		mask[pc] = 1
		array.append(current)
		
		var dir_match = 0
		for direction in DIRECTIONS:
			var coordinates = current + direction * spacing
			
			if coordinates.x < 0.0 or coordinates.x > width - 1.0 or coordinates.y < 0.0 or coordinates.y > height - 1.0:
				continue
			
			if origin.distance_to(coordinates) > max_distance:
				dir_match = dir_match + 1
				continue
			
			var p = int((coordinates.x) + (coordinates.y) * width)
			if mask[p] > 0:			
				dir_match = dir_match + 1
				continue
			
			if bytearray[p] < low or bytearray[p] > high:
				continue

			stack.append(coordinates)
			dir_match = dir_match + 1
			
		if dir_match < 3:
			array_edge.append(current)
	return [array, mask, array_edge]
		
		
		
		
		
