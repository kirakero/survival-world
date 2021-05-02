extends Node
class_name Api


const TYPE_PLAYER = 0		# this is a Player
const TYPE_RESOURCE = 1 	# this is a body in the environment that might move
const TYPE_REMOVED = 2 		# this is a default body in the environment that was altered
const TYPE_CHUNK = 3 		# this is a map chunk
const TYPE_TERRAIN = 4 		# this is a single map height

const TX_ID = 'I'
const TX_TYPE = 'T'
const TX_DATA = 'D'
const TX_TIME = 't'
const TX_ERASE = 'E' # erase mode
const TX_INTENT = 'i'

const INTENT_CLIENT = 0		# objects in the local/player domain
const INTENT_SERVER = 1		# objects in the server/world domain

const DIRTY_SENDER = 0
const DIRTY_TYPE = 1
const DIRTY_ID = 2

const TX_PHYS_POSITION = 'P'


# this is the ID of the map
var game setget set_game
var player setget set_player
var config

# this is the world_provider for the world data
var world_provider: Reference
var state_provider: Node

var frameware: = []
# character information will be saved in a separate DB instance on the client side

var dirty_objects_mutex: Mutex

const DB_DATA_DIR = 'user://savegame/'

signal net_failure

signal server_loaded
signal client_loaded

signal world_get_done(result)
signal world_post_done(result)
signal chunk_post_done(result)
signal multichunk_post_done(result)
signal multichunk_get_done(result)
signal chunk_get_done(result)

func _init(_world_provider):
	world_provider = _world_provider
	dirty_objects_mutex = Mutex.new()

var server_started = false
var server_port
var server_max_players
var server = null
var networked = null

func start_server( game, _networked = false, password = null, port = 2480, max_players = 10 ):
	
	# World Data is LOCAL
	world_provider = SQLiteProvider.new()
	
	if (networked):
		server_port = port
		server_max_players = max_players
		
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(port, max_players)
		get_tree().network_peer = peer
		
		_init_network()
	
	set_game(game)
	async_world_get()
	config = yield(self, "world_get_done")['data']
	config.chunk_size = int(config.chunk_size)
	config.world_size = int(config.world_size)
	
	Global.config = config
	
	server = load("res://scripts/Server.gd").new( self )
	
	get_tree().get_root().add_child( server )
	
	emit_signal("server_loaded")

func start_client( host = null, password = null, port = 2480 ):
	
	if host != null:
		local_server = false
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(host, port)
		get_tree().network_peer = peer
		
		# World Data is REMOTE
		assert(false)
		world_provider = RemoteWorldProvider.new()
	else:
		local_server = true
		_player_connected()
	
	emit_signal("client_loaded")
	

func _player_connected():
	# the client has connected to a server (may or may not be local
	# the client should transmit player data so the server can start processing
	if networked:
		my_id = get_tree().get_network_unique_id()
	var my_data = {
		"name": "kero",
		TX_PHYS_POSITION: Vector3(-440, 1, 128)
	}
	rpc_invoke_reliable(1, 'tx_object', { TX_ID: my_id, TX_TYPE: TYPE_PLAYER, TX_DATA: my_data })





func _connected_fail():
	emit_signal("net_failure", "failed to connect")

func _server_disconnected():
	emit_signal("net_failure", "disconnected")

func _init_network():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	networked = true

func set_game(_game):
	if game != null and world_provider != null:
		world_provider.conn_delete({})
	
	game = _game
	world_provider.conn_post({'game': _game})

func set_player(_player):
	player = _player

# standardize the request object
func invoke(endpoint: String, data: Dictionary):
	print ('invoke ', endpoint)
	data['game'] = game
	data['_sender'] = self
	data['_callback'] = str(endpoint, '_done')
	data['_key'] = 1
	world_provider.call_deferred(endpoint, data)

func done(signal_name, result, code):
	print('api done ',signal_name, result)
	emit_signal(signal_name, { 'data': result, 'status': code })
	
# lists the worlds saved locally
func sync_my_world_index() -> Array:
	var dir = Directory.new()
	if not dir.dir_exists(DB_DATA_DIR):
		dir.make_dir(DB_DATA_DIR)
	dir.open(DB_DATA_DIR)
	dir.list_dir_begin()
	var files = []
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file.get_basename())

	dir.list_dir_end()
	return files

# when creating a brand new world to save locally
func async_world_post(_newgame, _seed, _world_size, _chunk_size):
	invoke('world_post', {
		'newgame': _newgame,
		'seed': _seed,
		'world_size': _world_size,
		'chunk_size': _chunk_size,
	})

