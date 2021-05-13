extends Node
class_name Server

var services = []

var game
var networked = false
var password
var port
var max_players

var chunks = {}
var obchunks = {}
var objects = {}
var players = {}
var chunks_client = {}

var dirty_objects = []
var dirty_chunks = []
var dirty_players = []

var qt_loaded_chunks: QuadTree

var last_transmitted = {}

signal server_loaded

func _init( _game, _networked = false, _password = null, _port = 2480, _max_players = 10 ):
	
	game = _game
	networked = _networked
	port = _port
	max_players = _max_players
	
	connect("tree_entered", self, "_startup")
	connect("tree_exited", self, "_shutdown")


func _startup():
	
	Global.DATA.add_mode( Def.MODE_SERVER )
	Global.DATA.set_world(game)

	
	qt_loaded_chunks = Global.DATA.qt_empty()

	if (networked):
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(port, max_players)
		get_tree().network_peer = peer

		Global.NET.my_id = get_tree().get_network_unique_id()
		get_tree().connect("network_peer_connected", self, "_player_connected")
#		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
#		get_tree().connect("connected_to_server", self, "_connected_ok")
#		get_tree().connect("connection_failed", self, "_connected_fail")
#		get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	
	services.append( load("res://scripts/Service/SyncPlayers.gd").new() )
	services.append( load("res://scripts/Service/SyncChunks.gd").new() )
	
	_debug('loaded')
	emit_signal("server_loaded")
	

func _player_connected(id):
	if id != Global.NET.my_id and id == 1:
		# someone new that isnt us has joined -- they need the world config
		# this method should not be called on a local client/server, only
		# remote clients
		rpc_id(id, "rx_config", Global.config)
	

func add_gameob(gameob: Dictionary, from, pos_x, pos_z):
	if objects.has( gameob[ Def.TX_ID ] ):
		_debug("Warning: Receiving object %s again" % gameob[ Def.TX_ID ])
		return
	var key = Fun.make_chunk_key(pos_x, pos_z)
	if not chunks.has( key ):
		_debug('loading missing chunk %s' % key )
		# force load the chunk
		var needed = QuadTree.new(pos_x, pos_z, Global.DATA.config['chunk_size'], 1)
		qt_load_chunks( needed )
	
	# if the object type is a player, begin tracking what has been sent to them
	if gameob[ Def.TX_TYPE ] == Def.TYPE_PLAYER:
		last_transmitted[ gameob[ Def.TX_ID ] ] = Global.DATA.qt_empty()
		print(last_transmitted)
	gameob[ Def.TX_CREATED_AT ] = ServerTime.now()
	gameob[ Def.TX_UPDATED_AT ] = ServerTime.now()
	# finally, add it to the chunk and mark the obchunk as dirty
	obchunks[ key ].add( gameob )
	
	if gameob[ Def.TX_TYPE ] == Def.TYPE_PLAYER:
		dirty_players.append( gameob[ Def.TX_ID ] )

	
func update_gameob(gameob: Dictionary, from, pos_x, pos_z):
	# data is partial but it will have an ID
	# make sure we dont process old data, and make sure we can update something
	if not objects.has( gameob[ Def.TX_ID ] ) \
	|| objects[ gameob[Def.TX_ID] ][ Def.TX_UPDATED_AT ] > gameob[ Def.TX_UPDATED_AT ]:
		return false
	
	var chunk_key = Fun.make_chunk_key(pos_x, pos_z)
	if not chunks.has( chunk_key ):
		_debug('loading missing chunk %s' % chunk_key )
		# force load the chunk
		var needed = QuadTree.new(pos_x, pos_z, Global.DATA.config['chunk_size'], 1)
		qt_load_chunks( needed )
		
	# write the new values
	for k in gameob.keys():
		objects[ gameob[Def.TX_ID] ][ k ] = gameob[ k ]
	
	# the object has moved into another chunk
	if chunk_key != objects[ gameob[Def.TX_ID] ][ Def.QUAD ]:
		# this is a special case for putting players into the chunks
		if objects[ gameob[Def.TX_ID] ][ Def.QUAD ]:
			chunks[ objects[ gameob[Def.TX_ID] ][ Def.QUAD ] ].exit( gameob[Def.TX_ID] )
			chunks[ chunk_key ].enter( gameob[Def.TX_ID] )
		objects[ gameob[Def.TX_ID] ][ Def.QUAD ] = chunk_key
		obchunks[ chunk_key ].update( gameob, true )
	else:
		obchunks[ chunk_key ].update( gameob, false )

	if objects[ gameob[Def.TX_ID] ][ Def.TX_TYPE ] == Def.TYPE_PLAYER:
		dirty_players.append( gameob[ Def.TX_ID ] )




func qt_load_chunks(chunk: QuadTree):
	if chunk.size == Global.DATA.config['chunk_size']:
		var res = Global.DATA.world_provider._chunk_get( chunk.position )
		# register the basic object -- this is the object that can be transmitted
		# to connected peers
		objects[ chunk.key ] = res
		qt_loaded_chunks.operation(QuadTree.OP_ADD, chunk.x, chunk.y, chunk.size)
		# create the obchunk -- this is the object that handles server magics
		var uncompressed = res[Def.TX_CHUNK_DATA]
		if uncompressed.size() > 0:
			uncompressed = res[Def.TX_CHUNK_DATA].decompress(pow(chunk.size + 2, 2) * 4)
		var chunk_obj = Chunk.new( chunk.position )
		chunk_obj.set_ChunkData(uncompressed, res[Def.TX_OBJECT_DATA])
		chunks[ chunk_obj.get_key() ] = chunk_obj
		obchunks[ chunk_obj.get_key() ] = ObChunk.new( chunk_obj, Global.SRV )
		obchunks[ chunk_obj.get_key() ].load_all()
		# the raw object needs to be a child of its own obchunk so it can be
		# synced to other clients
		obchunks[ chunk.key ].update( res, false )
		_debug('loading %s' % chunk.key )
		return
	
	chunk.add_children()
	for child in chunk.child:
		qt_load_chunks( child )

func qt_get_chunks(tree: QuadTree) -> Array:
	var missing_chunks = QuadTree.intersect(qt_loaded_chunks, tree, QuadTree.INTERSECT_KEEP_B).all()

	for chunk in missing_chunks:
		qt_load_chunks(chunk)

	var union = QuadTree.union(qt_loaded_chunks, tree).all()

	var chunks = []
	for chunk in union:
		chunks.append( chunk.key )

	return chunks

	
func empty_dirty_players():
	dirty_players = []
	
func serialized(id):
	var gameob = objects[ id ].duplicate()
	gameob.erase( Def.QUAD )
	gameob.erase( Def.QUAD_INDEX )
	return gameob
		
func serialized_partial(id):
	# todo return only the physics fields
	var gameob = objects[ id ].duplicate()
	gameob.erase( Def.QUAD )
	gameob.erase( Def.QUAD_INDEX )
	gameob.erase( Def.TX_TYPE )
	gameob.erase( Def.TX_SUBTYPE )
	return gameob	
	









var counter = 0.0
var tick = 0.0
func _physics_process(delta):
	counter = counter + delta
	if counter < 2.0:
		return
	counter = 0.0
	
#	print('server tick')
	for service in services:
		service.run()


func _debug(message):
	print ("SRV: %s" % message)
