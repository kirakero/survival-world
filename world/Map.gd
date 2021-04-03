extends Node
class_name Map

# this is the main PBA that stores the master height map
var pba_alpha: PoolByteArray
# this is used for blending additional shapes
var pba_beta: PoolByteArray

var oceans: = []
var rivers: = []

var ffTool = preload("res://tool/FloodFill.gd").new()

var config: MapSettings

func _init(config: MapSettings):
	self.config = config
	pass

func generate():
	pba_alpha = _get_heightmap(config.randomseed, config.width, config.height)
	pba_beta = _get_heightmap(config.randomseed+1, config.width, config.height)

	# add the super deep areas to the map
	# pba_alpha = _get_blended_pba_range(pba_alpha, pba_beta, 0, config.H_WATER)
	#print (pba_alpha[0])
	#create_oceans()
	#create_rivers()
	
	var base_pba = PoolByteArray()
	for byte in pba_alpha:
		
		if byte <= config.H_WATER:
			base_pba.append(byte * 0.5)
			base_pba.append(byte)
			base_pba.append(255 - byte * 0.5)
			base_pba.append(255)
		elif byte <= config.H_WATER + 16:
			base_pba.append(byte * 0.5)
			base_pba.append(255 - byte * 0.5)
			base_pba.append(byte)
			base_pba.append(255)
	
	print(' size ',base_pba.size())
	var img = Image.new()
	img.create_from_data(config.width, config.height, false, Image.FORMAT_RGBA8, base_pba)
	
	img.save_png("res://savegame/test.png")

	pass


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
	var mask_pba = PoolByteArray()
	mask_pba.resize(pba_alpha.size())
	for d in deeps:
		var mask_r = _flood_fill_array(pba_alpha, mask_pba, d, 0, 60, config.width, config.height, config.SPACING)
		var mask = mask_r[0]
		mask_pba = mask_r[1]
		print('found mask ', mask.size())
#		if mask.size() < 10:
#			continue
#
#		oceans.append(ocean_factory.new(self, mask))

func create_rivers():
	var river_factory = preload("res://world/River.gd")
	for s in range(oceans.size()):
		var ocean_s: Ocean = oceans[s]
		var iter = 5
		while ocean_s.can_link_river() and iter < 5:
			# make sure we arent infinite looping where there are no oceans
			iter = iter + 1
			for e in range(oceans.size()):
				var ocean_e: Ocean = oceans[e]
				if ocean_e.can_link_river(ocean_s):
					# find the closest points
					var closest = _closest_points_in_arrays(ocean_s.detect_map, ocean_e.detect_map)
					if not closest:
						continue
					# we can link the rivers
					var river: River = river_factory.new([ocean_s, ocean_e], closest)
					rivers.append(river)
					ocean_s.add_river(river)
					ocean_e.add_river(river)

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
	
	var height = 0
	for x in range(_width):
		for y in range(_height):
			height = int(noise.get_noise_3d(x, 0, y) * 255) + 128
#			print (height)
			pba_out.append(height)
	return pba_out
		
func _flood_fill_array(bytearray, mask, origin, low, high, width, height, spacing = 1) -> Array:
	print ('_flood_fill_array params', [origin, low, high, width, height, spacing])
	
	
	var array = []
	
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

		for direction in DIRECTIONS:
			var coordinates = current + direction * spacing
			
			if coordinates.x < 0.0 or coordinates.x > width - 1.0 or coordinates.y < 0.0 or coordinates.y > height - 1.0:
				continue
			
			var p = int((coordinates.x) + (coordinates.y) * width)
			if mask[p] > 0:
				continue
			
			if bytearray[p] < low or bytearray[p] > high:
				continue

			if coordinates.x == 100 and coordinates.y == 60:
				print('found the chosen one', bytearray[p]  )
			stack.append(coordinates)
#			if (op == 10000):
##				for i in stack:
##				print(stack)
#				print('fource return')
#				return [array, mask]
		
		
		op = op + 1
	return [array, mask]
		
		
		
		
		
