extends Reference

var player_chunks = {}
var chunk_size
var max_range_chunk
var world_size
var world_half

func _init():
	max_range_chunk = int(Global.DATA.config['max_range_chunk'])
	chunk_size = int(Global.DATA.config['chunk_size'])
	world_size = int(Global.DATA.config['world_size'])
	world_half = int(world_size * 0.5)

func send_chunks(pkey):
	var player = Global.DATA.objects[ pkey ]
	var chunks = QuadTree.new(0, 0, Global.DATA.config.world_size, false)
	var pos_x = int(player[ Api.TX_PHYS_POSITION ].x / chunk_size) * chunk_size
	var pos_z = int(player[ Api.TX_PHYS_POSITION ].z / chunk_size) * chunk_size
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
	
	Global.NET.txs( Global.DATA.qt_get_chunks(will_send), pkey )
	
	if player_chunks.has( pkey ):
		for chunk in will_send.all():
			player_chunks[ pkey ].operation(QuadTree.OP_ADD, chunk.x, chunk.y, chunk.size)
	else:
		player_chunks[ pkey ] = will_send

func run():
	var dirty = Global.DATA.dirty_players
	Global.DATA.empty_dirty_players()
	for pkey in dirty:
		call('send_chunks', pkey )
		
	
		
	
	
