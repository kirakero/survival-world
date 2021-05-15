extends Spatial
class_name GameOb

var id
var chunk

func init( _id, _chunk ):
	id = _id
	chunk = _chunk
	Global.CLI.objects[ id ][ Def.REF ] = self
	_sync()


# called when the GameOb receives an update
func on_rx_change():
	_sync()
	pass

func _sync():
	# if we locally control this object, skip
	if Global.CLI.objects[ id ].has( Def.TX_FOCUS ) and Global.CLI.objects[ id ][ Def.TX_FOCUS ] == Global.NET.my_id:
		return
		
	translation = Global.CLI.objects[ id ][ Def.TX_POSITION ] - chunk.translation
	rotation = Global.CLI.objects[ id ][ Def.TX_ROTATION ]
