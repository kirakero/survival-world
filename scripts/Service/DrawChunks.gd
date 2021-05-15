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
var tryagainpos = null

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
	threads = [ Thread.new(), Thread.new(), Thread.new(), ]
	counter = 0.0
	
func run(delta):
	counter = counter + delta
	if counter < 0.5:
		return
	counter = 0.0
	
	if tryagainpos:
		update(tryagainpos)

	if render_queue.size() > 0 and threads.size() > 0:
		var next = render_queue.pop_front()
		var thread = threads.pop_front()
		if thread:				
			thread.start(self, "render_chunk", [next, thread])
			if render_queue.size() == 0 and not tryagainpos:
				Global.CLI.emit_signal('chunk_queue_empty')



func update(pos):
	tryagainpos = null
#	Global.CLI._debug('updating chunks with %s' % to_json( pos ))
#	if Global.SRV and Global.SRV.players.has( Global.NET.my_id ):
#		Global.SRV._debug('server player %s' % to_json( Global.SRV.players[ Global.NET.my_id ]['pos_new'] ))
	var wanted = Global.DATA.chunkkeys_circle( pos )
	for loaded in Global.CLI.loaded_chunks.keys():
		if not wanted.has(loaded) \
		and Global.CLI.loaded_chunks[ loaded ].distance_to( pos ) > Global.DATA.config['max_range_chunk'] * 1.25:
			# CHUNK UNLOAD
			loaded_ref[ loaded ].queue_free()
			Global.CLI.loaded_chunks.erase( loaded )
		else:
			# CHUNK IGNORE (already loaded)
			wanted.erase( loaded )
	
	# CHUNK IGNORE (already loading)
	for loading in Global.CLI.loading_chunks.keys():
		wanted.erase( loading )
		
	mutex.lock()
	for chunk in wanted.keys():
		# CHUNK SKIP (data not available yet)
		if not render_queue.has( chunk ):
			if Global.CLI.objects.has( chunk ):
				# CHUNK LOAD
				Global.CLI.loading_chunks[ chunk ] = true
				render_queue.append( chunk )
			else:
				# DATA NOT AVAILABLE - TRY AGAIN LATER
				tryagainpos = pos
				
	mutex.unlock()

func render_process():
#	print('attempt render')
	
	if threads.size() == 0 or render_queue.size() == 0:
		if render_queue.size() == 0 and not tryagainpos:
			Global.CLI.emit_signal('chunk_queue_empty')
		return
		
	mutex.lock()
	var thread = threads.pop_front()
	var item = render_queue.pop_front()
	thread.start(self, "render_chunk", [item, thread])
	mutex.unlock()

func render_chunk(_data):
	var data = Global.CLI.objects[ _data[0] ]
	var thread = _data[1]
	
	var chunk = Global.CLI.chunks[ _data[0] ]
	chunk.set_ChunkData( data )
	var mesh_chunk = chunk.get_ChunkMesh()
	mesh_chunk.generate()
	mesh_chunk.name = 'Chunk %s' % _data[0]
	mesh_chunk.translation = data[Def.TX_POSITION]
	
	call_deferred('render_done', _data[0], thread, mesh_chunk)

func render_done(key, thread, mesh_chunk):
	thread.wait_to_finish()
	loaded_ref[key] = mesh_chunk
	Global.CLI.loaded_chunks[ key ] = mesh_chunk.translation * Vector3(1, 0, 1)
#	loaded_chunks.operation(QuadTree.OP_ADD, mesh_chunk.translation.x, mesh_chunk.translation.z, chunk_size)
#	loading_chunks.operation(QuadTree.OP_SUBTRACT, mesh_chunk.translation.x, mesh_chunk.translation.z, chunk_size)
	mutex.lock()
	threads.append(thread)
	mutex.unlock()
	self.call_deferred('render_process')
	scene.call_deferred('add_child', mesh_chunk)
	print('render %s complete'%mesh_chunk.name)













