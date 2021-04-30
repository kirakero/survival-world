extends Spatial
class_name MeshChunk

var mesh_instance
var noise
var x
var z
var data: PoolByteArray
var chunk_size
var should_remove = true 

func _init(noise, data, x, z, chunk_size):
	self.noise = noise
	self.x = x
	self.z = z
	self.chunk_size = chunk_size
	self.data = data
	
func _ready():
	generate_water()
	generate_chunk()

static func bytes2height(pixel_high, pixel_low):
	return ((((pixel_high & 0xff) << 8) | (pixel_low & 0xff))  - 65534/2) * 0.25

static func height2bytes(height):
	height = int(height * 4.0) + 65534/2
	var high = ((height >> 8) & 0xff)
	var low = height & 0xff
	return [high, low]

func generate_chunk():
	var mesh: ArrayMesh = ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	var verts = PoolVector3Array()
	verts.resize( (chunk_size + 1) * (chunk_size + 1) )
	var uvs = PoolVector2Array()
	uvs.resize( verts.size() )
	var normals = PoolVector3Array()
	normals.resize( verts.size() )
	var indices = PoolIntArray( )
	indices.resize( (chunk_size ) * (chunk_size ) * 6 )
	var vert_index = 0
	var index_index = 0
	
	var heights = []
	for _z in range(0, chunk_size + 2):
		for _x in range(0, chunk_size + 2):
			var pixel = (_x * 4) + (_z * (chunk_size + 2) * 4)
			var nh = bytes2height(data[pixel], data[pixel + 1])
			assert(data[pixel] != 0)
			heights.append(Vector3(x + _x - 1, nh, z + _z - 1))

	
	for _z in range(0, chunk_size + 1):
		for _x in range(0, chunk_size + 1):
			var t = _x + (_z - 1) * (chunk_size + 2)
			var b = _x + (_z + 1) * (chunk_size + 2)
			var l = _x - 1 + _z * (chunk_size + 2)
			var r = _x + 1 + _z * (chunk_size + 2)
			normals[ _x - 1 + (_z - 1) * (chunk_size + 1)] = Vector3(2*(heights[l].y-heights[r].y), 4, 2*(heights[t].y-heights[b].y)).normalized()


	for i in range(normals.size()):
		uvs[i] = Vector2.ONE
	
	for _z in range(1, chunk_size + 2):
		for _x in range(1, chunk_size + 2):
			verts[vert_index] = heights[_x + _z * (chunk_size + 2)]

			var vert_topleft = vert_index
			var vert_topright = vert_topleft + 1
			var vert_bottomleft = vert_topleft + chunk_size + 1
			var vert_bottomright = vert_bottomleft + 1

			if _x < chunk_size+1 and _z < chunk_size+1:
				indices[index_index + 0] = vert_topleft
				indices[index_index + 1] = vert_topright
				indices[index_index + 2] = vert_bottomleft
				indices[index_index + 3] = vert_topright
				indices[index_index + 4] = vert_bottomright
				indices[index_index + 5] = vert_bottomleft

				index_index = index_index + 6
			
			vert_index = vert_index + 1

	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	
	
	return mesh
	
func generate_water():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_width = chunk_size * 0.5
	plane_mesh.subdivide_depth = chunk_size * 0.5
	
	plane_mesh.material = preload("res://zOld/water.material")
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = plane_mesh
	add_child(mesh_instance)
