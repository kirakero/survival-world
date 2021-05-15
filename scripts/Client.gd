extends Node
class_name Client

var scene
var player
var services = []

var character
var host
var password
var port

# OBJECT DATA
var objects: = {}
var chunks: = {}

# NEW SYS
var loading_chunks: = {}
var loaded_chunks: = {}

signal client_loaded
signal chunk_queue_empty

func _init( _character, _host = null, _password = null, _port = 2480 ):
	character = _character
	host = _host
	password = _password
	port = _port
			
	connect("tree_entered", self, "_startup")
	connect("tree_exited", self, "_shutdown")

func _startup():
	# If the server is not running in any capacity, we need to connect to the
	# remote host
	if not Global.SRV:
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(host, port)
		get_tree().network_peer = peer
		Global.NET.my_id = get_tree().get_network_unique_id()
		_debug('initiated connection, my id is %s ' % Global.NET.my_id)
		get_tree().connect("network_peer_connected", self, "_player_connected")

	else:
		_player_connected(1)

func get_chunk(pos_x, pos_z):
	var key = Fun.make_chunk_key(pos_x, pos_z)
	if not chunks.has( key ):
		chunks[ key ] = Chunk.new( Vector2(pos_x, pos_z), self )
	
	return chunks[ key ]

func add_gameob(gameob: Dictionary, from, pos_x, pos_z):
#	_debug("received %s" % gameob[ Def.TX_ID ])
	get_chunk(pos_x, pos_z).add( gameob )

	
func update_gameob(gameob: Dictionary, from, pos_x, pos_z):
	if not objects.has( gameob[ Def.TX_ID ] ) \
		|| objects[ gameob[Def.TX_ID] ][ Def.TX_UPDATED_AT ] > gameob[ Def.TX_UPDATED_AT ] \
		|| objects[ gameob[Def.TX_ID] ][ Def.TX_FOCUS ] == Global.NET.my_id:
		return false

	var chunk_key = Fun.make_chunk_key(pos_x, pos_z)
	
	# if this is ghost, process it here
	if gameob[ Def.TX_TYPE ] == Def.TYPE_GHOST:
		return
		
	# write the new values todo optimize
	for k in gameob.keys():
		objects[ gameob[ Def.TX_ID ] ][ k ] = gameob[ k ]
	
	var enter = false
	# the object has moved into another chunk
	if chunk_key != objects[ gameob[Def.TX_ID] ][ Def.QUAD ]:
		if objects[ gameob[Def.TX_ID] ][ Def.QUAD ]:
			chunks[ objects[ gameob[Def.TX_ID] ][ Def.QUAD ] ].remove( gameob )
		objects[ gameob[Def.TX_ID] ][ Def.QUAD ] = chunk_key
		enter = true
	
	get_chunk(pos_x, pos_z).update( gameob, enter )





var seen_players = []
func _player_connected(id):
	if not seen_players.has(id):
		seen_players.append(id)

	if seen_players.has(1) and not scene:
		load_scene()
		

func load_scene():
	scene = true

	
	if not Global.SRV:
		_debug('waiting for config')
		# wait for world config from server
		yield(Global.NET, "config_received")
	
	
	_debug("transmitting my data to server")
	var my_data = {
		Def.TX_ID: Global.NET.my_id,
		Def.TX_NAME: name,
		Def.TX_POSITION: Vector3(-440, 1, 128),
		Def.TX_FOCUS: Global.NET.my_id,
		Def.TX_TYPE: Def.TYPE_PLAYER,
	}
	
	Global.NET.ingest( my_data, 1, 'add' )
	Global.NET.txr( [ my_data ] )
	
	# start the client services
	# first load the world scene
	Global.goto_scene_prepare('res://scenes/GameScene.tscn')
#	var global = Global
	scene = yield(Global, "scene_prepared")
	player = preload('res://Player/Player.tscn').instance()
	player.translation = objects[ Global.NET.my_id ][ Def.TX_POSITION ]
	scene.add_child(player)
	
	# instantiate the client services
	services.append( load("res://scripts/Service/SendPhysics.gd").new() )
	services.append( load("res://scripts/Service/DrawChunks.gd").new() )
	
	yield(self, "chunk_queue_empty")
	player.physics_active = true


func _on_player_chunk_changed(pos):
	services[1].update(pos)

func _physics_process(delta):
	for service in services:
		service.run(delta)

func _debug(message):
	print ("CLI: %s" % message)
