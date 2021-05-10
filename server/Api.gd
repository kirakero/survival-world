extends Node
class_name Api

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
var local_server = true


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
signal config_received

func _init(_world_provider):
	
	world_provider = _world_provider
	dirty_objects_mutex = Mutex.new()

var server_started = false
var server_port
var server_max_players
var server = null
var client = null
var networked = null


func start_server( game, _networked = false, password = null, port = 2480, max_players = 10 ):
	# World Data is LOCAL
	world_provider = SQLiteProvider.new()
	
	if (_networked):
		print('starting local server')
		server_port = port
		server_max_players = max_players
		
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(port, max_players)
		get_tree().network_peer = peer

		Global.NET.my_id = get_tree().get_network_unique_id()
		_init_network()
	
	set_game(game)
	async_world_get()
	
	Global.DATA.add_mode( Def.MODE_SERVER )
	Global.DATA.config = yield(self, "world_get_done")['data']
	
	server = load("res://scripts/Server.gd").new( self )
	get_tree().get_root().add_child( server )
	
	emit_signal("server_loaded")

func start_client( host = null, password = null, port = 2480 ):
	
	client = true
	Global.DATA.add_mode( Def.MODE_CLIENT )
	if host != null:
		local_server = false
		_init_network()
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(host, port)
		get_tree().network_peer = peer
		Global.NET.my_id = get_tree().get_network_unique_id()
		print('initiated connection, my id is ', Global.NET.my_id)
		world_provider = RemoteWorldProvider.new()

	_player_connected(Global.NET.my_id)
	
	emit_signal("client_loaded")
	
var seen_players = []
var client_loaded = false


func load_character(name):
	var my_data = {
		Def.TX_ID: Global.NET.my_id,
		Def.TX_NAME: name,
		Def.TX_POSITION: Vector3(-440, 1, 128),
	}
	Global.DATA.add_player(my_data)

# this puts the player into the game world locally
func load_client():
	print("transmitting my data to server")
	Global.NET.tx( Global.NET.my_id )
	
	if not local_server:
		# wait for world config from server
		yield(Global.NET, "config_received")
	
	# start the client services
	# first load the world scene
	Global.goto_scene_prepare('res://scenes/GameScene.tscn')
#	var global = Global
	var scene = yield(Global, "scene_prepared")
	var player = preload('res://Player/Player.tscn').instance()
	player.translation = Global.DATA.objects[ Global.NET.my_id ][ Def.TX_POSITION ]
	scene.add_child(player)
	# instantiate the client service
	client = load("res://scripts/Client.gd").new( self, scene, player )
	
	get_tree().get_root().add_child( client )
	
	yield(client, "chunk_queue_empty")
	player.physics_active = true
	
	
	
func _player_connected(id):
	# the client has connected to a server (may or may not be local
	# the client should transmit player data so the server can start processing
	
	print ("player connected ", id)
	
	if server != null and id != Global.NET.my_id and id == 1:
		# someone new that isnt us has joined -- they need the world config
		# this method should not be called on a local client/server, only
		# remote clients
		rpc_id(id, "rx_config", Global.config)
	
	if not seen_players.has(id):
		seen_players.append(id)

	if seen_players.has(1) and not client_loaded:	
		client_loaded = true
		load_client()
		




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



static func make_chunk_key(x, y):
	return '%s,%s' % [x, y]

static func strip_meta(data):
	data.erase('_key')
	data.erase('_callback')
	return data



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






