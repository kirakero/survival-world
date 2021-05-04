extends Reference

var scene: Node
var api: Api
var player: Node
var client: Node
var last_pos: Vector3

var disabled = false

func _init(_client: Node, _api: Api, _scene: Node, _player: Node):
	scene = _scene
	player = _player
	api = _api
	client = _client
	
func run(delta):
	# Do not run if we have nothing to do
	# Use disabled so that the service can be tracked easily later
	if disabled:
		return
	call_deferred('_run', delta)
	

func _run(delta):
	if player.translation.distance_to(last_pos) < 0.01:
		return
	last_pos = player.translation
	api.tx_physics({
		Api.TX_TYPE: Api.TYPE_PLAYER,
		Api.TX_ID: api.my_id,
		Api.TX_DATA: {
			Api.TX_PHYS_POSITION: player.translation
		}
	})
	
	















