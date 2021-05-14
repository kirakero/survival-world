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
	var player = Global.SRV.objects[ pkey ]
	var qt = Global.SRV.last_transmitted[ pkey ] as QuadTree

	var pos_x = int(player[ Def.TX_POSITION ].x / chunk_size) * chunk_size
	var pos_z = int(player[ Def.TX_POSITION ].z / chunk_size) * chunk_size
	
	# create a QuadTree 'circle' to select the chunks we'll work with
	var chunks = Global.DATA.qt_circle(pos_x, pos_z)
	
	var ts = ServerTime.now()
	var will_send = QuadTree.intersect( qt, chunks, QuadTree.INTERSECT_KEEP_B)
	
	if will_send.is_empty():
#		Global.SRV._debug('will_send empty')
		return

	# make sure the chunks we need are loaded
	var chunks_ready = Global.SRV.qt_get_chunks(will_send)
	Global.SRV._debug('chunks_ready %s' % chunks_ready.size())
	var txr = [] # whole - this is objects that havent been sent to the client
	var txp = [] # partial - this is physics updates

	print (will_send.all_resize(chunk_size))
	for chunk in will_send.all_resize(chunk_size):
		var res = Global.SRV.obchunks[ chunk.key ].bifurcated_delta( chunk.value, pkey )
		txr.append_array( res['txr'] ) # RPC RELIABLE - NEW OBJECTS
		txp.append_array( res['txp'] ) # RPC UNRELIABLE - UPDATES
		qt.operation(chunk.value, chunk.x, chunk.y, chunk.size)

	Global.NET.txr( txr, pkey )
	Global.NET.txp( txp, pkey )

func run():
	var dirty = Global.SRV.dirty_players.keys()
	Global.SRV.empty_dirty_players()
	for pkey in dirty:
		call('send_chunks', pkey )


	
		
	
	
