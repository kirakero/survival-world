extends Node
class_name Api

# this is the ID of the map
var game
# this is the provider for the world data
var provider: Reference
# character information will be saved in a separate DB instance on the client side

signal world_post_done(result)
signal chunk_post_done(result)
signal chunk_get_done(result)

func _init(_game, _provider):
	game = _game
	provider = _provider

# standardize the request object
func invoke(endpoint: String, data: Dictionary):
	data['game'] = game
	data['_sender'] = self
	data['_callback'] = str(endpoint, '_done')
	data['_key'] = 1
	provider.call_deferred(endpoint, data)

func done(signal_name, result, code):
	emit_signal(signal_name, { 'data': result, 'status': code })
	
# when creating a brand new world to save locally
func async_world_post(_newgame, _seed, _world_size, _chunk_size):
	invoke('world_post', {
		'newgame': _newgame,
		'seed': _seed,
		'world_size': _world_size,
		'chunk_size': _chunk_size,
	})

# returns all settings for the world
func async_world_get():
	invoke('world_get', {})

# write chunk
func async_chunk_post(_position, _data):
	invoke('chunk_post', {
		'position': _position,
		'data': _data,
	})

# bulk write chunk
func async_multichunk_post(_data: Array):
	# use format for regular call, as array
	invoke('multichunk_post', {
		'data': _data,
	})
	
# read chunk
func async_chunk_get(_position):
	invoke('chunk_get', {
		'position': _position,
	})

# bulk read chunk
func async_multichunk_get(_data: Array):
	# use format for regular call, as array
	invoke('multichunk_get', {
		'data': _data,
	})





