extends Node
class_name PoolArrayGrid

var pa: PoolByteArray
var size: Vector2
var renderer: Renderer
var queue: Array = []
var thread: Thread

var shader_stale = false
signal render_done
signal command_done

# Pool Array Grid
func _init(x, y, init_val = 0, pa = PoolByteArray()):
	if pa.size() == 0:
		self.pa = resize_and_fill(pa, x * y, init_val)
	else:
		self.pa = pa
	size = Vector2(x, y)
	
func read(x, y):
	var p = int(x) + int(y) * size.x
	return pa[p]

func write(x, y, value):
	var p = int(x) + int(y) * size.x
	pa[p] = value
	
func has(x, y) -> bool:
	return x >= 0 && y >= 0 && x < size.x && y < size.y
	
	
func readv(coords: Vector2):
	return read(coords.x, coords.y)

func writev(coords, value):
	write(coords.x, coords.y, value)
	
func hasv(coords: Vector2) -> bool:
	return has(coords.x, coords.y)

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

func clone():
	return duplicate()

func queue(shader: Shader, params: Dictionary = {}, iterations: int = 1) -> int:
	queue.append({
		"shader": shader,
		"params": params,
		"iterations": iterations,
	})
	return queue.size() - 1

func queue_command(command: Resource, params: Dictionary = {}, iterations: int = 1) -> int:
	queue.append({
		"command": command,
		"params": params,
		"iterations": iterations,
	})
	return queue.size() - 1
	
func render(keep_renderer = false):
	var job = queue.pop_front()
	if not job:
		return
	
	if not renderer:
		_init_renderer()
		if thread == null:
			thread = Thread.new()
	
	# if we performed a CPU function, we need to reimport the data into renderer
	if shader_stale:
		print('shader is stale, size > ', pa.size())
		var img = Image.new()
		img.create_from_data(size.x, size.y, false, Image.FORMAT_L8, pa)
		var tex = ImageTexture.new()
		tex.create_from_image(img, 0)
		renderer.set_image(img, tex)
		shader_stale = false
	
	if job.has('shader'):
		renderer.set_brush_shader( job['shader'] )
		for param in job['params'].keys():
			if param.substr(0,1) == 'u':
				renderer.set_brush_shader_param(param, job['params'][param])
		renderer.loop( job['iterations'] )
		if job['iterations'] > 0:
			var out: Image = yield(renderer, "loop_done")
			print('job loop', job)
			if job['params'].has('post_2x') and job['iterations'] <= job['params']['post_2x']:
				# we are going to upsample the image by 2x
				out.expand_x2_hq2x()
				size = size * 2
				_teardown_renderer()
			out.convert(Image.FORMAT_L8)
			pa = out.get_data()
			print('pa size is ', pa.size())
	elif job.has('command'):
		assert(not thread.is_active())
		thread.start(self, "_run_command", [thread, job])
		var res = yield(self, "command_done")
		shader_stale = true

	if queue.size() > 0:
		return render(keep_renderer)
	emit_signal("render_done")
	if not keep_renderer:
		_teardown_renderer()

func _init_renderer():
	print ('init renderer with size ', size)
	var img = Image.new()
	img.create_from_data(size.x, size.y, false, Image.FORMAT_L8, pa)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)

	renderer = Renderer.new(size)
	renderer.set_image(img, tex)
	add_child(renderer)

func _teardown_renderer():
	remove_child(renderer)
	renderer.queue_free()
	renderer = null

func _run_command(cmd):
	var thread = cmd[0]
	var job = cmd[1]
	var res = job['command'].new().run(self, job['params'])
	job['iterations'] = job['iterations'] - 1
	call_deferred('_end_command', thread, job, res)

func _end_command(thread, job, res):
	thread.wait_to_finish()
	if job['iterations'] < 1:
		emit_signal("command_done", res)
	else:
		assert(not thread.is_active())
		thread.start(self, "_run_command", [thread, job])

func flood_fill(origin: Vector2, value = null, low = 0, high = 255, spacing = 1) -> Array:
	var array := []
	var stack := [origin]
	var DIRECTIONS = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT
	]
	
	while not stack.empty():
		var current = stack.pop_back()
		array.append(current)
		if value:
			writev(current, value)
		for direction in DIRECTIONS:
			var coordinates = current + direction * spacing
			if coordinates in array || not hasv(coordinates):
				continue
			
			var val = readv(coordinates)
			
			if val < low or val > high:
				continue

			stack.append(coordinates)
			
	return array

func regrade(delta, minval, maxval):
	for i in range(pa.size()):
		pa[i] = clamp(pa[i] + delta, minval, maxval)
