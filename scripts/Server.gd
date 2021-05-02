extends Node

var api
var services = []

func _init(_api):
	api = _api
	services.append( load("res://scripts/Service/SyncPlayers.gd").new( api ) )
	services.append( load("res://scripts/Service/SyncChunks.gd").new( api ) )
	
	
var counter = 0.0
func _physics_process(delta):
	counter = counter + delta
	if counter < 5.0:
		return
	counter = 0.0
	print('server tick')
	print(api.objects)
	for service in services:
		service.run()
