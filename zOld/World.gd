extends Spatial

const chunk_size = 128
const chunk_amount = 4


var noise
var chunks = {}
var unready_chunks = {}
var thread
var save
var spacing = 10

var WATER_LEVEL = 127

func _ready():	
#	generate_world('world',2)
	noise = OpenSimplexNoise.new()
	noise.seed = 2
	noise.octaves = 6
	noise.period = 240
	thread = Thread.new()
	
	var config = preload("res://world/MapSettings.gd").new(2, Vector2(16, 8))
	var map = preload("res://world/Map.gd").new(config)
	map.generate()
	
func generate_world(world, randomseed):
	var save = preload("res://Save.gd").new(world)
	if (save.exists()):
		print('save already exists')
		#return

	save.create(randomseed)
	# determine the size and vertex spacing of the chunk data so we can store it
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_width = chunk_size * 0.5
	plane_mesh.subdivide_depth = chunk_size * 0.5
	
	var surface_tool = SurfaceTool.new()
	var data_tool = MeshDataTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var array_plane = surface_tool.commit()
	var error = data_tool.create_from_surface(array_plane, 0)
	
	var vbase = []
	for i in range(data_tool.get_vertex_count()):
		vbase.append(data_tool.get_vertex(i))
		
	# start randomness
	noise = OpenSimplexNoise.new()
	noise.seed = 2
	noise.octaves = 6
	noise.period = 240
	# world size is 10 x 10 chunks
	
	var world_size = 8
	
	var texture = NoiseTexture.new()
	texture.width = world_size * chunk_size
	texture.height = world_size * chunk_size
	texture.noise = noise
	yield(texture, "changed")
	var image = texture.get_data()
	
	# start randomness again
	var noise2 = OpenSimplexNoise.new()
	noise2.seed = 2+1
	noise2.octaves = 2
	noise2.period = 240
	var texture2 = NoiseTexture.new()
	texture2.width = world_size * chunk_size
	texture2.height = world_size * chunk_size
	texture2.noise = noise
	yield(texture2, "changed")
	var image2 = texture2.get_data()
	
	
	var base_pba: PoolByteArray = image.get_data()
	var mod_pba: PoolByteArray = image2.get_data()
	
	var width = world_size * chunk_size
	var height = world_size * chunk_size
	
	# base.b = clamp(base.b + clamp(mod.r - 0.6, 0, 0.4), 0, 1.0) original mountain code
	# since hieghtmaps are grayscale, we only need to check the red value to do this merge
	#+0 = red
	#+1 = blue
	#+2 = green
	#+3 = alpha
	var level = WATER_LEVEL
	var shallows = 8
	var deep = level - shallows
	var deepening = 1.2
	# the promotion of water into ocean
	var ocean = level - 50
	# how often to test for deeps
	var detection_rate = 64
	
	
	var ocean_pba = PoolByteArray()
	ocean_pba.resize(base_pba.size() * 0.25)
	
	for d in range(0, base_pba.size(), 4):
		if mod_pba[d] < WATER_LEVEL:
			base_pba[d] = int(clamp(base_pba[d] - (clamp(level - mod_pba[d],0,shallows)) - clamp(pow(clamp((deep - mod_pba[d]),0.0,deep),deepening), 0, deep), 0, 255))
			base_pba[d+1] = base_pba[d]
			base_pba[d+2] = base_pba[d]
			if base_pba[d] <= deep:
				ocean_pba[d * 0.25] = 1
	
	var deeps = []
	for x in range(detection_rate, width, detection_rate):
		for y in range(detection_rate, height, detection_rate):
			var p = x * 4 + y * width * 4
			if base_pba[p] <= deep:
				deeps.append(_spacing_snap(x, y))
				base_pba[p+1] = 255
				base_pba[p+2] = 255
	
	var masks = []
	var rivers_index = []
	var rivers = []
	var centers = []
	for d in deeps:
		var mask = _flood_fill(base_pba, d, 0, 90, width, height)
		if mask.size() < 10:
			continue
		masks.append(mask)
		var _x = 0
		var _y = 0
		for coord in mask:
			var p = ((coord[0]) * 4) + ((coord[1]) * width * 4)
			base_pba[p] = 255
			base_pba[p+1] = 255
			_x = _x + coord[0]
			_y = _y + coord[1]
		var center = _spacing_snap(_x/mask.size(), _y/mask.size())
		centers.append(center)
		
		print('mask is size', mask.size(),' and invocation param was', d,' and center is ', center)
	
	# setup the stamp pba
	var local_pba = PoolByteArray()
	local_pba.resize(base_pba.size() * 0.25)
	
				
	for i in range(masks.size()):
		if (masks[i].size() > 100):
			var distance = 1000
			var j = null
			for k in range(masks.size()):
				var _key = [centers[i], centers[k]]
				if centers[k][0] + centers[k][1] < centers[i][0] + centers[i][1]:
					_key = [centers[k], centers[i]]
				if k == i or rivers.has(_key):
					continue
				var _d = sqrt(pow(centers[k][0]-centers[i][0],2) + pow(centers[k][1]-centers[i][1],2))
				if (_d < distance):
					distance = _d
					j = k
			if j:
				var _key = [centers[i], centers[j]]
				if centers[j][0] + centers[j][1] < centers[i][0] + centers[i][1]:
					_key = [centers[j], centers[i]]
				
				# determine the closest points from the connected masks
				# this will help us to draw the river in a more natural way
				var p_dist = 1000
				var p1_close = null
				var p2_close = null
				for p1 in masks[i]:
					for p2 in masks[j]:
						var _d = sqrt(pow(p2[0]-p1[0],2) + pow(p2[1]-p1[1],2))
						if _d < p_dist:
							p_dist = _d
							p1_close = p1
							p2_close = p2
				
				rivers.append(_key)
				print('river ',_key,' between ',p1_close, ' and ', p2_close)
								
				var start_p = Vector2(p1_close[0], p1_close[1]) * 0.8 + Vector2(centers[i][0],centers[i][1]) * 0.2
				var end_p = Vector2(rand_range(p2_close[0], centers[j][0]), rand_range(p2_close[1], centers[j][1])) * 0.8 + Vector2(centers[j][0],centers[j][1]) * 0.2
			
				var dir = (start_p - end_p).normalized()
				var vector_perp = Vector2(dir.y, -dir.x)
				
				
				# find the center point
				var mid_p = Vector2((start_p[0] + end_p[0]) * 0.5, (start_p[1] + end_p[1]) * 0.5)
				# adjust the center point randomly
				# this will be used to give a basic shape to the river
				mid_p = mid_p + Vector2(rand_range(p_dist * 0.3, p_dist), 0.0) * vector_perp
				
				base_pba = _draw_debug(base_pba, mid_p, width, 255)
				base_pba = _draw_debug(base_pba, mid_p + Vector2.DOWN, width, 255)
				base_pba = _draw_debug(base_pba, mid_p + Vector2.DOWN*2, width, 255)
			
				var points = []
				var point_count = clamp(p_dist/rand_range(50,90), 2, 100)
				
				var curve: Curve2D = Curve2D.new()
			
				# determine the distance between two points
