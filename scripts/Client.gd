extends Node

var api
var scene
var player
var services = []

signal chunk_queue_empty

func _init(_api, _scene, _player):
	api = _api
	scene = _scene
	player = _player
	services.append( load("res://scripts/Service/SendPhysics.gd").new( self, api, scene, player ) )
	services.append( load("res://scripts/Service/DrawChunks.gd").new( self, api, scene, player ) )
	

func _physics_process(delta):
	for service in services:
		service.run(delta)
