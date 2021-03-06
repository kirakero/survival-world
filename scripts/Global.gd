extends Node

var provider
var current_scene = null
var config: Dictionary

var DATA= null
var NET = null
var CLI = null
var SRV = null

signal scene_loaded
signal scene_prepared

var printnexttxr = false

# api and provider basically always needs to be available
func _init():	
	DATA = DataLayer.new()	
	NET = Network.new()
	add_child(NET)

func start_local( game, server, password ):
	goto_scene("res://scenes/LoadScene.tscn")
	yield(self, "scene_loaded")
	
	SRV = Server.new( game, server, password )
	call_deferred("add_child", SRV )
	yield(SRV, "server_loaded")
	
	CLI = Client.new( 'kero' )
	add_child( CLI )
	yield(CLI, "client_loaded")

func start_server( game, server, password ):
	goto_scene("res://scenes/LoadScene.tscn")
	yield(self, "scene_loaded")
	
	SRV = Server.new( game, server, password )
	call_deferred("add_child", SRV )
	yield(SRV, "server_loaded")

func start_remote( server, password ):
	goto_scene("res://scenes/LoadScene.tscn")
	yield(self, "scene_loaded")
	
	CLI = Client.new( 'kero', server, password )
	call_deferred("add_child", CLI )
	yield(CLI, "client_loaded")


func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

func create_world(settings: Dictionary):
	print('create world', settings)
	goto_scene("res://scenes/LoadScene.tscn")
	
	yield(self, "scene_loaded")
	## create the map savefile
	DATA.async_world_post(settings['newgame'], settings['seed'], settings['world_size'], settings['chunk_size'])
	var _res = yield(DATA, "world_post_done")
	print (_res)
	
	if _res['status'] != 200:
		return goto_scene("res://scenes/HomeScene.tscn")
		
	### connect to new savefile
	DATA.game = settings['newgame']
	
	### map generation
	print('gen')
	var coordinator = Coordinator.new(6)
	var pipe = preload("res://gen/WorldPipe.gd").pipeline({'chunk_size': settings['chunk_size'], 'seed': settings['seed']})
	add_child(pipe)
	
	pipe.run(coordinator)
	var map = yield(pipe, "done")
	var cs = settings['chunk_size']
	
	var black = ImageData.new(Vector2(cs+2, cs+2), Image.FORMAT_RGBA8)
	
	print(' result len ', map['islands'].size())
	for k in map['islands'].size():
		var image_data: ImageData = map['islands'][k]['image']
		var image: Image = image_data.get_image()
		var island_extents = map['islands'][k]['extents']
		
		
		
		island_extents.position.x = floor(island_extents.position.x / cs) * cs
		island_extents.position.y = floor(island_extents.position.y / cs) * cs
		print(island_extents)
		var chunks = []
		var bitdepth = 4
		for x in range(0, island_extents.size.x, settings['chunk_size']):
			for y in range(0, island_extents.size.y, settings['chunk_size']):
				var dynImage = Image.new()
				dynImage.create(settings['chunk_size'] + 2, settings['chunk_size'] + 2, false, Image.FORMAT_RGBA8)
				dynImage.blit_rect(image, Rect2(x - 1, y - 1, settings['chunk_size'] + 2, settings['chunk_size'] + 2),  Vector2.ZERO)
				var _data = dynImage.get_data()
				if _data == black.pa:
					continue
				var _position = Vector2(x + island_extents.position.x, y + island_extents.position.y)
#				if _position.x == 64 and _position.y == 960:
#					image.save_png('res://_test/i_%s-x%s-y%s.png' % [k, _position.x, _position.y])
#					dynImage.save_png('res://_test/i_%s_%s-%s.png' % [k, x, y])
				chunks.append({'position': _position, 'chunk': _data.compress()})
				
		DATA.async_multichunk_post(chunks)
		var api_res = yield(DATA, "multichunk_post_done")
		print (api_res)
		if api_res['status'] == 400:
			assert(false)
	pipe.queue_free()
#	load_world(settings['newgame'])
	## store the map
	pass
	
func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)

func goto_scene_prepare(path):
	call_deferred("_deferred_goto_scene_prepare", path)

func goto_scene_commit(scene):
	call_deferred("_deferred_goto_scene_commit", scene)

func _deferred_goto_scene_prepare(path):
	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	var new_scene = s.instance()
	
	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(new_scene)
	emit_signal("scene_prepared", new_scene)
	
func _deferred_goto_scene_commit(scene):
	# It is now safe to remove the current scene
	current_scene.free()
	
	current_scene = scene

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)
	
	emit_signal("scene_loaded")
	
func _deferred_goto_scene(path):


	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	var new_scene = s.instance()
	
	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(new_scene)
	
	# It is now safe to remove the current scene
	current_scene.free()
	
	current_scene = new_scene

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)
	
	emit_signal("scene_loaded")