#				curve.add_point(start_p)
				base_pba = _draw_debug(base_pba, start_p, width, 255)
				var p_distance = start_p.linear_interpolate(end_p, 1.0 / float(point_count)) - start_p

				
				for p_index in range( 0, point_count ):
					
					# this is the point we are adding
					var next_point = _quadratic_bezier(start_p, mid_p, end_p, float(p_index) / float(point_count))
					
					
					# this is the point to the left or right of the point we are adding
					var control1 = p_distance * rand_range(-0.25, 1.0)
					control1 = control1.rotated(deg2rad(rand_range(80.0, 100.0)))
					control1 = control1 - p_distance * rand_range(0.35, 0.65)
					var control2 = control1 * -1.0
					
			
					
#					base_pba = _draw_debug(base_pba, control1 + next_point, width)
					base_pba = _draw_debug(base_pba, control2 + next_point, width, WATER_LEVEL)
					curve.add_point(next_point, control1, control2)
					
				
				curve.add_point(end_p)
				base_pba = _draw_debug(base_pba, end_p, width, 0)
#				for index in range(32):
#					var coord = _cubic_bezier(start_p, midpoint, midpoint2, end_p, index/32.0)
#				for coord in curve.get_baked_points():
#					coord = clamp_map(coord, width, height)
#					var p = (int(coord.x) * 4) + (int(coord.y) * width * 4)
#					base_pba[p] = 255
				
				var baked_points = curve.get_baked_points()
				

				var river_rad = preload("res://RiverRadiusTool.gd").new(curve, start_p, end_p)
				local_pba = curve_to_alphamask(curve, local_pba, ocean_pba, width, height, river_rad, rand_range(-35,-15), WATER_LEVEL+5)

	for byte in range(local_pba.size()):
		if local_pba[byte] != 0:
			base_pba[byte*4] = local_pba[byte] * 0.5 + base_pba[byte*4] * 0.5
			if (local_pba[byte] < WATER_LEVEL - 1):
				var change = 0.6
				while base_pba[byte*4] >= WATER_LEVEL:
					base_pba[byte*4] = local_pba[byte] * change + base_pba[byte*4] * (1.0 - change)
					change = change - 0.1

	var hit = 0
	for d in range(0, base_pba.size(), 4):
		
		hit = hit + 1
		if base_pba[d] <= WATER_LEVEL:
			base_pba[d] = base_pba[d] * 0.5
			base_pba[d+1] = base_pba[d]
			base_pba[d+2] = 255 - base_pba[d] * 0.5
		elif base_pba[d] <= WATER_LEVEL + 16:
			base_pba[d] = base_pba[d] * 0.5
			base_pba[d+1] = 255 - base_pba[d] * 0.5
			base_pba[d+2] = base_pba[d]
	print('hit ', hit,' size ',base_pba.size())
	var img = Image.new()
	img.create_from_data(world_size * chunk_size, world_size * chunk_size, false, Image.FORMAT_RGBA8, base_pba)
	
	img.save_png(save.path('height.png'))

