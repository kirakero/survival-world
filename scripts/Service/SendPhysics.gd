extends Reference

var scene: Node
var api: Api
var player: Node
var client: Node
var last_pos: Vector3

var disabled = false

var counter = 0.0
var bufferout = 0

func run(delta):
	counter = counter + delta
	if counter < 0.005:
		return
	counter = 0.0
	if Global.CLI.player.translation.distance_to(last_pos) < 0.005:
		if bufferout > 20:
			return
		bufferout = bufferout + 1
	else:
		bufferout = 0
	last_pos = Global.CLI.player.translation

	for k in Global.CLI.player.tx.keys():
		Global.CLI.objects[ Global.NET.my_id ][ k ] = Global.CLI.player.tx[ k ]
	
	# ippatsu controls
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_PLAYER_ROLL ] = Global.CLI.player.will_roll
	Global.CLI.player.will_roll = false

	
	#player latency transmission
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_LATENCY ] = Global.CLI.time.latency

	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_UPDATED_AT ] = Global.CLI.time.now()
	Global.NET.txp( [ Global.CLI.objects[ Global.NET.my_id ] ], 1, Global.NET.INTENT_SERVER )
	
	















