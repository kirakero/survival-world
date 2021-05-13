extends Node

var scene: Node
var player: Node
var max_range_chunk
var min_range_chunk_unload
var chunk_size
var world_half
var loaded_chunks: QuadTree
var loading_chunks: QuadTree
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
var last_x = 0
var last_z = 0
func _init():
	scene = Global.CLI.scene
	player = Global.CLI.player
	chunk_size = Global.DATA.config['chunk_size']
	max_range_chunk = Global.DATA.config['max_range_chunk']
	# this determines when a chunk is actually unloaded
	min_range_chunk_unload = max_range_chunk + chunk_size
	world_half = int(Global.DATA.config['world_size'] * 0.5)
	loaded_chunks = Global.DATA.qt_empty()
	loading_chunks = Global.DATA.qt_empty()
	noise = OpenSimplexNoise.new()
	noise.seed = 2
	noise.octaves = 6
	noise.period = 240
	mutex = Mutex.new()
	threads = [ Thread.new(), ]
	counter = 0.0
	
func run(delta):
	counter = counter + delta
	if counter < 0.05:
		return
	counter = 0.0
	
	if processing:
		return

	# Do not run if we have nothing to do
	# Use disabled so that the service can be tracked easily later
	if disabled || not Global.CLI.received_chunks_dirty:
		var next = render_queue.pop_front()
		if next != null:
			var thread = threads.pop_front()
			if thread:				
				thread.start(self, "render_chunk", [next, thread])
#				print ('render queue is ', render_queue.size(), 'dirty ', api.dirty_objects_client.size())
				if render_queue.size() == 0:
					Global.CLI.emit_signal('chunk_queue_empty')
				return

		
	disabled = false
	processing = true
	
	
	call_deferred('_run')


func _run():
	var pos_x = int(player.translation.x / chunk_size) * chunk_size
	var pos_z = int(player.translation.z / chunk_size) * chunk_size
	
	if not Global.CLI.received_chunks_dirty and last_x == pos_x and last_z == pos_z:
		processing = false
		return
	
	last_x = pos_x
	last_z = pos_z
	
	# create a QuadTree 'circle' to select the chunks we'll work with
	var desired = Global.DATA.qt_circle(pos_x, pos_z)
	
	# Determine which chunks will be unloaded
	var undesired = Global.DATA.qt_empty()
	undesired.operation(QuadTree.OP_ADD, pos_x - min_range_chunk_unload, pos_z - min_range_chunk_unload, min_range_chunk_unload*2)

	

	# Remove chunks from desired that we don't have, are already loaded, or that will load
	print( 'desired ')
	print (desired.all_as_array())
	print( 'received_chunks ')
	Global.CLI.received_chunks_dirty = false
	print (Global.CLI.received_chunks.all_as_array())
#	var need_loadu = QuadTree.union(received_chunks, desired)
#
#	print( 'after received_chunks ')
#	print (need_loadu.all_as_array())
#	var need_load = QuadTree.intersect(loaded_chunks, need_loadu, QuadTree.INTERSECT_KEEP_B)
#	print( 'after loaded_chunks ' )
#	print (need_load.all_as_array())
#	need_load = QuadTree.intersect(loading_chunks, need_load, QuadTree.INTERSECT_KEEP_B)
#	print( 'after loading_chunks  ' )
#	print (need_load.all_as_array())
	
	
	var need_load = QuadTree.intersect(loaded_chunks, desired, QuadTree.INTERSECT_KEEP_B)
	print( 'after loaded_chunks ' )
	print (need_load.all_as_array())
	need_load = QuadTree.intersect(loading_chunks, need_load, QuadTree.INTERSECT_KEEP_B)
	print( 'after loading_chunks  ' )
	print (need_load.all_as_array())
	need_load = QuadTree.union(Global.CLI.received_chunks, need_load)
	print( 'after received_chunks  ' )
	print (need_load.all_as_array())
	
	# Determine which chunks to unload
	var need_unload = QuadTree.intersect(loaded_chunks, undesired, QuadTree.INTERSECT_KEEP_A)
	

	# If there are no chunks to load, we are waiting for data
	if need_load.is_empty():
		print('nothing to load')
		disabled = true
		processing = false
		return
	
	var can_load_all = need_load.all()
	var can_unload_all = need_unload.all()
	mutex.lock()
	for item in can_load_all:
		print('wanted chunk %s'%item.key)
		render_queue.append( item.key )
		loading_chunks.operation(QuadTree.OP_ADD, item.x, item.y, chunk_size)
	mutex.unlock()
	
	# Removing chunks should be pretty cheap so...
	var didunload = false
	for item in can_unload_all:
		var key = item.key
		if loaded_ref.has(key):
			mutex.lock()
			loaded_ref[ key ].queue_free()
			loaded_ref.erase(key)
			loaded_chunks.operation(QuadTree.OP_SUBTRACT, item.x, item.y, chunk_size)
			assert(loaded_chunks.query(item.x, item.y, chunk_size).size() == 0)
			mutex.unlock()
			print('unload chunk %s okay'% key, ' with ', [QuadTree.OP_SUBTRACT, item.x, item.y, chunk_size] )
			didunload = true
		else:
			print('unload chunk %s failed'% key )
#			assert(false)
			pass
	
#	if didunload:
#		loaded_chunks.debug()
#	assert(false)
#	call_deferred('render_process')
	
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
	var data = Global.CLI.objects[ _data[0] ]
	var thread = _data[1]
	var uncompressed = data[Def.TX_CHUNK_DATA]
	if uncompressed.size() > 0:
		uncompressed = data[Def.TX_CHUNK_DATA].decompress(pow(chunk_size + 2, 2) * 4)
	
	var key = Fun.make_chunk_key(data[Def.TX_POSITION].x, data[Def.TX_POSITION].z)
	var chunk = Global.CLI.chunks[ key ]
	chunk.set_ChunkData( uncompressed, PoolByteArray() )
	var mesh_chunk = chunk.get_ChunkMesh()
	mesh_chunk.name = 'Chunk %s' % key
	mesh_chunk.translation = data[Def.TX_POSITION]
	
	call_deferred('render_done', key, thread, mesh_chunk)

func render_done(key, thread, mesh_chunk):
	thread.wait_to_finish()
	loaded_ref[key] = mesh_chunk
	loaded_chunks.operation(QuadTree.OP_ADD, mesh_chunk.translation.x, mesh_chunk.translation.z, chunk_size)
	loading_chunks.operation(QuadTree.OP_SUBTRACT, mesh_chunk.translation.x, mesh_chunk.translation.z, chunk_size)
	threads.append(thread)
	scene.call_deferred('add_child', mesh_chunk)
	print('render %s complete'%mesh_chunk.name)

	















