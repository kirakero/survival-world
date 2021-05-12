extends Node
class_name Server

var services = []

var game
var networked = false
var password
var port
var max_players

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
