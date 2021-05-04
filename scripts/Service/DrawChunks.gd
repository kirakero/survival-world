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
var received_chunks: QuadTree
var render_queue = []
var unload_queue = []
var disabled = false
var processing = false
var mutex: Mutex
var noise
var threads: = []
var client
var counter

func _init(_client: Node, _api: Api, _scene: Node, _player: Node):
	scene = _scene
	player = _player
	api = _api
	client = _client
	chunk_size = api.config.chunk_size
	max_range_chunk = 128
	# this determines when a chunk is actually unloaded
	min_range_chunk_unload = max_range_chunk + chunk_size
	world_half = int(api.config.world_size * 0.5)
	loaded_chunks = QuadTree.new(0, 0, api.config.world_size)
	received_chunks = QuadTree.new(0, 0, api.config.world_size)
	noise = OpenSimplexNoise.new()
	noise.seed = 2
	noise.octaves = 6
	noise.period = 240
	mutex = Mutex.new()
	threads = [ Thread.new(), Thread.new(), ]
	counter = 0.0
	
func run(delta):
	counter = counter + delta
	if counter < 2.6:
		return
	counter = 0.0
	print('client chunk tick')
	
	if processing:
		return
	# Do not run if we have nothing to do
	# Use disabled so that the service can be tracked easily later
	print(api.dirty_objects_client)
	if disabled || api.dirty_objects_client[ Def.TYPE_CHUNK ].size() == 0:
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
	var dirty_chunks = api.dirty_objects_client[ Def.TYPE_CHUNK ]
	print('running DrawChunks', dirty_chunks.size(), 'needloadsize is ', need_load.all().size())
	api.dirty_objects_client[ Def.TYPE_CHUNK ] = []
	api.dirty_objects_mutex.unlock()
	
	# Do the dirty work
	desired.debug()
	for item in dirty_chunks:
		var i = api.objects[ Def.TYPE_CHUNK ][ item ]
		# this could be an empty chunk
		var pos = Vector2(int(i[Def.TX_PHYS_POSITION].x) + world_half, int(i[Def.TX_PHYS_POSITION].z) + world_half)
		if desired.contains( pos.x, pos.y, chunk_size ).size() > 0:
			print('desired dirty ', pos)
			need_load.operation(QuadTree.OP_ADD, pos.x, pos.y, chunk_size)
			received_chunks.operation(QuadTree.OP_ADD, pos.x, pos.y, chunk_size)
			loaded_chunks.operation(QuadTree.OP_ADD, pos.x, pos.y, chunk_size)
	
	# Remove chunks not available for loading
	var can_load = QuadTree.union(received_chunks, need_load)

	# If there are no chunks to load, we are waiting for data
	if can_load.is_empty():
		print('nothing to load')
		disabled = true
		return
	
	var can_load_all = can_load.all()
	var can_unload_all = need_unload.all()
	mutex.lock()
	for item in can_load_all:
		render_queue.append( Fun.make_chunk_key(item.x - world_half, item.y - world_half) )
	mutex.unlock()
	
	# Removing chunks should be pretty cheap so...
	for item in can_unload_all:
		var key = Fun.make_chunk_key(item.x - world_half, item.y - world_half)
		if loaded_ref.has(key):
			mutex.lock()
			loaded_ref[ key ].queue_free()
			loaded_ref.erase(key)
			loaded_chunks.operation(QuadTree.OP_SUBTRACT, item.x, item.y, chunk_size)
			mutex.unlock()
		else:
			assert(false)
	
	print ('render queue is ', render_queue.size())
#	assert(false)
	call_deferred('render_process')
	
	processing = false

func render_process():
	print('attempt render')
	mutex.lock()
	if threads.size() == 0 or render_queue.size() == 0:
		pass
	else:
		var thread = threads.pop_front()
		var item = render_queue.pop_front()
		thread.start(self, "render_chunk", [item, thread])
	mutex.unlock()

func render_chunk(_data):
	var data = api.objects[ Def.TYPE_CHUNK ][ _data[0] ]
	var thread = _data[1]
	var uncompressed = data[Def.TX_CHUNK_DATA]
	if uncompressed.size() > 0:
		uncompressed = data[Def.TX_CHUNK_DATA].decompress(pow(chunk_size + 2, 2) * 4)
	var mesh_chunk = MeshChunk.new(noise, uncompressed, data[Def.TX_PHYS_POSITION].x / chunk_size, data[Def.TX_PHYS_POSITION].z / chunk_size, chunk_size)
	var key = Fun.make_chunk_key(data[Def.TX_PHYS_POSITION].x, data[Def.TX_PHYS_POSITION].z)
	mesh_chunk.name = 'Chunk %s' % key
	mesh_chunk.translation = data[Def.TX_PHYS_POSITION]
	call_deferred('render_done', key, thread, mesh_chunk)

func render_done(key, thread, mesh_chunk: MeshChunk):
	thread.wait_to_finish()
	mutex.lock()
	loaded_ref[key] = mesh_chunk
	loaded_chunks.operation(QuadTree.OP_ADD, mesh_chunk.translation.x + world_half, mesh_chunk.translation.y + world_half, chunk_size)
	var next = render_queue.pop_front()
	if next != null:
		thread.start(self, "render_chunk", [next, thread])
	else:
		client.emit_signal('chunk_queue_empty')
		threads.append(thread)
	mutex.unlock()
	scene.call_deferred('add_child', mesh_chunk)

	















