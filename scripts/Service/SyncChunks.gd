extends Reference

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
	var chunks = Global.DATA.qt_empty()
	var pos_x = int(player[ Def.TX_POSITION ].x / chunk_size) * chunk_size
	var pos_z = int(player[ Def.TX_POSITION ].z / chunk_size) * chunk_size
	chunks.operation(QuadTree.OP_ADD, pos_x - max_range_chunk, pos_z - max_range_chunk, max_range_chunk*2)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x - max_range_chunk - chunk_size, pos_z - max_range_chunk, chunk_size)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x + (max_range_chunk)*2 - chunk_size, pos_z - max_range_chunk, chunk_size)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x - max_range_chunk - chunk_size, pos_z + (max_range_chunk)*2 - chunk_size, chunk_size)
	chunks.operation(QuadTree.OP_SUBTRACT, pos_x + (max_range_chunk)*2 - chunk_size, pos_z + (max_range_chunk)*2 - chunk_size, chunk_size)
	
	var ts = ServerTime.now()
	var will_send = QuadTree.intersect( Global.DATA.last_transmitted[ pkey ], chunks, QuadTree.INTERSECT_KEEP_B)
	
	if will_send.is_empty():
		return

	# make sure the chunks we need are loaded
	Global.DATA.qt_get_chunks(will_send)
		
	var txr = [] # whole - this is objects that havent been sent to the client
	var txp = [] # partial - this is physics updates

	for chunk in will_send.all():
		var res = Global.DATA.obchunks[ chunk.key ].bifurcated_delta( chunk.value, pkey )
		txr.append_array( res['txr'] ) # RPC RELIABLE - NEW OBJECTS
		txp.append_array( res['txp'] ) # RPC UNRELIABLE - UPDATES
		Global.DATA.last_transmitted[ pkey ].operation(ts, chunk.x, chunk.y, chunk.size)

	Global.NET.txr( txr, pkey )
	Global.NET.txp( txp, pkey )

func run():
	var dirty = Global.DATA.dirty_players
	Global.DATA.empty_dirty_players()
	for pkey in dirty:
		call('send_chunks', pkey[ Def.TX_ID] )
		
	
		
	
	
