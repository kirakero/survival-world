extends Node
class_name Network

var my_id = 1

signal config_received


# TRANSMIT MANY RAW
func txr(data, to = 1):
	if data.size() == 0:
		return
	rpc_invoke_reliable(to, 'rxs', data)

# TRANSMIT MANY PARTIAL RAW
func txp(data, to = 1, force_cli = false):
	if data.size() == 0:
		return
	rpc_invoke(to, 'rxs_partial', data, force_cli)

remote func rxs(data: Array, force_cli = false):
	var sender_id = get_tree().get_rpc_sender_id()
	# ingest the data
#	_debug("rx-r (from %s) %s" % [sender_id, to_json(data)] )
	for item in data:
		ingest( item, sender_id, 'add', force_cli )
	
remote func rxs_partial(data: Array, force_cli = false):
	var sender_id = get_tree().get_rpc_sender_id()
#	_debug("rx-p (from %s) %s" % [sender_id, to_json(data)] )
		# ingest the data
	for item in data:
		ingest( item, sender_id, 'update', force_cli )

# Standardized RX data router
func ingest(gameob: Dictionary, from, method, force_cli = false):
	# determine the chunk key
	var pos = Global.DATA.get_chunk_pos(gameob[ Def.TX_POSITION ])

	# CLI
	if Global.CLI and from < 2:
		Global.CLI.call("%s_gameob" % method, gameob, from, pos.x, pos.z)
	# SRV
	if Global.SRV and (from != 1 || force_cli):
		Global.SRV.call("%s_gameob" % method, gameob, from, pos.x, pos.z)


#####################################################3
### STATE INOUT
func rpc_invoke(id, method, data, force_cli = false):
#	print('rpc_invoke', id, method)
	if Global.SRV and id < 2:
		call_deferred(method, data, force_cli)
	else:
		rpc_unreliable_id(id, method, data)

func rpc_invoke_reliable(id, method, data):
#	print('rpc_invoke_reliable', id, method)
	if Global.SRV and id < 2:
		call_deferred(method, data)
	else:
#		print('rpc_id', id, method, data)
		rpc_id(id, method, data)


######### OBJECT DATA #########################################################

func tx_config(to):
	if to != Global.NET.my_id:
		# someone new that isnt us has joined -- they need the world config
		# this method should not be called on a local client/server, only
		# remote clients
		_debug('tx config to %s' % to)
		rpc_id(int(to), "rx_config", Global.DATA.config)

remote func rx_config(_data: Dictionary):
	Global.DATA.config = _data
	print ("received config ", _data)
	emit_signal("config_received")


func _debug(message):
	print ("NET: %s" % message)
