extends Node
class_name Client

var scene
var player
var services = []

var character
var host
var password
var port

var dirty_chunks: = []

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

var seen_players = []
func _player_connected(id):
	if not seen_players.has(id):
		seen_players.append(id)

	if seen_players.has(1) and not scene:
		load_scene()
		

func load_scene():
	scene = true
	_debug("transmitting my data to server")
	var my_data = {
		Def.TX_ID: Global.NET.my_id,
		Def.TX_NAME: name,
		Def.TX_POSITION: Vector3(-440, 1, 128),
		Def.TX_FOCUS: Global.NET.my_id,
	}
	Global.DATA.add_player(my_data)
	Global.NET.tx( Global.NET.my_id )
	
	if not Global.SRV:
		# wait for world config from server
		yield(Global.NET, "config_received")
	
	# start the client services
	# first load the world scene
	Global.goto_scene_prepare('res://scenes/GameScene.tscn')
#	var global = Global
	scene = yield(Global, "scene_prepared")
	player = preload('res://Player/Player.tscn').instance()
	player.translation = Global.DATA.objects[ Global.NET.my_id ][ Def.TX_POSITION ]
	scene.add_child(player)
	
	# instantiate the client services
	services.append( load("res://scripts/Service/SendPhysics.gd").new() )
	services.append( load("res://scripts/Service/DrawChunks.gd").new() )
	
	yield(self, "chunk_queue_empty")
	player.physics_active = true


func get_and_forget_dirty_chunks():
	var dirty_chunks_ = dirty_chunks.duplicate()
	dirty_chunks = []
	return dirty_chunks_


func _physics_process(delta):
	for service in services:
		service.run(delta)


func _debug(message):
	print ("CLI: %s" % message)
