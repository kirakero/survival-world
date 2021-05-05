extends Reference

# transmit dirty physics to players in range
var max_range
var api

func _init(_api: Api, _max_range = 192):
	max_range = _max_range
	api = _api

func run():
	# update and retransmit new player locations
#	print ('PLAYERS ', api.objects[ Api.TYPE_PLAYER ].keys())
	for pkey in api.objects[ Api.TYPE_PLAYER ].keys():
		var player = api.objects[ Api.TYPE_PLAYER ][ pkey ]
		var pkey_int = int(pkey)
		
#		print(' DIRTY ', api.dirty_physics.size())
		## broadcast player data
		for dirty in api.dirty_physics:

			pass
		
		api.dirty_physics = []
#			# do not transmit back to original sender
#			# nor to server or local client -- that's us!
#			if dirty[ Api.DIRTY_SENDER ] == pkey_int or dirty[ Api.DIRTY_SENDER ] == 1 or dirty[ Api.DIRTY_SENDER ] == 0:
#				continue
#			# all physical objects have a position -- if the position is far away
#			# from the player, there is no need to send this data
#			if obj[ Api.TX_PHYS_POSITION ].distance_to( player[ Api.TX_PHYS_POSITION ]) > max_range:
#				continue
#
			# for now fire off individual packets -- can optimize later
#			api.rpc_unreliable_id(pkey_int, 'rx_physics', obj)

	
	
