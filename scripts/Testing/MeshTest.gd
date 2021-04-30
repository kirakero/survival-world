extends Spatial


func _ready():
	
#
#	testheigh2bytes([255, 255, 8192])
#	testheigh2bytes([0, 0, -8191.75])
#
#	return
	var data = PoolByteArray()
	var simplex = OpenSimplexNoise.new()
	simplex.seed = 2
	simplex.octaves = 1
	simplex.period = 22
	print (Vector3(2,4,-2).normalized())
	var testsize = 32
	for i in range(0, (testsize + 2)*4, 4):
		for j in range(0, (testsize + 2 )*4, 4):
			var h = int((simplex.get_noise_2d(i, j)) * 3 * 4) / 4
			var _h = MeshChunk.height2bytes(h)
			# set the basic height to 508
			assert(_h[0] != 0)
			data.append(_h[0])
			data.append(_h[1])
			data.append(0)
			data.append(0)
			testheigh2bytes([_h[0], _h[1], h])
#			print ([h])
	print( 'heights in size ', data.size() / 4)
	var chunk = MeshChunk.new(null, data, 0, 0, testsize)
	var ma = MeshInstance.new()
	ma.mesh = chunk.generate_chunk()
	ResourceSaver.save("res://test.tres", ma.mesh, 32)
	add_child(ma)


func testheigh2bytes(bytes):
	var joined = MeshChunk.bytes2height(bytes[0], bytes[1])
	assert(joined == bytes[2])
	var split = MeshChunk.height2bytes(joined)
	assert(split[0] == bytes[0] && split[1] == bytes[1])
	#print(bytes)



