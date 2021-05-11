extends Node
class_name Network

var my_id = 1

	
func tx(id, to = 1):
	rpc_invoke(to, 'rxs', [Global.DATA.serialized_copy( id )])

func txs(ids, to = 1):
	var data = Array()
	data.resize( ids.size() )
	for i in range(ids):
		data[ i ] =  Global.DATA.serialized( ids[i] ) 
	rpc_invoke(to, 'rxs', data)

func txs_partial(ids, to = 1):
	var data = Array()
	data.resize( ids.size() )
	for i in range(ids):
		data[ i ] =  Global.DATA.serialized_partial( ids[i] ) 
	rpc_invoke(to, 'rxs_partial', data)

func rxs(data: Array):
	var sender_id = get_tree().get_rpc_sender_id()
	Global.DATA.receive( data, sender_id )
	
func rxs_partial(data: Array):
	var sender_id = get_tree().get_rpc_sender_id()
	Global.DATA.receive_partial( data, sender_id )

#####################################################3
### STATE INOUT
func rpc_invoke(id, method, data):
#	print('rpc_invoke', id, method)
	if Global.DATA.is_server():
		call_deferred(method, data)
	else:
		rpc_unreliable_id(id, method, data)

func rpc_invoke_reliable(id, method, data):
#	print('rpc_invoke_reliable', id, method)
	if Global.DATA.is_server():
		call_deferred(method, data)
	else:
		print('rpc_id', id, method, data)
		rpc_id(id, method, data)






















######### OBJECT DATA #########################################################

puppet func rx_config(_data: Dictionary):
	Global.DATA.config = _data
	print ("received config ", _data)
	emit_signal("config_received")

#func tx_objects(_data: Dictionary):
#	assert(_data.has(TX_DATA))
#	var to = 1
#	if _data.has(Def.TX_TO):
#		to = _data[ Def.TX_TO ]
#	rpc_invoke(to, "rx_objects", _data)
#
#remote func rx_objects(_data: Dictionary):
#	print('rx_objects   ', _data)
#	var sender_id = get_tree().get_rpc_sender_id()
#	if _data[TX_INTENT] == INTENT_CLIENT:
#		if client == null:
#			return
#
#		for item in _data[TX_DATA]:
#			objects[ _data[TX_TYPE] ][ item[0] ] = item[1]
#			dirty_objects_client[ _data[TX_TYPE] ].append( item[0] )
#	else:
#		for item in _data[TX_DATA]:
#			objects[ _data[TX_TYPE] ][ item[0] ] = item[1]
#			dirty_objects.append([ sender_id, _data[TX_TYPE] , item[0] ])
#
#func tx_physics(_data: Dictionary):
#	assert(_data.has(TX_ID) && _data.has(TX_TYPE) && _data.has(TX_DATA))
#	_data[ TX_DATA ][ TX_TIME ] = OS.get_system_time_msecs() #todo
#	rpc_invoke(1, "rx_physics", _data)
#
#remote func rx_physics(_data: Dictionary):
##	print('rx_physics', _data)
#	var sender_id = get_tree().get_rpc_sender_id()
#
#	# update the local object if the physics are newer
#	if not objects[ _data[ Def.TX_TYPE ] ].has( _data[ Def.TX_ID ] ):
#		print('warning: rx_physics received for object that doesnt exist' ,_data)
#		return
#
#	var obj = objects[ _data[ Def.TX_TYPE ] ][ _data[ Def.TX_ID ] ]
#	if _data[ Def.TX_DATA ][ Def.TX_TIME ] > obj[ Def.TX_TIME ]: # todo
#		for _key in _data[Def.TX_DATA].keys():
#			obj[_key] = _data[Def.TX_DATA][_key]
#
#	dirty_physics.append([ sender_id, _data[TX_TYPE] , _data[TX_ID] ])
