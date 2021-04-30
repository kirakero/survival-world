extends Node

var api: Api
var provider
var current_scene = null

signal scene_loaded

# api and provider basically always needs to be available
func _init():
	provider = SQLiteProvider.new()
	api = Api.new(provider)

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

func create_world(settings: Dictionary):
	print('create world', settings)
	goto_scene("res://scenes/LoadScene.tscn")
	
	yield(self, "scene_loaded")
	## create the map savefile
	api.async_world_post(settings['newgame'], settings['seed'], settings['world_size'], settings['chunk_size'])
	var _res = yield(api, "world_post_done")
	print (_res)
	
	if _res['status'] != 200:
		return goto_scene("res://scenes/HomeScene.tscn")
		
	### connect to new savefile
	api.game = settings['newgame']
	
	### map generation
	print('gen')
	var coordinator = Coordinator.new(6)
	var pipe = preload("res://gen/WorldPipe.gd").pipeline({'chunk_size': settings['chunk_size']}, current_scene)
	pipe.run(coordinator)
	var map = yield(pipe, "done")
	var cs = settings['chunk_size']
	
	var black = ImageData.new(Vector2(cs, cs), Image.FORMAT_RGBA8)
	
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
				dynImage.create(settings['chunk_size'], settings['chunk_size'], false, Image.FORMAT_RGBA8)
				dynImage.blit_rect(image, Rect2(x, y, settings['chunk_size'], settings['chunk_size']),  Vector2.ZERO)
				var _data = dynImage.get_data()
				if _data == black.pa:
					continue
				chunks.append({'position': Vector2(x + island_extents.position.x, y + island_extents.position.y), 'chunk': _data.compress()})
				
		api.async_multichunk_post(chunks)
		var api_res = yield(api, "multichunk_post_done")
		print (api_res)
		if api_res['status'] == 400:
			assert(false)
		
	
	## store the map
	pass
	
	




func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instance()

	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)
	
	emit_signal("scene_loaded")