# sample points on the curve to see if they hit within a radius of the curves points
# if they do, determine the closeness and write the value to given alpha mask PBA
func curve_to_alphamask(curve: Curve2D, pba: PoolByteArray, mask: PoolByteArray, width, height, rad_tool: RiverRadiusTool, amount, base_level, ease_curve = 2.6) -> PoolByteArray:
	# This is the array of walkable cells the algorithm outputs.
	var array := []
	var iter = 0
	var skip = 0
	# The way we implemented the flood fill here is by using a stack. In that stack, we store every
	# cell we want to apply the flood fill algorithm to.
	var stack := [curve.get_baked_points()[0]]
	
	var DIRECTIONS = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT
	]
	# We loop over cells in the stack, popping one cell on every loop iteration.
	while not stack.empty():
		var current = stack.pop_back()

		# If we meet all the conditions, we "fill" the `current` cell. To be more accurate, we store
		# it in our output `array` to later use them with the UnitPath and UnitOverlay classes.
		array.append(current)
		# We then look at the `current` cell's neighbors and, if they're not occupied and we haven't
		# visited them already, we add them to the stack for the next iteration.
		# This mechanism keeps the loop running until we found all cells the unit can walk.
		for direction in DIRECTIONS:
			var coordinates = current + direction
			# This is an "optimization". It does the same thing as our `if current in array:` above
			# but repeating it here with the neighbors skips some instructions.
			if coordinates in array:
				continue
			if coordinates.x < 0 or coordinates.x > width - 1 or coordinates.y < 0 or coordinates.y > height - 1:
				continue
							
			# are we in range of the curve?
			var distance = curve.get_closest_point(coordinates).distance_to(coordinates)

			# determine the depth
			var intensity = 1.0 - distance / rad_tool.radius(coordinates)
			if intensity < 0.0:
				continue
			
			#determine p so we can see if we are in the mask
			var p = coordinates[0] + coordinates[1] * width
			if mask[p] != 0:
				skip = skip + 1
				stack.append(coordinates)
				continue
			
			var val =  intensity * (amount)
			
			pba[p] = clamp(int(base_level + val), 0, 255)
			# This is where we extend the stack.
			stack.append(coordinates)
			iter = iter + 1
			
			
	print ('curve_to_alphamask iter ', iter,' mask hit ', skip)
	return pba


func is_in_map(point, w, h):
	if point.x < 0:
		return false
	if point.x >= w:
		return false
	if point.y < 0:
		return false
	if point.y >= w:
		return false
	return true

