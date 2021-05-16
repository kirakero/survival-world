extends Spatial
class_name GameOb

var id
var chunk

var state_buffer: = []
var interpolation_offset = 1000

func init( _id, _chunk ):
	id = _id
	chunk = _chunk
	Global.CLI.objects[ id ][ Def.REF ] = self
	print ('init ', _id)
	translation = Global.CLI.objects[ id ][ Def.TX_POSITION ] - chunk.translation

# called when the GameOb receives an update
func on_rx_change():
	_sync()

func _sync():
	# the incoming state information is the newest info
	if Global.CLI.objects[ id ][ Def.TX_UPDATED_AT ] != 0:
		state_buffer.append( { 
			Def.TX_POSITION: Global.CLI.objects[ id ][ Def.TX_POSITION ] ,
			Def.TX_UPDATED_AT: Global.CLI.objects[ id ][ Def.TX_UPDATED_AT ],
			'chunk': chunk.translation,
		})	

func _physics_process(delta):	
	var render_time = Global.CLI.time.system() - interpolation_offset
	while state_buffer.size() > 2 and render_time > state_buffer[2][ Def.TX_UPDATED_AT ]:
		state_buffer.remove(0)
	
	if state_buffer.size() < 1:
		return 
#
	if state_buffer.size() > 2 and state_buffer[1][ Def.TX_UPDATED_AT ] >= render_time - int(delta * 1000): # interpolation
		var interpolation_factor = 0.0 
		var diff = float( state_buffer[2][ Def.TX_UPDATED_AT ] - state_buffer[1][ Def.TX_UPDATED_AT ] )
		if diff > 0:
			interpolation_factor = float( render_time - state_buffer[1][ Def.TX_UPDATED_AT ] ) / diff
		
		translation = lerp(state_buffer[1][ Def.TX_POSITION ], state_buffer[2][ Def.TX_POSITION ], clamp(interpolation_factor,0,1)) - state_buffer[1]['chunk']
		print ('int ', interpolation_factor)
		
		
	elif render_time > state_buffer[1][ Def.TX_UPDATED_AT ]: # extrapolation
		var extrapolation_factor = 0.0 
		var diff =  float( state_buffer[1][ Def.TX_UPDATED_AT ] - state_buffer[0][ Def.TX_UPDATED_AT ] )
		if diff > 0:
			extrapolation_factor = float( render_time - state_buffer[0][ Def.TX_UPDATED_AT ] ) / diff - 1.0

		var position_delta: Vector3 = state_buffer[1][ Def.TX_POSITION ] - state_buffer[0][ Def.TX_POSITION ]
		if position_delta.length() < 0.01:
			return
			
		translation = state_buffer[1][ Def.TX_POSITION ] + (position_delta * extrapolation_factor) - state_buffer[1]['chunk']
#		print (render_time, state_buffer)
		print ('ext ', translation)

		
