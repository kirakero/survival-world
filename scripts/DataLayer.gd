extends Reference
class_name DataLayer

# The operational mode of the DataLayer and thus the current user's system
var mode = 0

var chunks = {}
var obchunks = {}
var objects = {}
var players = {}
var chunks_client = {}

var dirty_objects = []
var dirty_chunks = []
var dirty_players = []

var pending_gameob: = []

var qt_dirty_obchunks: QuadTree
var tick: int = 0

var config setget set_config

var qt_loaded_chunks: QuadTree

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
	qt_dirty_obchunks = QuadTree.new(config['world_size'] * -0.5, config['world_size'] * -0.5, config['world_size'])
	qt_loaded_chunks = QuadTree.new(config['world_size'] * -0.5, config['world_size'] * -0.5, config['world_size'])
	
# receive new objects
func receive(raw: Array, from: int):
	# ingest the data
	for item in raw:
		ingest_new( item, from )

# receive physics or other continuous data
func receive_partial(raw: Array, from: int):
	# ingest the data
	for item in raw:
		ingest_partial( item, from )

func ingest_new(data: Dictionary, from):
	# the server is not allowed to received chunks, so we know that the
	# client side chunks are dirty
	var id = data[ Def.ID ]
	if data[ Def.TX_TYPE ] == Def.TYPE_CHUNK:
		chunks_client[ id ] = data
		dirty_chunks.append( id )
		return
	data[ Def.TX_ID ] = id
	# the system expects this to be a brand new object...
	add( data )
	# dirty objects
	dirty_objects.append([ id, from ])

func ingest_partial(data: Dictionary, from):
	# the server is not allowed to received chunks, so we know that the
	# client side chunks are dirty
	# todo - since this is an update operation, we'd have to sort out the chunk
	# that might already be loaded...
	var id = data[ Def.ID ]
	if data[ Def.TX_TYPE ] == Def.TYPE_CHUNK:
		chunks_client[ id ] = data
		dirty_chunks.append( id )
		return
	data[ Def.TX_ID ] = id
	# the system expects this to be an updated object...
	update( data )
	# dirty objects
	dirty_objects.append([ id, from ])

# object was created
# this would have come from an RPC reliable from the client, or created by
# an internal server process
func add(gameob: Dictionary):
	# validation
	assert(gameob.has( Def.TX_ID ))
	assert(not objects.has( gameob[ Def.TX_ID ] ))
	assert(gameob.has( Def.TX_TYPE ))
	assert(gameob.has( Def.TX_POSITION ))
	
	# determine the chunk key
	var pos_x: int = floor(gameob[ Def.TX_POSITION ].x / config['world_size']) * config['world_size']
	var pos_z: int = floor(gameob[ Def.TX_POSITION ].z / config['world_size']) * config['world_size']
	var key = Fun.make_chunk_key(pos_x, pos_z)
	if not chunks.has( key ):
		# try again later
		pending_gameob.append( gameob )
		return
	
	# finally, add it to the chunk and mark the obchunk as dirty
	obchunks[ key ].add( gameob )
	qt_dirty_obchunks.operation(tick, pos_x, pos_z, config['world_size'])

func add_player(gameob: Dictionary):
	# validation
	assert(gameob.has( Def.TX_ID ))
	assert(not objects.has( gameob[ Def.TX_ID ] ))
	assert(gameob.has( Def.TX_POSITION ))
	
	gameob[ Def.TX_UPDATED_AT ] = ServerTime.now()
	gameob[ Def.TYPE ] = Def.TYPE_PLAYER
	gameob[ Def.QUAD ] = null
	
	objects[ gameob[Def.TX_ID] ] = gameob
	players[ gameob[Def.TX_ID] ] = gameob
	dirty_players.append( gameob )
	

