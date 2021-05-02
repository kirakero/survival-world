extends Node

var local_server = false
var my_id = 0
# connected players
var players = {}
var spawned = {}

# max distance that a player will receive updates from another player
var max_radius = 80

func send_player(_data):
	if local_server:
		recv_player(_data)
		return
	
	rpc_unreliable_id(1, "recv_player", _data)
	

func recv_player(_data):
	var sender_id = get_tree().get_rpc_sender_id()
	# we have received data from a client informing us that a player
	# object has changed
	# if sender_id is 0, we are on local loopback
	
	# update object
	# player data is always synced
	players[sender_id] = _data
	

	
	pass

# server tick
func _physics_process(delta):
	
	# for each player, calculate objects visible by range and send
	for p_key in players.keys():
		var new_visibility = []
		for o_key in players.keys():
			if players[p_key]['P'].distance_to(players[o_key]['P']) < max_radius:
				new_visibility.append(o_key)
				# transmit player information
				if p_key != my_id:
					rpc_unreliable_id(p_key, 'recv_player', players[o_key])
		
		# use a reliable method to update the client when player spawns have changed
		new_visibility.sort()
		if new_visibility != spawned[p_key]['players']:
			spawned[p_key]['players'] = new_visibility
			if p_key != my_id:
				rpc_id(p_key, 'recv_spawn_player', new_visibility)
		
	pass






