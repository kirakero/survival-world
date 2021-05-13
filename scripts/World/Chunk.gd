extends Reference
class_name Chunk

var position: Vector2
var data: PoolByteArray
var obdata: PoolByteArray
var chunk_size: int
var heights: = []
var world_position

func _init(_position: Vector2):
	position = _position
	world_position = Vector3(position.x, 0, position.y)
	chunk_size = Global.DATA.config['chunk_size']

func set_ChunkData( _data, _obdata):
	data = _data #should already be uncompressed
	obdata = _obdata
	generate_heights()

func get_ChunkMesh():
	# todo clean this up when cyclic errors are a thing of the past
	var cm = preload("res://scripts/World/ChunkMesh.gd").new()
	cm.chunk_basic = self
	return cm

func get_key():
	return '%s,%s' % [position.x, position.y]

static func bytes2height(pixel_high, pixel_low):
	return ((((pixel_high & 0xff) << 8) | (pixel_low & 0xff))  - 65534/2) * 0.25

static func height2bytes(height):
	height = int(height * 4.0) + 65534/2
	var high = ((height >> 8) & 0xff)
	var low = height & 0xff
	return [high, low]

func height_from_local(position: Vector3):
	return _get_height_from_rounded( int(position.x), int(position.z) ) #todo interpolate

func _get_height_from_rounded(pos_x: int, pos_y: int):
	var i = (pos_x + 1) + (pos_y + 1 * (chunk_size + 2))
	if heights.size() > i:
		return heights[i]
	return 0

func generate_heights():
	var _heights = []
	var _ch_half = Vector3(chunk_size * 0.5, 0, chunk_size * 0.5)
	for _z in range(0, chunk_size + 2):
		for _x in range(0, chunk_size + 2):
			var pixel = (_x * 4) + (_z * (chunk_size + 2) * 4)
			var nh = -0.5
			if pixel < data.size():
				if data[pixel] == 255:
					nh = 1
#				nh = bytes2height(data[pixel], data[pixel + 1])
#				assert(data[pixel] != 0)
### removed -1 from being added to _x and _z
			_heights.append(Vector3(_x, nh,_z) - _ch_half)
	
	heights = _heights
