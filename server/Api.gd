extends Node
class_name Api



# this is the world_provider for the world data
var world_provider: Reference
var state_provider: Node



var dirty_objects_mutex: Mutex
var local_server = true




signal net_failure

signal server_loaded
signal client_loaded




func _init(_world_provider):
	
	
	dirty_objects_mutex = Mutex.new()






