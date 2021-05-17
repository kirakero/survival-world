extends Spatial
class_name GameOb

var id
var chunk

var state_buffer: = []
var interpolation_offset = 1000
var anim: AnimationTree
var last_speed = 0


func init( _id, _chunk ):
	id = _id
	chunk = _chunk
	Global.CLI.objects[ id ][ Def.REF ] = self
	translation = Global.CLI.objects[ id ][ Def.TX_POSITION ] - chunk.translation

# called when the GameOb receives an update
func on_rx_change():
	_sync()

func _sync():
	# the incoming state information is the newest info
	if Global.CLI.objects[ id ][ Def.TX_UPDATED_AT ] != 0:
		if Global.CLI.objects[ id ][ Def.TX_TYPE ] == Def.TYPE_PLAYER:
			state_buffer.append( { 
				Def.TX_POSITION: Global.CLI.objects[ id ][ Def.TX_POSITION ] ,
				Def.TX_ROTATION: Global.CLI.objects[ id ][ Def.TX_ROTATION ] ,
				Def.TX_PLAYER_AIM: Global.CLI.objects[ id ][ Def.TX_PLAYER_AIM ] ,
				Def.TX_PLAYER_ROLL: Global.CLI.objects[ id ][ Def.TX_PLAYER_ROLL ] ,
				Def.TX_PLAYER_STRAFE: Global.CLI.objects[ id ][ Def.TX_PLAYER_STRAFE ] ,
				Def.TX_PLAYER_IWR: Global.CLI.objects[ id ][ Def.TX_PLAYER_IWR ] ,
				Def.TX_UPDATED_AT: Global.CLI.objects[ id ][ Def.TX_UPDATED_AT ],
				'chunk': chunk.translation,
			})	
		else:
			state_buffer.append( { 
				Def.TX_POSITION: Global.CLI.objects[ id ][ Def.TX_POSITION ] ,
				Def.TX_ROTATION: Global.CLI.objects[ id ][ Def.TX_ROTATION ] ,
				Def.TX_UPDATED_AT: Global.CLI.objects[ id ][ Def.TX_UPDATED_AT ],
				'chunk': chunk.translation,
			})	
	

func _physics_process(delta):	
	var render_time = Global.CLI.time.system() - interpolation_offset
	while state_buffer.size() > 2 and render_time > state_buffer[2][ Def.TX_UPDATED_AT ]:
		state_buffer.remove(0)
	
	if state_buffer.size() < 2:
		if anim:
			anim.set("parameters/iwr_blend/blend_amount", -1 )
		return 
#
	if state_buffer.size() > 2 and state_buffer[1][ Def.TX_UPDATED_AT ] >= render_time - int(delta * 1000): # interpolation
		var interpolation_factor = 0.0 
		var diff = float( state_buffer[2][ Def.TX_UPDATED_AT ] - state_buffer[1][ Def.TX_UPDATED_AT ] )
		if diff > 0:
			interpolation_factor = float( render_time - state_buffer[1][ Def.TX_UPDATED_AT ] ) / diff
		
		
		translation = lerp(state_buffer[1][ Def.TX_POSITION ], state_buffer[2][ Def.TX_POSITION ], clamp(interpolation_factor,0,1)) - state_buffer[1]['chunk']
		print ('int ', translation)

		if anim and state_buffer[1].has( Def.TX_PLAYER_AIM ) and state_buffer[2].has( Def.TX_PLAYER_AIM ):
			var velocity =  lerp(state_buffer[1][ Def.TX_PLAYER_IWR ], state_buffer[2][ Def.TX_PLAYER_IWR ], clamp(interpolation_factor,0,1))
			

#			anim.set("parameters/aim_transition/current", 1)
			anim.set("parameters/iwr_blend/blend_amount", velocity_to_iwr(velocity) )
			
			
			$Mesh.rotation = lerp(state_buffer[1][ Def.TX_ROTATION ], state_buffer[2][ Def.TX_ROTATION ], clamp(interpolation_factor,0,1))
		else:
			rotation = lerp(state_buffer[1][ Def.TX_ROTATION ], state_buffer[2][ Def.TX_ROTATION ], clamp(interpolation_factor,0,1))
			
	elif render_time > state_buffer[1][ Def.TX_UPDATED_AT ]: # extrapolation
		var extrapolation_factor = 0.0 
		var diff =  float( state_buffer[1][ Def.TX_UPDATED_AT ] - state_buffer[0][ Def.TX_UPDATED_AT ] )
		if diff > 0:
			extrapolation_factor = float( render_time - state_buffer[0][ Def.TX_UPDATED_AT ] ) / diff - 1.0

		var position_delta: Vector3 = state_buffer[1][ Def.TX_POSITION ] - state_buffer[0][ Def.TX_POSITION ]
		if position_delta.length() > 0.01:
			translation = state_buffer[1][ Def.TX_POSITION ] + (position_delta * extrapolation_factor) - state_buffer[1]['chunk']
			print ('ext ', translation)
		
		var rotation_delta: Vector3 = state_buffer[1][ Def.TX_ROTATION ] - state_buffer[0][ Def.TX_ROTATION ]
		if rotation_delta.length() > 0.01:
			var rot = state_buffer[1][ Def.TX_ROTATION ] + (rotation_delta * extrapolation_factor)
			if anim:
				$Mesh.rotation = rot
			else:
				rotation = rot
				
		var velocity_delta = state_buffer[1][ Def.TX_PLAYER_IWR ] - state_buffer[0][ Def.TX_PLAYER_IWR ]
		if velocity_delta > 0.01:
			var velocity = state_buffer[1][ Def.TX_PLAYER_IWR ] + (velocity_delta * extrapolation_factor)
			if anim:
				anim.set("parameters/iwr_blend/blend_amount", velocity_to_iwr(velocity) )

		
#		if anim and state_buffer[1].has( Def.TX_PLAYER_AIM ):
#			anim.set("parameters/aim_transition/current", state_buffer[1][ Def.TX_PLAYER_AIM ])
#			if state_buffer[1][ Def.TX_PLAYER_ROLL ]:
#				anim.set("parameters/roll/active", state_buffer[1][ Def.TX_PLAYER_ROLL ])
#			anim.set("parameters/strafe/blend_position", state_buffer[1][ Def.TX_PLAYER_STRAFE ] )
#			anim.set("parameters/iwr_blend/blend_amount", state_buffer[1][ Def.TX_PLAYER_IWR ] )


func _on_AnimationPlayer_ready():
	print ('----- ready ----')
	anim = $AnimationTree
	anim.tree_root.set_filter_enabled(true)
	

func velocity_to_iwr(velocity):
	var walk_speed = 1.5
	var run_speed = 5
	var iw_blend = (velocity - walk_speed) / walk_speed
	var wr_blend = (velocity - walk_speed) / (run_speed - walk_speed)

	#find the graph here: https://www.desmos.com/calculator/4z9devx1ky

	var iwr = -1
	if velocity <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , iw_blend)
		iwr = iw_blend
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , wr_blend)
		iwr = wr_blend

	return iwr
