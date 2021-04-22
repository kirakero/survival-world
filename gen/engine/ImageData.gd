extends Node
class_name ImageData

var pa: PoolByteArray
var size: Vector2
var renderer: Renderer
var queue: Array = []
var thread: Thread
var format

var shader_stale = false
signal render_done
signal command_done

# Pool Array Grid
func _init(size, format = Image.FORMAT_L8, init_val = 0, pa = PoolByteArray()):
	if pa.size() == 0:
		self.pa = resize_and_fill(pa, size.x * size.y, init_val)
	else:
		self.pa = pa
	self.size = size
	self.format = format
	
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

func init_renderer(container):
	print ('init renderer with size ', size)
	var img = Image.new()
	img.create_from_data(size.x, size.y, false, Image.FORMAT_L8, pa)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)

	renderer = Renderer.new(size)
	renderer.set_image(img, tex)
	container.add_child(renderer)

func teardown_renderer(container):
	container.remove_child(renderer)
	renderer.queue_free()
	renderer = null
