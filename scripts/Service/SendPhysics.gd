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
	if counter < 0.025:
		return
	counter = 0.0
	if Global.CLI.player.translation.distance_to(last_pos) < 0.005:
		if bufferout > 3:
			return
		bufferout = bufferout + 1
	else:
		bufferout = 0
	last_pos = Global.CLI.player.translation

	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_POSITION ] = last_pos
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_ROTATION ] = Global.CLI.player.rotation
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_UPDATED_AT ] = Global.CLI.time.now()
	Global.NET.txp( [ Global.CLI.objects[ Global.NET.my_id ] ], 1, Global.NET.INTENT_SERVER )
	
	















