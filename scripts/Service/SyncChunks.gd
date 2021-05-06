extends Reference

var player_chunks = {}
var chunk_size
var max_range_chunk
var active_world_chunk_tree: QuadTree
var api: Api
var world_half

func _init(_api: Api, _max_range_chunk = 192, _chunk_size = 64):
	api = _api
	max_range_chunk = _max_range_chunk
	chunk_size = _chunk_size
	active_world_chunk_tree = QuadTree.new(0, 0, api.config.world_size, false, true)
	world_half = int(api.config.world_size * 0.5)
	
func load_chunks(chunk: QuadTree):
	if chunk.size == chunk_size:
#		var res = Global.api.world_provider.chunk_get({'_key':1, 'data':{'position': Vector2( chunk.x, chunk.y )}}) #todo cleanup
		var res = api.world_provider._chunk_get( Vector2( chunk.x - world_half, chunk.y - world_half ) )
		
		
		active_world_chunk_tree.operation(QuadTree.OP_ADD, chunk.x, chunk.y, chunk.size)
		Global.api.objects[ Api.TYPE_CHUNK ][ Api.make_chunk_key(chunk.x - world_half, chunk.y - world_half) ] = res
		return
	
	chunk.add_children()
	for child in chunk.child:
		load_chunks( child )
	
	
func get_chunks(tree: QuadTree) -> Array:
	# load our missing chunks
	var missing_chunks = QuadTree.intersect(active_world_chunk_tree, tree, QuadTree.INTERSECT_KEEP_B).all()
#	print('missing chunks', missing_chunks)
	for chunk in missing_chunks:
		load_chunks(chunk)

	var union = QuadTree.union(active_world_chunk_tree, tree).all()

	var chunks = []
	for chunk in union:
		var key = Api.make_chunk_key(chunk.x - world_half, chunk.y - world_half)
		chunks.append([key, api.objects[ Api.TYPE_CHUNK ][ key ]])
	
	print ('server is sending %s chunks' % chunks.size())
	return chunks

func send_chunks(pkey):
	var player = api.objects[ Api.TYPE_PLAYER ][ pkey ]
	var chunks = QuadTree.new(0, 0, api.config.world_size, false)
	var pos_x = int(player[ Api.TX_PHYS_POSITION ].x / chunk_size) * chunk_size + world_half
	var pos_z = int(player[ Api.TX_PHYS_POSITION ].z / chunk_size) * chunk_size + world_half
	chunks.operation(QuadTree.OP_ADD, pos_x - max_range_chunk, pos_z - max_range_chunk, max_range_chunk*2)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x - max_range_chunk - chunk_size, pos_z - max_range_chunk, chunk_size)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x + (max_range_chunk)*2 - chunk_size, pos_z - max_range_chunk, chunk_size)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x - max_range_chunk - chunk_size, pos_z + (max_range_chunk)*2 - chunk_size, chunk_size)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x + (max_range_chunk)*2 - chunk_size, pos_z + (max_range_chunk)*2 - chunk_size, chunk_size)
	
	var will_send: QuadTree = chunks
	
	if player_chunks.has( pkey ):
		will_send = QuadTree.intersect(player_chunks[ pkey ], chunks, QuadTree.INTERSECT_KEEP_B)
	
	if will_send.is_empty():
		return
	else:
		
		print ('server chunk parameters', [pos_x, pos_z, max_range_chunk, chunk_size] )
		if player_chunks.has( pkey ):
			print('player prior ------------')
			print(player_chunks[ pkey ].all_as_array())
			
		print('player chunks ------------')
		print(chunks.all_as_array())
		
		if player_chunks.has( pkey ):
			print('player diff ------------')
			print(will_send.all_as_array())
	
	api.tx_objects({ 
		Def.TX_TO: pkey,
		Api.TX_TYPE: Api.TYPE_CHUNK,
		Api.TX_INTENT: Api.INTENT_CLIENT,
		Api.TX_DATA: get_chunks(will_send)
	})
	
	if player_chunks.has( pkey ):
		for chunk in will_send.all():
			player_chunks[ pkey ].operation(QuadTree.OP_ADD, chunk.x, chunk.y, chunk.size)
	else:
		player_chunks[ pkey ] = will_send

func run():
	# update player_visible, which is used for chunk loading and sending	
	for pkey in api.objects[ Api.TYPE_PLAYER ].keys():		
		call('send_chunks', pkey )
		
	
	
