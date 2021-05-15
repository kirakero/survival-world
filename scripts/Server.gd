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
var dirty_players = {}

var loader

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

	if (networked):
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(port, max_players)
		get_tree().network_peer = peer

		Global.NET.my_id = get_tree().get_network_unique_id()
		get_tree().connect("network_peer_connected", self, "_player_connected")
		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
#		get_tree().connect("connected_to_server", self, "_connected_ok")
#		get_tree().connect("connection_failed", self, "_connected_fail")
#		get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	
	services.append( load("res://scripts/Service/SyncPlayers.gd").new() )
	services.append( load("res://scripts/Service/SyncChunks.gd").new() )
	services.append( load("res://scripts/Service/LoadChunks.gd").new() )
	loader = services[2]
	
	_debug('loaded')
	emit_signal("server_loaded")
	

func _player_connected(id):
	Global.NET.tx_config(id)

func _player_disconnected(id):
	_debug("player %s disconnected" % id)
	players.erase( id )

func get_chunk(pos_x, pos_z):
	var key = Fun.make_chunk_key(pos_x, pos_z)
	if not chunks.has( key ):
		chunks[ key ] = Chunk.new( Vector2(pos_x, pos_z), self )
		loader.queue( pos_x, pos_z )
	
	return chunks[ key ]
	
func add_gameob(gameob: Dictionary, from, pos_x, pos_z):
	if objects.has( gameob[ Def.TX_ID ] ):
		_debug("Warning: Receiving object %s again" % gameob[ Def.TX_ID ])
		return
	
	get_chunk(pos_x, pos_z).add( gameob )
	
	if gameob[ Def.TX_TYPE ] == Def.TYPE_PLAYER:
		players[ gameob[ Def.TX_ID ] ] = {
			'pos_new': Vector2(pos_x, pos_z), 
			'pos_old': null,
			'chunks': {},
			'previous_wanted': [], 
		}


func update_gameob(gameob: Dictionary, from, pos_x, pos_z):
	if not objects.has( gameob[ Def.TX_ID ] ) \
		|| objects[ gameob[Def.TX_ID] ][ Def.TX_UPDATED_AT ] > gameob[ Def.TX_UPDATED_AT ]:
		_debug('rej %s' %  gameob[ Def.TX_ID ] )	
		return false

	var chunk_key = Fun.make_chunk_key(pos_x, pos_z)
	
	# if this is ghost, process it here
	if gameob[ Def.TX_TYPE ] == Def.TYPE_GHOST:
		return
	
	var enter = false
	
	var old = objects[ gameob[Def.TX_ID] ][ Def.QUAD ]
	objects[ gameob[Def.TX_ID] ][ Def.QUAD ] = chunk_key
	
	# the object has moved into another chunk
	if old and chunk_key != old:
		_debug('object move from %s to %s' % [ old, chunk_key ])
		chunks[ old ].remove( gameob )
		enter = true
	
	get_chunk(pos_x, pos_z).update( gameob, enter )
	if gameob[ Def.TX_TYPE ] == Def.TYPE_PLAYER:
		players[ gameob[ Def.TX_ID ] ][ 'pos_new' ] = Vector2(pos_x, pos_z)

	assert( objects[ gameob[Def.TX_ID] ][ Def.QUAD ]  == chunk_key )


	
func empty_dirty_players():
	dirty_players = {}
	
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
	

func _physics_process(delta):
	for service in services:
		service.run(delta)


func _debug(message):
	print ("SRV: %s" % message)
