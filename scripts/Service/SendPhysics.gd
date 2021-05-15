extends Reference

var scene: Node
var api: Api
var player: Node
var client: Node
var last_pos: Vector3

var disabled = false

var counter = 0.0

func run(delta):
	counter = counter + delta
	if counter < 0.1:
		return
	counter = 0.0
	if Global.CLI.player.translation.distance_to(last_pos) < 0.01:
		return
	last_pos = Global.CLI.player.translation
	
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_POSITION ] = last_pos
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_ROTATION ] = Global.CLI.player.rotation
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_UPDATED_AT ] = ServerTime.now()
	Global.NET.txp( [ Global.CLI.objects[ Global.NET.my_id ] ], 1, Global.NET.INTENT_SERVER )
	
	