# returns all settings for the world
func async_world_get():
	invoke('world_get', {})

# write chunk
func async_chunk_post(_position, _data):
	invoke('chunk_post', {
		'position': _position,
		'data': _data,
	})

# bulk write chunk
func async_multichunk_post(_data: Array):
	# use format for regular call, as array
	invoke('multichunk_post', {
		'data': _data,
	})
	
# read chunk
func async_chunk_get(_position):
	invoke('chunk_get', {
		'position': _position,
	})

# bulk read chunk
func async_multichunk_get(_data: Array):
	# use format for regular call, as array
	invoke('multichunk_get', {
		'data': _data,
	})

#####################################################3
### STATE INOUT

var local_server = false
var my_id = 1
# connected players
var players = {
	'123': {'P': Vector3(2, 2, 2)}
}
var world_visible = {
	'0': {'players': []},
	'123': {'players': []}
}
var local_visible_players = {}

# max distance that a player will receive updates from another player
var max_radius = 80

func rpc_invoke(id, method, data):
	print('rpc_invoke', id, method)
	if local_server:
		call_deferred(method, data)
	else:
		rpc_unreliable_id(id, method, data)

func rpc_invoke_reliable(id, method, data):
	print('rpc_invoke_reliable', id, method)
	if local_server:
		call_deferred(method, data)
	else:
		rpc_id(id, method, data)

######### OBJECT DATA #########################################################

# object's 'true' data
var objects = [
	{}, # PLAYER
	{}, # RESOURCE - saves to disk
	{}, # REMOVED  - saves to disk
	{}, # CHUNK  - saves to disk
	{}, # TERRAIN  - saves to disk
]
var dirty_objects = [
	[],
	[],
	[],
	[],	
	[],
]
var dirty_objects_client = [
	[],
	[],
	[],
	[],
	[],
]

# object's 'ephemeral' data (like physics)
var physics = [
	{}, # PLAYER
	{}, # RESOURCE - saves to disk via local callback to object
]
var dirty_physics = [
	[],
	[]
]

func tx_object(_data: Dictionary):
	assert(_data.has(TX_ID) && _data.has(TX_TYPE) && _data.has(TX_DATA))
	_data[ TX_TIME ] = OS.get_system_time_msecs() #todo
	rpc_invoke(1, "rx_object", _data)

remote func rx_object(_data: Dictionary):
	print('rx_object', _data)
	var sender_id = get_tree().get_rpc_sender_id()
	objects[ _data[TX_TYPE] ][ _data[TX_ID] ] = _data[TX_DATA]
	dirty_objects.append([ sender_id, _data[TX_TYPE] , _data[TX_ID] ])
	if _data[TX_TYPE] == TYPE_PLAYER:
		physics[ _data[TX_TYPE] ][ _data[TX_ID] ] = _data[TX_DATA]

func tx_objects(_data: Dictionary):
	assert(_data.has(TX_TYPE) && _data.has(TX_DATA))
	rpc_invoke(1, "rx_objects", _data)

remote func rx_objects(_data: Dictionary):
	print('rx_objects   ', _data)
	var sender_id = get_tree().get_rpc_sender_id()
	if _data[TX_INTENT] == INTENT_CLIENT:
		for item in _data[TX_DATA]:
			objects[ _data[TX_TYPE] ][ item[0] ] = item[1]
			dirty_objects_client.append([ sender_id, _data[TX_TYPE] , item[0] ])
	else:
		for item in _data[TX_DATA]:
			objects[ _data[TX_TYPE] ][ item[0] ] = item[1]
			dirty_objects.append([ sender_id, _data[TX_TYPE] , item[0] ])

func tx_physics(_data: Dictionary):
	assert(_data.has(TX_ID) && _data.has(TX_TYPE) && _data.has(TX_DATA))
	rpc_invoke(1, "rx_physics", _data)

remote func rx_physics(_data: Dictionary):
	print('rx_physics', _data)
	var sender_id = get_tree().get_rpc_sender_id()
	physics[ _data[TX_TYPE] ][ _data[TX_ID] ] = _data[TX_DATA]
	dirty_physics.append([ sender_id, _data[TX_TYPE] , _data[TX_ID] ])

###############################################################################

static func make_chunk_key(x, y):
	return '%s,%s' % [x, y]

static func strip_meta(data):
	data.erase('_key')
	data.erase('_callback')
	return data