func clamp_map(point, w, h):
	if point.x < 0:
		point.x = 0
	if point.x >= w:
		point.x = w - 1
	if point.y < 0:
		point.y = 0
	if point.y >= w:
		point.y = h - 1
	return point

func _draw_debug(base_pba, p, width, color = 255):
	p = clamp_map(p, width-2, width)
	var _p = (int(p.x) * 4) + (int(p.y) * width * 4)
	base_pba[_p] = color
	base_pba[_p+1] = color
	_p = _p + 4
	base_pba[_p] = color
	base_pba[_p+1] = color
	_p = _p + 4
	base_pba[_p] = color
	base_pba[_p+1] = color
	return base_pba

func _spacing_snap(x, y):
	return [int(x/spacing)*spacing, int(y/spacing)*spacing]

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var q2 = p2.linear_interpolate(p3, t)

	var r0 = q0.linear_interpolate(q1, t)
	var r1 = q1.linear_interpolate(q2, t)

	var s = r0.linear_interpolate(r1, t)
	return s

# Returns an array with all the coordinates of walkable cells based on the `max_distance`.
func _flood_fill(bytearray, origin, low, high, width, height, offset = 0) -> Array:
	# This is the array of walkable cells the algorithm outputs.
	var array := []
	# The way we implemented the flood fill here is by using a stack. In that stack, we store every
	# cell we want to apply the flood fill algorithm to.
	var stack := [origin]
	var DIRECTIONS = [
		[0,spacing],[spacing,0],[-spacing,0],[0,-spacing]
	]
	# We loop over cells in the stack, popping one cell on every loop iteration.
	while not stack.empty():
		var current = stack.pop_back()

		# If we meet all the conditions, we "fill" the `current` cell. To be more accurate, we store
		# it in our output `array` to later use them with the UnitPath and UnitOverlay classes.
		array.append(current)
		# We then look at the `current` cell's neighbors and, if they're not occupied and we haven't
		# visited them already, we add them to the stack for the next iteration.
		# This mechanism keeps the loop running until we found all cells the unit can walk.
		for direction in DIRECTIONS:
			var coordinates = [current[0] + direction[0], current[1] + direction[1]]
			# This is an "optimization". It does the same thing as our `if current in array:` above
			# but repeating it here with the neighbors skips some instructions.
			if coordinates in array:
				continue
			if coordinates[0] < 0 or coordinates[0] > width - 1 or coordinates[1] < 0 or coordinates[1] > height - 1:
				continue
			var p = (coordinates[0]) * 4 + (coordinates[1]) * width * 4 + offset
			
			if bytearray[p] < low or bytearray[p] > high:
				continue

			# This is where we extend the stack.
			stack.append(coordinates)
			
			if stack.size() > 10000:
				return array
	return array


func fast_mask(bytearray, origin, low, high, width, height, offset = 0, radius = 8, inside = 0, mask = [], total = 0, count = 0):
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			if (x < -inside or x > inside) and (y < -inside or y > inside):
				if (sqrt(pow(x,2) + pow(y,2))) <= radius and (origin[0] + x) > 0 and (origin[1]+x) < width and (origin[1]+y) > 0 and (origin[1]+y) < height: #in the circle?
					var p = (origin[0] + x) * 4 + (origin[1]+y) * width * 4 + offset
					total = total + bytearray[p]
					count = count + 1
					mask.append([x, y])
	
	var density = total/count
	if density > low and density < high:
		return fast_mask(bytearray, origin, low, high, width, height, offset, radius, radius + 8, mask, total, count)
	
	print ('fast mask done, density is', density)
	return mask
			
# bytearray is the raw 4 byte image data
# origin is the point to check
# low is the lowest acceptable value to match
# high is the highest acceptable value to match
# width is how wide the image data x axis is
# offset is which byte to check RGBA
# found is an array contain Vector2 values that should not be checked
func get_mask(bytearray, origin, low, high, width, height, offset = 0, found = []):
	var p = origin[0] * 4 + origin[1] * width * 4 + offset
	if found.has(origin) or bytearray[p] < low or bytearray[p] > high:
