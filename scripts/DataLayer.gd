extends Reference
class_name DataLayer

# The operational mode of the DataLayer and thus the current user's system
var mode = 0



#var qt_dirty_obchunks: QuadTree
var tick: int = 0

var config setget set_config


var game
var world_provider

signal world_get_done(result)
signal world_post_done(result)
signal chunk_post_done(result)
signal multichunk_post_done(result)
signal multichunk_get_done(result)
signal chunk_get_done(result)
signal config_received

func add_mode(_mode):
	mode = mode | _mode

func set_config(value):
	config = value
	config['world_size'] = float(config['world_size'])
	config['chunk_size'] = float(config['chunk_size'])
	_debug('config loaded')

func qt_empty():
	return QuadTree.new(-config['world_size']*0.5, -config['world_size']*0.5, config['world_size'])

func chunkkeys_circle(pos: Vector3):
	var out = {}
	for x in range(pos.x - config['max_range_chunk'], pos.x + config['max_range_chunk'], config['chunk_size']):
		for z in range(pos.z - config['max_range_chunk'], pos.z + config['max_range_chunk'], config['chunk_size']):
			var chunk = Vector3(x, 0, z)
			if chunk.distance_to( pos ) <= config['max_range_chunk'] + config['chunk_size'] * 0.5:
				out[ Fun.make_chunk_key(x, z) ] = chunk
	return out

func get_chunk_pos( translation: Vector3 ):
	return Vector3(
		floor(translation.x / config['chunk_size']) * config['chunk_size'],
		0,
		floor(translation.z / config['chunk_size']) * config['chunk_size']
	)

#	return pos

func qt_circle(pos_x, pos_z) -> QuadTree:
	var qt = qt_empty()
	var max_range_chunk = config['max_range_chunk']
	var chunk_size = config['chunk_size']
	
	qt.operation(QuadTree.OP_ADD, pos_x - max_range_chunk - chunk_size, pos_z - max_range_chunk, (max_range_chunk)*2)
	qt.operation(QuadTree.OP_SUBTRACT, pos_x - max_range_chunk - chunk_size, pos_z - max_range_chunk, chunk_size)
	qt.operation(QuadTree.OP_SUBTRACT, pos_x + (max_range_chunk)*2 - chunk_size, pos_z - max_range_chunk, chunk_size)
	qt.operation(QuadTree.OP_SUBTRACT, pos_x - max_range_chunk - chunk_size, pos_z + (max_range_chunk)*2 - chunk_size, chunk_size)
	qt.operation(QuadTree.OP_SUBTRACT, pos_x + (max_range_chunk)*2 - chunk_size, pos_z + (max_range_chunk)*2 - chunk_size, chunk_size)
	return qt

#func add_player(gameob: Dictionary):
#	# validation
#	assert(gameob.has( Def.TX_ID ))
#	assert(not objects.has( gameob[ Def.TX_ID ] ))
#	assert(gameob.has( Def.TX_POSITION ))
#
#	gameob[ Def.TX_UPDATED_AT ] = ServerTime.now()
#	gameob[ Def.TX_TYPE ] = Def.TYPE_PLAYER
#	gameob[ Def.QUAD ] = null
#
#	objects[ gameob[Def.TX_ID] ] = gameob
#	players[ gameob[Def.TX_ID] ] = gameob
#	# todo remove this function...
#	# also this setup shouldnt be here...
#	last_transmitted[ gameob[ Def.TX_ID ] ] = qt_empty()
#	dirty_players.append( gameob )
	
	
	
func set_world(_game):
	if game != null and world_provider != null:
		world_provider.conn_delete({})
	world_provider = SQLiteProvider.new()
	game = _game
	world_provider.conn_post({'game': _game})
	set_config( world_provider._world_get() )	

# standardize the request object
func invoke(endpoint: String, data: Dictionary):
	print ('invoke ', endpoint)
	data['game'] = game
	data['_sender'] = self
	data['_callback'] = str(endpoint, '_done')
	data['_key'] = 1
	world_provider.call_deferred(endpoint, data)

func done(signal_name, result, code):
	print('api done ',signal_name, result)
	
	emit_signal(signal_name, { 'data': result, 'status': code })

const DB_DATA_DIR = 'user://savegame/'

# lists the worlds saved locally
func sync_my_world_index() -> Array:
	var dir = Directory.new()
	if not dir.dir_exists(DB_DATA_DIR):
		dir.make_dir(DB_DATA_DIR)
	dir.open(DB_DATA_DIR)
	dir.list_dir_begin()
	var files = []
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file.get_basename())

	dir.list_dir_end()
	return files

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


func _debug(message):
	print ("DATA: %s" % message)
