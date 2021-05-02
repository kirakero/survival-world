extends Reference

var scene: Node
var api: Api
var player: Node
var max_range_chunk
var min_range_chunk_unload
var chunk_size
var world_half
var loaded_chunks: QuadTree
var loaded_ref = {}
var received_chunks
var render_queue = []
var unload_queue = []
var disabled = false
var processing = false
var mutex: Mutex
var noise
var threads: = []

func _init(_api: Api, _scene: Node, _player: Node):
	scene = _scene
	player = _player
	api = _api
	chunk_size = api.config.chunk_size
	max_range_chunk = 128
	# this determines when a chunk is actually unloaded
	min_range_chunk_unload = max_range_chunk + chunk_size
	world_half = int(api.config.world_size * 0.5)
	loaded_chunks = QuadTree.new(0, 0, api.config.world_size)

	noise = OpenSimplexNoise.new()
	noise.seed = 2
	noise.octaves = 6
	noise.period = 240
	
	threads = [ Thread.new(), Thread.new(), ]

func run():
	if processing:
		return
	# Do not run if we have nothing to do
	# Use disabled so that the service can be tracked easily later
	if disabled and api.dirty_objects_client[ Api.TYPE_CHUNK ].size() == 0:
		return
		
	disabled = false
	processing = true
	
	call_deferred('_run')
	

func _run():
	var pos_x = int(player.translation.x / chunk_size) * chunk_size + world_half
	var pos_z = int(player.translation.z / chunk_size) * chunk_size + world_half
	
	# Determine which chunks we'd like to see
	var desired = QuadTree.new(0, 0, api.config.world_size)
	desired.operation(QuadTree.OP_ADD, pos_x - max_range_chunk, pos_z - max_range_chunk, max_range_chunk*2)
	
	# Determine which chunks we'd like to see
	var undesired = QuadTree.new(0, 0, api.config.world_size)
	undesired.operation(QuadTree.OP_ADD, pos_x - min_range_chunk_unload, pos_z - min_range_chunk_unload, min_range_chunk_unload*2)

	# Remove chunks already loaded
	var need_load = QuadTree.intersect(loaded_chunks, desired, QuadTree.INTERSECT_KEEP_B)
	# Determine which chunks to unload
	var need_unload = QuadTree.intersect(loaded_chunks, undesired, QuadTree.INTERSECT_KEEP_A)
	
	# Dirty objects must be loaded if they are part of the desired set
	# This ensures that updates to the entire chunk are processed
	# Clear the dirty as fast as possible
	api.dirty_objects_mutex.lock()
	var dirty_chunks = api.dirty_objects_client[ Api.TYPE_CHUNK ]
	api.dirty_objects_client[ Api.TYPE_CHUNK ].empty()
	api.dirty_objects_mutex.unlock()
	
	# Do the dirty work
	for item in dirty_chunks:
		var i = api.objects[ Api.TYPE_CHUNK ][ item ]
		if desired.query( int(i['pos_x']), int(i['pos_y']), chunk_size ).size() > 0:
			need_load.operation(QuadTree.OP_ADD, int(i['pos_x']), int(i['pos_y']), chunk_size)
	
	# Remove chunks not available for loading
	var can_load = QuadTree.intersect(received_chunks, need_load, QuadTree.INTERSECT_KEEP_B)

	# If there are no chunks to load, we are waiting for data
	if can_load.is_empty():
		disabled = true
		return
	
	var can_load_all = can_load.all()
	var can_unload_all = need_unload.all()
	mutex.lock()
	for item in can_load_all:
		render_queue[ Api.make_chunk_key(item.x - world_half, item.y - world_half) ] = true
	mutex.unlock()
	
	# Removing chunks should be pretty cheap so...
	for item in can_unload_all:
		var key = Api.make_chunk_key(item.x - world_half, item.y - world_half)
		loaded_ref[ key ].queue_free()
		mutex.lock()
		loaded_ref.erase(key)
		loaded_chunks.operation(QuadTree.OP_SUBTRACT, item.x, item.y, chunk_size)
		mutex.unlock()
	
	processing = false

func render_process():
	mutex.lock()
	if threads.size() == 0 or render_queue.size() == 0:
		mutex.unlock()
		return
	var thread = threads.pop_front()
	var key = render_queue.pop_front()
	mutex.unlock()
	thread.start(self, "render_chunk", [key, thread])

func render_chunk(_data):
	var key = _data[0]
	var thread = _data[1]
	var data = api.objects[ Api.TYPE_CHUNK ][ key ]
	var uncompressed = data['chunk'].decompress(pow(chunk_size + 2, 2) * 4)
	var mesh_chunk = MeshChunk.new(noise, uncompressed, data['pos_x'] / chunk_size, data['pos_y'] / chunk_size, chunk_size)
	mesh_chunk.name = 'Chunk %s' % key
	mesh_chunk.translation = Vector3(data['pos_x'], 0, data['pos_y'])
	call_deferred('render_done', key, thread)

func render_done(key, thread, mesh_chunk: MeshChunk):
	thread.wait_to_finish()
	mutex.lock()
	loaded_ref[key] = mesh_chunk
	loaded_chunks.operation(QuadTree.OP_ADD, mesh_chunk.translation.x + world_half, mesh_chunk.translation.y + world_half, chunk_size)
	var next = render_queue.pop_front()
	if next != null:
		thread.start(self, "render_chunk", [key, thread])
	else:
		threads.append(thread)
	mutex.unlock()
	scene.call_deferred('add_child', mesh_chunk)