#		print( bytearray[p] , high)
		return found
	found.append(origin)
	if (origin[0] < width - 1):
		found = get_mask(bytearray, [origin[0] + 1, origin[1]], low, high, width, height, offset, found)
	if (origin[0] > 0):
		found = get_mask(bytearray, [origin[0] - 1, origin[1]], low, high, width, height, offset, found)
	if (origin[1] > 0):
		found = get_mask(bytearray, [origin[0], origin[1] - 1], low, high, width, height, offset, found)
	if (origin[1] < height - 1):
		found = get_mask(bytearray, [origin[0], origin[1] + 1], low, high, width, height, offset, found)
	return found
		
func add_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key) or unready_chunks.has(key):
		return
	
	if not thread.is_active():
		thread.start(self, "load_chunk", [thread, x, z])
		unready_chunks[key] = 1
		
func load_chunk(array):
	var thread = array[0]
	var x = array[1]
	var z = array[2]
	
	var chunk = Chunk.new(noise, x * chunk_size, z * chunk_size, chunk_size)
	chunk.translation = Vector3(x * chunk_size, 0, z * chunk_size)
	
	call_deferred("load_done", chunk, thread)

func load_done(chunk, thread):
	add_child(chunk)
	var key = str(chunk.x / chunk_size) + "," + str(chunk.z / chunk_size)
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()
	
	var player_translation = $Player.translation
	var p_x = int(player_translation.x) / chunk_size
	var p_z = int(player_translation.z) / chunk_size
	if (chunk.x / chunk_size == p_x && chunk.z / chunk_size == p_z):
		$Player.physics_active = true
	
func get_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key):
		return chunks.get(key)
	
	return null

func _process(delta):
#	if (chunks.size() < chunk_amount * chunk_amount):
	update_chunks()
	clean_up_chunks()
	reset_chunks()
	
func update_chunks():
	var player_translation = $Player.translation
	var p_x = int(player_translation.x) / chunk_size
	var p_z = int(player_translation.z) / chunk_size
	
	for x in range(p_x - chunk_amount * 0.5, p_x + chunk_amount * 0.5):
		for z in range(p_z - chunk_amount * 0.5, p_z + chunk_amount * 0.5):
			add_chunk(x, z)
			var chunk = get_chunk(x, z)
			if chunk != null:
				chunk.should_remove = false
	
	
func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			chunk.queue_free()
			chunks.erase(key)
	pass
	
func reset_chunks():
	for key in chunks:
		chunks[key].should_remove = true
	
	
	

# x and z are world values, r determines the radius of the change
func _on_Player_remove_terrain(x, z, r = 2.0):
	print ('remove at', x, z, r)
#	var player_translation = $Player.translation
#	$Player.translation.y = $Player.translation.y + 2.0
	var affected_vertices = []
	var affected_chunks = []
	var total = 0
	for key in chunks:
		var chunk = chunks[key]
		if (abs(x - chunk.x) <= chunk_size * 0.5 + r && abs(z - chunk.z) <= chunk_size * 0.5 + r):
			print('hit terrain on', [chunk.x, chunk.z, x, z, abs(x - chunk.x), abs(z - chunk.z) ])
			var affected = chunk.get_vertices_near(x, z, r)
			affected_chunks.append([chunk, affected])
			for v in affected:
				affected_vertices.append(v)
				total = total + v[1].y

	if affected_vertices.size() > 0:
		var new_height = ceil((total / affected_vertices.size()) + 0.001)
		for affected_chunk in affected_chunks:
			var out_verts = []
			for affected_vertex in affected_chunk[1]:
				affected_vertex[1].y = new_height
				out_verts.append(affected_vertex)
			affected_chunk[0].patch_vertices(out_verts)
			
#		if (int(round(x / chunk_size)) == int(chunk.x / chunk_size) and int(round(z / chunk_size)) == int(chunk.z / chunk_size)):
#			print('hit terrain on', [chunk.x, chunk.z, x, z, int(x / chunk_size) , int(chunk.x / chunk_size) ,  int(round(x / chunk_size)) , int(round(z / chunk_size))])
##			var b = CSGBox.new()
##			b.translation = chunk.translation
##			b.translation.y = b.translation.y + 10.0
##			add_child(b)
#			print('player local space', [x - chunk.x, z - chunk.z])
#			chunk.remove_terrain(x, z, r)			
#		else:
#			print('no hit terrain', [chunk.x, chunk.z, x, z, int(x / chunk_size) , int(chunk.x / chunk_size) , int(z / chunk_size) , int(chunk.z / chunk_size)])
