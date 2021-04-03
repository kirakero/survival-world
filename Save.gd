extends Node
class_name Save

var world
var datafolder = "res://savegame/"

func _init(world):
	self.world = world
		
		
func path(filename):
	return str(datafolder, world, "/", filename)
	
	
func exists():
	var dir = Directory.new()
	var path = str(datafolder, world)
	if dir.open(path) == OK:
		return true
	return false

func create(randomseed):
	var dir = Directory.new()
	dir.make_dir(str(datafolder, world))
	var file = File.new()
	var data = {"world":world, "seed":randomseed}
	file.open(path("world.json"), File.WRITE)
	file.store_string(JSON.print(data))
	file.close()

func save_resource():
	# the resource is expected to have a store() method
	
	pass
