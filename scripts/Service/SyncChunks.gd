extends Reference

var chunk_size
var max_range_chunk
var world_size
var world_half

const INACTIVE = 0
const LOADING = 1
const SUBSCRIBED= 2

func _init():
	max_range_chunk = int(Global.DATA.config['max_range_chunk'])
	chunk_size = int(Global.DATA.config['chunk_size'])
	world_size = int(Global.DATA.config['world_size'])
	world_half = int(world_size * 0.5)

func send_chunks( id, pos: Vector2 ):
#	Global.SRV._debug( 'sending chunks to %s: %s' % [id, pos])
	var txr = [] # whole - this is objects that havent been sent to the client
	var txp = [] # partial - this is physics updates
	
	var player = Global.SRV.players[ id ]
	var wanted_chunks = Global.DATA.chunkkeys_circle( Vector3(pos.x, 0, pos.y) )
	for wanted in wanted_chunks.keys():
		if not player['chunks'].has( wanted ):
			# the player hasn't visited this chunk yet, but they need it now
			# set status to loading@0
			player['chunks'][ wanted ] = [ LOADING, 0 ]
		elif player['chunks'][ wanted ][ 0 ] == INACTIVE:
			# the player is going from inactive to loading on this chunk
			player['chunks'][ wanted ][ 0 ] = LOADING
		
		# if the player needs this chunk, but is not subscribed, catch them up
		# and then subscribe them
		if player['chunks'][ wanted ][ 0 ] == LOADING:
			var chunk = Global.SRV.get_chunk( wanted_chunks[ wanted ].x, wanted_chunks[ wanted ].z )
			if chunk.fully_loaded:
				var res = chunk.bifurcated_delta( player['chunks'][ wanted ][ 1 ], id )

				print (' SERVER SYNC: ', wanted,  [res['txr'].size(), player['chunks'][ wanted ][ 1 ], id])
				print (res['txr'])
				# RPC RELIABLE - NEW OBJECTS
				# send them right away to minimize the chance subpub are missed
				Global.NET.txr( res['txr'], id, Global.NET.INTENT_CLIENT ) 
				player['chunks'][ wanted ][ 0 ] = SUBSCRIBED
				player['chunks'][ wanted ][ 1 ] = res['last']
				Global.SRV.chunks[ wanted ].subscribers.append( id )
				
				# RPC UNRELIABLE - UPDATES
				# these will be present if the player previously visited this chunk
				txp.append_array( res['txp'] ) 
			else:
				# the server is still loading one of the chunks, so we force
				# this routine to run again later
				player['pos_old'] = null
				
	for prev in player['previous_wanted']:
		if not wanted_chunks.has( prev ):
			player['chunks'][ prev ][ 0 ] = INACTIVE
			Global.SRV.chunks[ prev ].subscribers.erase( id )

	player['previous_wanted'] = wanted_chunks.keys()
	
	Global.NET.txp( txp, id, Global.NET.INTENT_CLIENT )


var counter = 0.0
func run(delta):
	counter = counter + delta
	if counter < 0.5:
		return
	counter = 0.0
	
	var players = Global.SRV.players.keys()
	
	for player in players:
		if Global.SRV.players[ player ][ 'pos_new' ] != Global.SRV.players[ player ][ 'pos_old' ]:
			Global.SRV.players[ player ][ 'pos_old' ] = Global.SRV.players[ player ][ 'pos_new' ]
			call_deferred('send_chunks', player, Global.SRV.players[ player ][ 'pos_old' ] )


