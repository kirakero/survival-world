extends Node2D


export var send = 0 setget sendit
var sending = false

func sendit(v):
	if sending: return
	send = v
	
	var gamename = 'kero'
	var sqlite = SQLiteProvider.new(gamename)
	var api = Api.new(gamename, sqlite)

	api.async_world_post(gamename, 12, 8192, 32)
	var res = yield(api, "world_post_done")
	
	print(res)
