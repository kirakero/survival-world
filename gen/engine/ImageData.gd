extends Node
class_name ImageData

var pa: PoolByteArray
var size: Vector2
var renderer: Renderer
#var queue: Array = []
#var thread: Thread
var format
var _silence = true

#var shader_stale = false
#signal render_done
#signal command_done

# Pool Array Grid
func _init(_size, _format, init_val = 0, _pa = PoolByteArray(), _bitdepth = 4):
	if _pa.size() == 0:
		pa = resize_and_fill(_pa, int(_size.x) * int(_size.y) * _bitdepth, init_val)
	else:
		pa = _pa
	size = _size
	format = _format
	
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

func get_image() -> Image:
	var img = Image.new()
	img.create_from_data(size.x, size.y, false, format, pa)
	return img

func resize_2x():
	var img = get_image()
	img.expand_x2_hq2x()
	img.convert(format)
	size = img.get_size()
	pa = img.get_data()

func resize_and_fill(pool, _size:int, value=0):
	if _size < 1:
		return null
	pool.resize(1)
	pool[0]=value
	while pool.size() << 1 <= _size:
		pool.append_array(pool)
	if pool.size() < _size:
		pool.append_array(pool.subarray(0,_size-pool.size()-1))
	return pool

func init_renderer(container):
	if not _silence:
		print ('init renderer with size/format ', [size, format])
	var img = Image.new()
	img.create_from_data(size.x, size.y, false, format, pa)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)

	renderer = Renderer.new(size)
	renderer.set_image(img, tex)
	container.call_deferred("add_child", renderer)

func teardown_renderer(container):
	container.call_deferred("remove_child", renderer)
	