func update(gameob: Dictionary):
	# validation
	assert(gameob.has( Def.TX_ID ))
	assert(gameob.has( Def.TX_POSITION ))
	assert(gameob.has( Def.TX_UPDATED_AT ))
		
	# data is partial but it will have an ID
	# make sure we dont process old data, and make sure we can update something
	if not objects.has( gameob[ Def.TX_ID ] ) || objects[ gameob[Def.TX_ID] ][ Def.TX_UPDATED_AT ] > gameob[ Def.TX_UPDATED_AT ]:
		return false
	
	gameob.erase( Def.TX_ID )
	gameob.erase( Def.TX_TYPE )
	
	var pos_x: int = floor(gameob[ Def.TX_POSITION ].x / config['world_size']) * config['world_size']
	var pos_z: int = floor(gameob[ Def.TX_POSITION ].z / config['world_size']) * config['world_size']
	var chunk_key = Fun.make_chunk_key(pos_x, pos_z)
	
	# write the new values
	for k in gameob.keys():
		objects[ gameob[Def.TX_ID] ][ k ] = gameob[ k ]
	
	# the object has moved into another chunk
	if chunk_key != objects[ gameob[Def.TX_ID] ][ Def.QUAD ]:
		# this is a special case for putting players into the chunks
		if objects[ gameob[Def.TX_ID] ].has( Def.QUAD ):
			chunks[ objects[ gameob[Def.TX_ID] ][ Def.QUAD ] ].exit( gameob[Def.TX_ID] )
			chunks[ chunk_key ].enter( gameob[Def.TX_ID] )
		objects[ gameob[Def.TX_ID] ][ Def.QUAD ] = chunk_key
		chunks[ chunk_key ].update( objects[ gameob[Def.TX_ID] ], true )
	else:
		chunks[ chunk_key ].update( objects[ gameob[Def.TX_ID] ], false )
	
	qt_dirty_obchunks.operation(tick, pos_x, pos_z, config['world_size'])
	







func qt_load_chunks(chunk: QuadTree):
	if chunk.size == config['chunk_size']:
		var res = Global.api.world_provider._chunk_get( chunk.position )
		# register the basic object -- this is the object that can be transmitted
		# to connected peers
		objects[ chunk.key ] = res
		qt_loaded_chunks.operation(QuadTree.OP_ADD, chunk.x, chunk.y, chunk.size)
		# create the obchunk -- this is the object that handles server magics
		var uncompressed = res[Def.TX_CHUNK_DATA]
		if uncompressed.size() > 0:
			uncompressed = res[Def.TX_CHUNK_DATA].decompress(pow(chunk.size + 2, 2) * 4)
		add_chunk( Chunk.new( chunk.position, uncompressed, res[Def.TX_OBJECT_DATA], chunk.size ) )
		return
	
	chunk.add_children()
	for child in chunk.child:
		qt_load_chunks( child )

func qt_get_chunks(tree: QuadTree) -> Array:
	var missing_chunks = QuadTree.intersect(qt_loaded_chunks, tree, QuadTree.INTERSECT_KEEP_B).all()

	for chunk in missing_chunks:
		qt_load_chunks(chunk)

	var union = QuadTree.union(qt_loaded_chunks, tree).all()

	var chunks = []
	for chunk in union:
		chunks.append( chunk.key )
	
	return chunks

# when the server loads a chunk
func add_chunk(chunk: Chunk):
	chunks[ chunk.get_key() ] = chunk
	obchunks[ chunk.get_key() ] = ObChunk.new( chunk )
	obchunks[ chunk.get_key() ].load_all()
	
	





func serialized(id):
	var gameob = Global.DATA.objects[ id ].duplicate()
	gameob.erase( Def.QUAD )
	gameob.erase( Def.QUAD_INDEX )
	return gameob
		
func serialized_partial(id):
	# todo return only the physics fields
	var gameob = Global.DATA.objects[ id ].duplicate()
	gameob.erase( Def.QUAD )
	gameob.erase( Def.QUAD_INDEX )
	gameob.erase( Def.TX_TYPE )
	gameob.erase( Def.TX_SUBTYPE )
	return gameob	
	
	
	
func empty_dirty_players():
	dirty_players = []
	
	
	
	
	
	
	
	
func set_world(_game):
	if game != null and world_provider != null:
		world_provider.conn_delete({})
	world_provider = SQLiteProvider.new()
	game = _game
	world_provider.conn_post({'game': _game})
	config = world_provider._world_get()	

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

