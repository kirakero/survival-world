extends Reference

var scene: Node
var api: Api
var player: Node
var client: Node
var last_pos: Vector3

var disabled = false
	
func run(delta):
	# Do not run if we have nothing to do
	# Use disabled so that the service can be tracked easily later
	if disabled:
		return
	call_deferred('_run', delta)
	

func _run(delta):
	if Global.CLI.player.translation.distance_to(last_pos) < 0.01:
		return
	last_pos = Global.CLI.player.translation
	
	Global.CLI.objects[ Global.NET.my_id ][ Def.TX_POSITION ] = last_pos
	Global.NET.txp( [ Global.CLI.objects[ Global.NET.my_id ] ] )
	
	















