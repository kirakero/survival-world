extends Node
class_name Api

# this is the ID of the map
var game setget set_game
var player setget set_player

# this is the world_provider for the world data
var world_provider: Reference
var state_provider: Node
# character information will be saved in a separate DB instance on the client side

const DB_DATA_DIR = 'user://savegame/'

signal world_get_done(result)
signal world_post_done(result)
signal chunk_post_done(result)
signal multichunk_post_done(result)
signal multichunk_get_done(result)
signal chunk_get_done(result)

func _init(_world_provider):
	world_provider = _world_provider

func _init_server():
	
	pass

func _init_client():
	
	
	pass

func _init_network():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	

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
var my_id = 0
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
	if local_server and id == 1:
		call_deferred(method, data)
	else:
		rpc_unreliable_id(id, method, data)

func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
#    rpc_id(id, "register_player", my_info)
	pass

func _player_disconnected(id):
	#player_info.erase(id) # Erase player from info.
	pass

func _connected_ok():
	pass # Only called on clients, not server. Will go unused; not useful here.

func _server_disconnected():
	pass # Server kicked us; show error and abort.

func _connected_fail():
	pass # Could not even connect to server; abort.

remote func register_player(info):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	# Store the info
#    player_info[id] = info
	pass
	

######### OBJECT DATA #########################################################
# 
#
#
const TYPE_PLAYER = 0		# this is a Player
const TYPE_RESOURCE = 1 	# this is a body in the environment that might move
const TYPE_REMOVED = 2 		# this is a default body in the environment that was altered
const TYPE_TERRAIN = 3 		# this is a height change

const TX_ID = 'I'
const TX_TYPE = 'T'
const TX_DATA = 'D'

const DIRTY_SENDER = 0
const DIRTY_TYPE = 1
const DIRTY_ID = 2

const TX_PHYS_POSITION = 'P'

# object's 'true' data
var objects = [
	{}, # PLAYER
	{}, # RESOURCE - saves to disk
	{}, # REMOVED  - saves to disk
	{}, # TERRAIN  - saves to disk
]
var dirty_objects = []

# object's 'ephemeral' data (like physics)
var physics = [
	{}, # PLAYER
	{}, # RESOURCE - saves to disk via local callback to object
]
var dirty_physics = []

func tx_object(_data: Dictionary):
	assert(_data.has(TX_ID) && _data.has(TX_TYPE) && _data.has(TX_DATA))
	rpc_invoke(1, "rx_object", _data)

remote func rx_object(_data: Dictionary):
	print('rx_object', _data)
	var sender_id = get_tree().get_rpc_sender_id()
	physics[ _data[TX_TYPE] ][ _data[TX_ID] ] = _data[TX_DATA]
	dirty_objects.append([ sender_id, _data[TX_TYPE] , _data[TX_ID] ])

func tx_physics(_data: Dictionary):
	assert(_data.has(TX_ID) && _data.has(TX_TYPE) && _data.has(TX_DATA))
	rpc_invoke(1, "rx_physics", _data)

remote func rx_physics(_data: Dictionary):
	print('rx_physics', _data)
	var sender_id = get_tree().get_rpc_sender_id()
	physics[ _data[TX_TYPE] ][ _data[TX_ID] ] = _data[TX_DATA]
	dirty_physics.append([ sender_id, _data[TX_TYPE] , _data[TX_ID] ])

###############################################################################

func send_player(_data: Dictionary):
	rpc_invoke(1, "recv_player", _data)

# called for remote players to update their local position every server frame
remote func recv_player(_data: Dictionary):
	print('recv_player', _data)
	var sender_id = get_tree().get_rpc_sender_id()
	players[sender_id] = _data

# contains an array of player IDs that are visible on this peer
# only called when its updated
remote func recv_visible_player(_data: Array):
	print('recv_visibility')
	local_visible_players = _data



var counter = 0.0
func _physics_process(delta):
	if not local_server:
		return
	counter = counter + delta
	if counter < 5.0:
		return
	counter = 0.0
	# for each player, calculate objects visible by range and send
	for p_key in players.keys():
		var p_key_int = int(p_key)
		var new_visibility = []
		for o_key in players.keys():
			if o_key == p_key:
				continue
			var o_key_int = int(o_key)
			if players[p_key]['P'].distance_to(players[o_key]['P']) < max_radius:
				new_visibility.append(o_key)
				# transmit player information
				if p_key_int != my_id:
					print(['rpc_unreliable_id', p_key_int, 'recv_player', o_key])
#					rpc_unreliable_id(p_key_int, 'recv_player', players[o_key])
		
		# use a reliable method to update the client when player spawns have changed
		new_visibility.sort()
		if new_visibility != world_visible[str(p_key)]['players']:
			world_visible[str(p_key)]['players'] = new_visibility
			print(['rpc_id', p_key_int, 'recv_visible_player', new_visibility])
#				rpc_id(p_key, 'recv_visible_player', new_visibility)
