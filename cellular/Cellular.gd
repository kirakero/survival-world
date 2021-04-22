extends Node
class_name Cellular

var map: PoolArrayGrid = null
var chanceToStartAlive = 0.4
var deathLimit = 3
var birthLimit = 4
var numberOfSteps = 4
var world_pos: Vector2
var rng: RandomNumberGenerator
var size: int
var growth_ease: float = 1.0
var simplex_scale: float = 1.0
var subdivisions: int = 1.0
var busy = false
signal generate_done(newimg)

func _init(rng: RandomNumberGenerator, size: int, world_pos: Vector2):
	map = PoolArrayGrid.new(size, size)
	assert(map != null)
	self.numberOfSteps = int(size / 10) + 3
	self.rng = rng
	self.world_pos = world_pos
	self.size = size

func generate_new():
	if busy:
		return null
	busy = true
	init_map()
	add_child(map)
	map.queue(preload("res://shader/brush/cellular.shader"), {
		'u_birth': birthLimit,
		'u_death': deathLimit,
		'u_scale': simplex_scale,
		'u_offset': world_pos
	}, numberOfSteps)
	map.queue_command(preload("res://shader/command/FloodFillPBA.gd"), {
		"origin": map.size * 0.5, 
		"value": 255,
		"low":   127,
		"high":  127,
	}, 1)
	map.queue(preload("res://shader/brush/regrade.shader"), {
		'u_delta': -0.5,
	}, 1)
	map.queue(preload("res://shader/brush/regrade.shader"), {
		'u_delta': 0.5,
		'u_low': 0.25,
		'post_2x': 1, # upsample the image after this shader is processed
	}, 1)
	map.queue(preload("res://shader/brush/upscale.shader"), {
		'post_2x': 1, # upsample the image after this shader is processed
	}, 1)
	map.queue(preload("res://shader/brush/upscale.shader"), {
		'post_2x': 1, # upsample the image after this shader is processed
	}, 1)
	map.queue(preload("res://shader/brush/upscale.shader"), {
	}, 1)
	# roughness pass
	map.queue(preload("res://shader/brush/cellular.shader"), {
		'u_birth': 3,
		'u_death': 3,
		'u_scale': 20,
		'u_offset': world_pos
	}, 6)
	map.queue(preload("res://shader/brush/cellular.shader"), {
		'u_birth': 1,
		'u_death': 2,
		'u_scale': 20,
		'u_offset': world_pos
	}, 2)

	map.render(true)
	yield(map, "render_done")
	emit_signal("generate_done", map)
	busy = false

func generate():
	init_map()
	var img = Image.new()
	img.create_from_data(map.size.x, map.size.y, false, Image.FORMAT_L8, map.pa)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)

	var renderer = Renderer.new(map.size)
	add_child(renderer)
	renderer.set_brush_shader(preload("res://shader/brush/cellular.shader"))
	renderer.set_image(img, tex)
	renderer.set_brush_shader_param('u_birth', birthLimit)
	renderer.set_brush_shader_param('u_death', deathLimit)
	renderer.set_brush_shader_param('u_scale', simplex_scale)
	renderer.set_brush_shader_param('u_offset', world_pos)
	renderer.loop(numberOfSteps)
	if numberOfSteps > 0:
		var out = yield(renderer, "loop_done")
		
		out.convert(Image.FORMAT_L8)
		map.pa = out.get_data()
	
	emit_signal("generate_done", map)
	# this is the slow way
	# iter_map()
	

# removes all islands not part of the main island
func denoise():
	# change grade
	map.regrade(-127, 0, 127)
	# set the center island to be 2
	map.flood_fill(map.size * 0.5, 255, 127, 127)
	# set all values that are not 2 to 0
	map.regrade(-127, 0, 127)

	map.flood_fill(map.size * 0.5, 255, 127, 127)
	pass

func init_map():
	map = PoolArrayGrid.new(size, size)
	var center = map.size * 0.5
	var max_dist = center.length()
	for x in range(map.size.x):
		for y in range(map.size.y):
			var p_dist = (center - Vector2(x, y)).length()
			var centerness = ease(1.0 - p_dist / max_dist, growth_ease)

			if (rng.randf() < chanceToStartAlive * centerness):
				map.write(x, y, 1)
	map.writev(center, 1)
   

func iter_map():
	var dying = []
	var spawning = []
	var simplex = OpenSimplexNoise.new()
	simplex.seed = rng.seed
	simplex.octaves = 6
	simplex.period = 3	
	for x in range(map.size.x):
		for y in range(map.size.y):
			var nbs = countAliveNeighbours(x, y)
			# if alive
			if(nbs < deathLimit && map.read(x, y) > 0):
				# cell death
				dying.append(Vector2(x, y))
					
			# if empty
			else:
				# simplex.get_noise_2d(x + world_pos.x, y + world_pos.y)
#				if nbs > birthLimit - (x%2 + y%2) % 2:
				if nbs > birthLimit - simplex.get_noise_2d(x + world_pos.x, y + world_pos.y):
					spawning.append(Vector2(x, y))     

	# apply changes
	for c in dying:
		map.write(c.x, c.y, 0)
	for c in spawning:
		map.write(c.x, c.y, 1)
		
	# the center must always be alive
	map.write(int(map.size.x * 0.5), int(map.size.y * 0.5), 1)

func countAliveNeighbours(x, y) -> int:
	var count = 0;
	var iter = 0
	for i in range(x-1, x+2):
		for j in range(y-1, y+2):
			iter = iter + 1
			if not map.has(i, j) || map.has(i, j) && map.read(i, j) == 0:
				continue
			count = count + 1
			
	return count


 



