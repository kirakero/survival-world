extends Node

var api

func _init(_api):
	api = _api
	
	

var counter = 0.0
func _physics_process(delta):
	counter = counter + delta
	if counter < 5.0:
		return
	counter = 0.0
	print('server tick')
	print(api.objects)
	for fw in api.frameware:
		fw.run()
